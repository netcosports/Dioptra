//
//  AVVideoPlaybackViewModel.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 5/11/18.
//  Copyright © 2018 Sergei Mikhan. All rights reserved.
//

import AVKit
import RxSwift
import RxCocoa
import RxReachability
import Reachability

open class AVVideoPlaybackViewModel: AVVideoPlaybackManagableViewModel {

  public var itemCreationClosure: ((String) -> (AVPlayerItem?))?

  override init() {
    super.init()
    player = AVPlayer()
  }

  override open func startPlayback(with stream: String) {
    super.startPlayback(with: stream)
    let item: AVPlayerItem
    if let customItem = itemCreationClosure?(stream) {
      item = customItem
    } else if stream.hasPrefix("http") {
      guard let url = URL(string: stream) else { return }
      item = AVPlayerItem(url: url)
    } else {
      let url = URL(fileURLWithPath: stream)
      item = AVPlayerItem(url: url)
    }
    if let player = player {
      bind(to: player)
    }
    bind(to: item)
    player?.replaceCurrentItem(with: item)
  }
}

open class AVVideoPlaybackManagableViewModel: NSObject, VideoPlayback {

  public struct Settings {
    public init(retrieveQualities: Bool = false, periodicTimeUpdateInterval: CMTime = CMTime(value: 1, timescale: 10)) {
      self.retrieveQualities = retrieveQualities
      self.periodicTimeUpdateInterval = periodicTimeUpdateInterval
    }

    public let retrieveQualities: Bool
    public let periodicTimeUpdateInterval: CMTime
  }

  fileprivate var disposeBag: DisposeBag?
	fileprivate let reachability: Reachability?
  fileprivate let itemRelay             = PublishRelay<AVPlayerItem?>()
  fileprivate let currentTimeRelay      = PublishRelay<TimeInSeconds>()
  fileprivate let speedRelay            = PublishRelay<Double>()
  fileprivate let availableQualitiesRelay = BehaviorSubject<[VideoQuality]>(value: [.auto])
	fileprivate let reachabilityDisposeBag = DisposeBag()

  var expectedStartTime: Double?

  public let stateRelay = PublishRelay<PlayerState>()
  public let seekCompleatedRelay = PublishRelay<Void>()
  public var player: AVPlayer?

  public typealias Stream = String
  public var input: Input<Stream> = .cleanup {
    willSet(newInput) {
      switch newInput {
      case .content(let stream):
        startPlayback(with: stream)
        stateRelay.accept(.loading)
        expectedStartTime = nil
      case .contentWithStartTime(let stream, let startTime):
        startPlayback(with: stream)
        stateRelay.accept(.loading)
        expectedStartTime = startTime
      case .ad(let stream):
        startPlayback(with: stream)
        stateRelay.accept(.loading)
      default: stop()
      }
    }
  }
  public var settings = Settings()
  public var muted: Bool = false {
    didSet {
      player?.isMuted = muted
      player?.currentItem?.audioMix = nil
    }
  }

  public var volume: Float {
    set {
      player?.volume = newValue
    }

    get {
      return player?.volume ?? 0.0
    }
  }

  public var quality = VideoQuality.auto {
    didSet {
      if #available(iOS 10.0, *) {
        switch quality {
        case .auto:
          player?.currentItem?.preferredForwardBufferDuration = 0.0
        case .stream:
          player?.currentItem?.preferredForwardBufferDuration = 1.0
        }
      }
      player?.currentItem?.preferredPeakBitRate = quality.preferredPeakBitRate
    }
  }
  public var speed = 1.0 {
    didSet {
      if player?.rate != 0.0 {
        player?.rate = Float(speed)
      }
    }
  }
  public let seek = PublishSubject<TimeInSeconds>()
  public var state = PublishSubject<PlaybackState>()
  public var availableQualities: Driver<[VideoQuality]> {
    return availableQualitiesRelay.asDriver(onErrorJustReturn: [])
  }

  public var speedUpdated: Driver<Double> {
    return speedRelay.asDriver(onErrorJustReturn: 0.0)
  }

  public var time: Driver<TimeInSeconds> {
    return currentTimeRelay.asDriver(onErrorJustReturn: 0.0)
  }

  public var duration: Driver<TimeInSeconds> {
    return itemRelay.asDriver(onErrorJustReturn: nil).filter { $0 != nil }.flatMapLatest { item -> Driver<TimeInSeconds> in
      if let item = item {
        return item.rx.seekableRange.map {
          guard let lastRange = $0.last else { return 0.0 }
          let seconds = CMTimeGetSeconds(lastRange.end)
          guard seconds.isFinite else { return 0.0 }
          return seconds
          }.asDriver(onErrorJustReturn: 0.0).distinctUntilChanged().filter { $0 > 0.0 }
      } else {
        return .empty()
      }
    }
  }

  public var loadedRange: Driver<LoadedTimeRange> {
    return itemRelay.asDriver(onErrorJustReturn: nil).filter { $0 != nil }.flatMapLatest { item -> Driver<LoadedTimeRange> in
      if let item = item {
        return item.rx.loadedTimeRanges.asDriver(onErrorJustReturn: []).map { ranges -> LoadedTimeRange in
          return ranges.map {
            let bounds = (lower: CMTimeGetSeconds($0.start), upper: CMTimeGetSeconds($0.end))
            guard bounds.lower.isFinite && bounds.upper.isFinite else {
              return TimeInSecondsRange(uncheckedBounds: (0, 0))
            }
            return TimeInSecondsRange(uncheckedBounds: bounds)
          }
        }
      } else {
        return .empty()
      }
    }
  }

  public var playerState: Driver<PlayerState> {
    return stateRelay.asDriver(onErrorJustReturn: .idle)
  }

  public var seekCompleated: Driver<Void> {
    return seekCompleatedRelay.asDriver(onErrorJustReturn: ())
  }

	public override init() {
		reachability = try? Reachability()
    super.init()
		try? reachability?.startNotifier()
		reachability?.rx.isReachable.debug("===").compactMap { $0 ? nil : PlayerState.error(error: .connection(error: nil)) }.bind(to: stateRelay).disposed(by: reachabilityDisposeBag)
  }

	deinit {
		reachability?.stopNotifier()
	}

  public func bind(to player: AVPlayer) {
    self.player = player
    player.isMuted = self.muted
    player.actionAtItemEnd = .none



    let disposeBag = DisposeBag()
    player.rx.periodicTimeObserver(interval: settings.periodicTimeUpdateInterval)
      .map {
        return CMTimeGetSeconds($0)
      }
      .filter { $0.isFinite }
      .filter { [weak self] _ in self?.expectedStartTime == nil }
      .bind(to: currentTimeRelay)
      .disposed(by: disposeBag)

    seek.asDriver(onErrorJustReturn: 0.0).drive(onNext: { [weak self] seconds in
      self?.seek(to: seconds)
      // TODO: we need to clarify is it necessary since we have periodic updates
      self?.currentTimeRelay.accept(seconds)
    }).disposed(by: disposeBag)

    state
      .observeOn(MainScheduler.asyncInstance)
      .asDriver(onErrorJustReturn: .paused).drive(onNext: { [weak self] state in
        switch state {
        case .playing:
          self?.play()
        case .paused:
          self?.pause()
        }
      }).disposed(by: disposeBag)

    player.rx.rate.withLatestFrom(itemRelay.asObservable(), resultSelector: { rate, item in
      return (rate, item)
    })
      .filter { [weak self] rate, item in
        guard let item = item else { return false }
        return item.duration.seconds != item.currentTime().seconds
      }
      .map { $0.0 }
      .distinctUntilChanged()
      .map { $0 == 0.0 ? PlayerState.active(state: .paused) : PlayerState.active(state: .playing) }
      .bind(to: stateRelay)
      .disposed(by: disposeBag)

    player.rx.rate.map { Double($0) }.bind(to: speedRelay).disposed(by: disposeBag)

    itemRelay.asDriver(onErrorJustReturn: nil).filter { $0 != nil }.flatMapLatest { item -> Driver<Bool> in
      if let item = item {
        return item.rx.playbackLikelyToKeepUp
          .observeOn(MainScheduler.asyncInstance)
          .asDriver(onErrorJustReturn: false)
      } else {
        return .empty()
      }
      }.map { [weak player] in
        return $0 ? PlayerState.active(state: player?.rate == 0.0 ? .paused : .playing ) : PlayerState.stuck
      }
      .asObservable().bind(to: stateRelay)
      .disposed(by: disposeBag)

    itemRelay.filter { $0 != nil }.flatMapLatest { item -> Observable<PlayerState> in
      if let item = item {
        return item.rx.didPlayToEnd.map { _ in PlayerState.finished }
      } else {
        return .empty()
      }
      }.bind(to: stateRelay)
      .disposed(by: disposeBag)

    itemRelay.filter { $0 != nil }.flatMapLatest { [weak self] item -> Observable<PlayerState> in
      if let item = item {
        return item.rx.status.filter { $0 == .readyToPlay }.take(1).map {_ in
          if let expectedStartTime = self?.expectedStartTime {
            self?.seek(to: expectedStartTime)
            self?.expectedStartTime = nil
          }
          return PlayerState.ready
        }
      } else {
        return .empty()
      }
      }.bind(to: stateRelay)
      .disposed(by: disposeBag)

    itemRelay.asDriver(onErrorJustReturn: nil).filter { $0 != nil }.flatMapLatest { item -> Driver<Error> in
      if let item = item {
        return item.rx.error.asDriver(onErrorJustReturn: nil).flatMap { error -> Driver<Error> in
          guard let error = error else { return .empty() }
          return .just(error)
        }
      } else {
        return .empty()
      }
		}.map { error in PlayerState.error(error: .playback(error: error)) }
      .asObservable()
      .bind(to: stateRelay)
      .disposed(by: disposeBag)
    self.disposeBag = disposeBag
  }

  open func startPlayback(with stream: String) {
    guard settings.retrieveQualities else { return }
    DispatchQueue.global(qos: .background).async { [weak self] in
      let builder = ManifestBuilder()
      if let url = URL(string: stream) {
        let manifest = builder.parse(url)
        let qualities = manifest.playlists.compactMap { submanifest -> VideoQuality? in
          guard let path = submanifest.path else { return nil }
          let urlString: String
          if path.starts(with: "http") || path.starts(with: "file") {
            urlString = path
          } else {
            urlString = url.URLByReplacingLastPathComponent(path)?.absoluteString ?? path
          }
          let description: String
          if submanifest.height > 0 {
            description = "\(submanifest.height)p"
          } else {
            description = "\(Int(submanifest.bandwidth / 1000.0)) Kbps"
          }
          return VideoQuality.stream(bandwidth: submanifest.bandwidth,
                                     resolution: CGSize( width: submanifest.width, height: submanifest.height),
                                     url: urlString, description: description)
        }
        guard let self = self else { return }
        let availableQualities = [.auto] + qualities
        let closestQuality = self.quality.closest(in: availableQualities)
        self.quality = closestQuality
        self.availableQualitiesRelay.onNext(availableQualities)
      }
    }
  }

  open func bind(to item: AVPlayerItem) {
    itemRelay.accept(item)
  }

  open func play() {
    player?.rate = Float(speed)
  }

  open func pause() {
    player?.rate = 0.0
  }

  open func stop() {
    player?.replaceCurrentItem(with: nil)
  }

  open func seek(to seconds: TimeInSeconds) {
    if let timeRange = player?.currentItem?.seekableTimeRanges.last?.timeRangeValue {
      let duration = timeRange.end
      let progress = seconds / CMTimeGetSeconds(duration)
      let time = CMTime(value: CMTimeValue(Double(duration.value) * progress), timescale: duration.timescale)
      let tolerance = CMTime(seconds: 0.5, preferredTimescale: 1)
      player?.currentItem?.cancelPendingSeeks()
      player?.currentItem?.seek(to: time, toleranceBefore: tolerance, toleranceAfter: tolerance, completionHandler: { [weak self] finished in
        if finished {
          self?.seekCompleatedRelay.accept(())
        }
      })
    }
  }
}
