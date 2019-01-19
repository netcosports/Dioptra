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

open class AVVideoPlaybackViewModel: AVVideoPlaybackManagableViewModel {

  override init() {
    super.init()
    bind(to: AVPlayer())
  }

  override func startPlayback(with stream: String) {
    let item: AVPlayerItem
    if stream.hasPrefix("http") {
      guard let url = URL(string: stream) else { return }
      item = AVPlayerItem(url: url)
    } else {
      let url = URL(fileURLWithPath: stream)
      item = AVPlayerItem(url: url)
    }
    bind(to: item)
    player?.replaceCurrentItem(with: item)
    player?.play()
  }
}

open class AVVideoPlaybackManagableViewModel: NSObject, VideoPlayback {

  fileprivate let seekCompleatedRelay = PublishRelay<Void>()
  fileprivate static var interval       = CMTime(value: 1, timescale: 60)
  fileprivate var disposeBag: DisposeBag?
  fileprivate let itemRelay             = PublishRelay<AVPlayerItem?>()
  fileprivate let currentTimeRelay      = PublishRelay<TimeInSeconds>()
  let stateRelay                        = PublishRelay<PlayerState>()
  var expectedStartTime: Double?


  var player: AVPlayer?

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

  public var muted: Bool = false {
    didSet {
      player?.isMuted = muted
      player?.currentItem?.audioMix = nil
    }
  }

  public let seek = PublishSubject<TimeInSeconds>()
  public var state = PublishSubject<PlaybackState>()
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

  public func bind(to player: AVPlayer) {
    self.player = player
    player.isMuted = self.muted
    player.actionAtItemEnd = .none
    let disposeBag = DisposeBag()
    player.rx.periodicTimeObserver(interval: AVVideoPlaybackViewModel.interval)
      .map { CMTimeGetSeconds($0) }
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
    .map {
      return $0 != 0 ? PlayerState.active(state: .playing) : PlayerState.active(state: .paused)
    }
    .bind(to: stateRelay)
    .disposed(by: disposeBag)

    itemRelay.asDriver(onErrorJustReturn: nil).filter { $0 != nil }.flatMapLatest { item -> Driver<Bool> in
        if let item = item {
          return item.rx.playbackLikelyToKeepUp
            .observeOn(MainScheduler.asyncInstance)
            .asDriver(onErrorJustReturn: false)
        } else {
          return .empty()
        }
      }.map { [weak player] in
        return $0 ? PlayerState.active(state: player?.rate == 1.0 ? .playing : .paused) : PlayerState.stuck
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
      }.map { error in PlayerState.error(error: error) }
      .asObservable()
      .bind(to: stateRelay)
      .disposed(by: disposeBag)
    self.disposeBag = disposeBag
  }

  func startPlayback(with stream: String) { }
}


extension AVVideoPlaybackManagableViewModel {

  func bind(to item: AVPlayerItem) {
    itemRelay.accept(item)
  }
}

extension AVVideoPlaybackManagableViewModel {

  fileprivate func play() {
    player?.play()
  }

  fileprivate func pause() {
    player?.pause()
  }

  fileprivate func stop() {
    player?.replaceCurrentItem(with: nil)
  }

  fileprivate func seek(to seconds: TimeInSeconds) {
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
