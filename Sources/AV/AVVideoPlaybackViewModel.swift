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

  fileprivate static var interval       = CMTime(value: 1, timescale: 60)
  fileprivate var disposeBag: DisposeBag?
  fileprivate let itemRelay             = BehaviorRelay<AVPlayerItem?>(value: nil)
  fileprivate let currentTimeRelay      = BehaviorRelay<TimeInSeconds>(value: 0)
  fileprivate let stateRelay            = BehaviorRelay<PlayerState>(value: .idle)

  var player: AVPlayer?

  public typealias Stream = String
  public var input: Input<Stream> = .cleanup {
    willSet(newInput) {
      switch newInput {
      case .content(let stream):
        startPlayback(with: stream)
        stateRelay.accept(.loading)
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
    return currentTimeRelay.asDriver()
  }

  public var duration: Driver<TimeInSeconds> {
    return itemRelay.asDriver().filter { $0 != nil }.flatMapLatest { item -> Driver<TimeInSeconds> in
      if let item = item {
        return item.rx.duration.distinctUntilChanged().asDriver(onErrorJustReturn: CMTime.zero).map { duration -> TimeInSeconds in
          return CMTimeGetSeconds(duration)
        }
      } else {
        return .empty()
      }
    }
  }

  public var loadedRange: Driver<LoadedTimeRange> {
    return itemRelay.asDriver().filter { $0 != nil }.flatMapLatest { item -> Driver<LoadedTimeRange> in
      if let item = item {
        return item.rx.loadedTimeRanges.asDriver(onErrorJustReturn: []).map { ranges -> LoadedTimeRange in
          return ranges.map {
            let start = CMTimeGetSeconds($0.start)
            let end = start + CMTimeGetSeconds($0.duration)
            return TimeInSecondsRange(uncheckedBounds: (lower: start, upper: end))
          }
        }
      } else {
        return .empty()
      }
    }
  }

  public var playerState: Driver<PlayerState> {
    return stateRelay.asDriver()
  }

  public func bind(to player: AVPlayer) {
    self.player = player
    player.actionAtItemEnd = .none
    let disposeBag = DisposeBag()
    player.rx.periodicTimeObserver(interval: AVVideoPlaybackViewModel.interval)
      .map { CMTimeGetSeconds($0) }
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

    player.rx.rate
      .filter { [weak self] _ in
        guard let item = self?.itemRelay.value else { return false }
        return item.duration.seconds != item.currentTime().seconds
      }
      .distinctUntilChanged()
      .map {
        return $0 != 0 ? PlayerState.active(state: .playing) : PlayerState.active(state: .paused)
      }
      .bind(to: stateRelay)
      .disposed(by: disposeBag)

    itemRelay.asDriver().filter { $0 != nil }.flatMapLatest { item -> Driver<Bool> in
        if let item = item {
          return item.rx.playbackLikelyToKeepUp
            .observeOn(MainScheduler.asyncInstance)
            .asDriver(onErrorJustReturn: false)
        } else {
          return .empty()
        }
      }.map {
        return $0 ? PlayerState.active(state: .playing) : PlayerState.stuck
      }
      .drive(stateRelay)
      .disposed(by: disposeBag)

    itemRelay.filter { $0 != nil }.flatMapLatest { item -> Observable<PlayerState> in
      if let item = item {
        return item.rx.didPlayToEnd.map { _ in PlayerState.finished }
      } else {
        return .empty()
      }
      }.bind(to: stateRelay)
      .disposed(by: disposeBag)

    itemRelay.filter { $0 != nil }.flatMapLatest { item -> Observable<PlayerState> in
      if let item = item {
        return item.rx.status.filter { $0 == .readyToPlay }.take(1).map { _ in PlayerState.ready }
      } else {
        return .empty()
      }
      }.bind(to: stateRelay)
      .disposed(by: disposeBag)

    itemRelay.asDriver().filter { $0 != nil }.flatMapLatest { item -> Driver<Error> in
        if let item = item {
          return item.rx.error.asDriver(onErrorJustReturn: nil).flatMap { error -> Driver<Error> in
            guard let error = error else { return .empty() }
            return .just(error)
          }
        } else {
          return .empty()
        }
      }.map { error in PlayerState.error(error: error) }
      .drive(stateRelay)
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
    if let duration = player?.currentItem?.duration {
      if duration.isIndefinite { return }
      let progress = seconds / CMTimeGetSeconds(duration)
      let time = CMTime(value: CMTimeValue(Double(duration.value) * progress), timescale: duration.timescale)
      player?.seek(to: time)
    }
  }
}
