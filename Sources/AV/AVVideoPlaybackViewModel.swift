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

open class AVVideoPlaybackViewModel: VideoPlayback {

  fileprivate static var interval       = CMTime(value: 1, timescale: 60)
  fileprivate let disposeBag            = DisposeBag()
  fileprivate let itemRelay             = BehaviorRelay<AVPlayerItem?>(value: nil)
  fileprivate let streamPublishSubject  = PublishSubject<Stream>()
  fileprivate let currentTimeRelay      = BehaviorRelay<TimeInSeconds>(value: 0)
  fileprivate let stateRelay            = BehaviorRelay<PlayerState>(value: .idle)

  let player = AVPlayer()

  public init() {
    bind(to: player)
  }

  public typealias Stream = String
  public var stream: Stream? {
    willSet(newStreamUrl) {
      if let newStreamUrl = newStreamUrl {
        if newStreamUrl != stream {
          startPlayback(with: newStreamUrl)
          streamPublishSubject.onNext(newStreamUrl)
          stateRelay.accept(.loading)
        }
      } else {
        stop()
      }
    }
  }

  public var muted: Bool = false {
    didSet {
      player.isMuted = muted
      player.currentItem?.audioMix = nil
    }
  }

  public let seek = PublishSubject<TimeInSeconds>()
  public var state = PublishSubject<PlaybackState>()
  public var time: Driver<TimeInSeconds> {
    return currentTimeRelay.asDriver()
  }

  public var duration: Driver<TimeInSeconds> {
    return itemRelay.asDriver().flatMapLatest { item -> Driver<TimeInSeconds> in
      if let item = item {
        return item.rx.duration.distinctUntilChanged().asDriver(onErrorJustReturn: CMTime.zero).map { duration -> TimeInSeconds in
          return CMTimeGetSeconds(duration)
        }
      } else {
        return .empty()
      }
    }
  }

  public var progress: Driver<Progress> {
    return Driver.combineLatest(time, duration).map { Progress(value: $0, total:$1) }
  }

  public var loadedRange: Driver<LoadedTimeRange> {
    return itemRelay.asDriver().flatMapLatest { item -> Driver<LoadedTimeRange> in
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

  public var started: Driver<Stream> {
    return streamPublishSubject.asDriver(onErrorJustReturn: "")
  }

  public var finished: Driver<Stream> {
    return itemRelay.asDriver().flatMapLatest { item -> Driver<Stream> in
      if let item = item {
        return item.rx.didPlayToEnd.flatMap { [weak self] _ -> Observable<Stream> in
          return .just(self?.stream ?? "")
          }.asDriver(onErrorJustReturn: "")
      } else {
        return .empty()
      }
    }
  }

  public var playerState: Driver<PlayerState> {
    return stateRelay.asDriver()
  }
}


extension AVVideoPlaybackViewModel {

  fileprivate func bind(to player: AVPlayer) {
    player.rx.periodicTimeObserver(interval: AVVideoPlaybackViewModel.interval)
      .map { CMTimeGetSeconds($0) }
      .bind(to: currentTimeRelay)
      .disposed(by: disposeBag)

    seek.asDriver(onErrorJustReturn: 0.0).drive(onNext: { [weak self] seconds in
      self?.seek(to: seconds)
      // TODO: we need to clarify is it necessary since we have periodic updates
      self?.currentTimeRelay.accept(seconds)
    }).disposed(by: disposeBag)

    state.asDriver(onErrorJustReturn: .paused).drive(onNext: { [weak self] state in
      switch state {
      case .playing:
        self?.play()
      case .paused:
        self?.pause()
      }
    }).disposed(by: disposeBag)

    player.rx.rate.map { $0 != 0 }
      .map { $0 ? PlayerState.active(state: .playing) : PlayerState.active(state: .paused) }
      .bind(to: stateRelay)
      .disposed(by: disposeBag)

    itemRelay.asDriver().flatMapFirst { item -> Driver<Bool> in
      if let item = item {
        return item.rx.playbackLikelyToKeepUp.asDriver(onErrorJustReturn: false)
      } else {
        return .empty()
      }
      }
      .map { $0 ? PlayerState.active(state: .playing) : PlayerState.stuck }
      .drive(stateRelay)
      .disposed(by: disposeBag)

    itemRelay.asDriver().flatMapLatest { item -> Driver<Error?> in
      if let item = item {
        return item.rx.error.asDriver(onErrorJustReturn: nil).map { error -> Error? in return error }
      } else {
        return .empty()
      }
    }.map { error in PlayerState.error(error: error) }
    .drive(stateRelay)
    .disposed(by: disposeBag)
  }

  fileprivate func bind(to item: AVPlayerItem) {
    itemRelay.accept(item)
  }
}

extension AVVideoPlaybackViewModel {

  fileprivate func play() {
    player.play()
  }

  fileprivate func pause() {
    player.pause()
  }

  fileprivate func stop() {
    player.pause()
    player.replaceCurrentItem(with: nil)
  }

  fileprivate func seek(to seconds: TimeInSeconds) {
    if let duration = player.currentItem?.duration {
      if duration.isIndefinite { return }
      let progress = seconds / CMTimeGetSeconds(duration)
      let time = CMTime(value: CMTimeValue(Double(duration.value) * progress), timescale: duration.timescale)
      player.seek(to: time)
    }
  }

  fileprivate func startPlayback(with url: String) {
    let item: AVPlayerItem
    if url.hasPrefix("http") {
      guard let url = URL(string: url) else { return }
      item = AVPlayerItem(url: url)
    } else {
      let url = URL(fileURLWithPath: url)
      item = AVPlayerItem(url: url)
    }
    bind(to: item)
    player.replaceCurrentItem(with: item)
    player.play()
  }
}
