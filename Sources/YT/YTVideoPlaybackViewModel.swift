//
//  DMVideoPlaybackViewModel.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 5/4/17.
//  Copyright © 2018 Netcosports. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import youtube_ios_player_helper

open class YTVideoPlaybackViewModel: NSObject, VideoPlayback {

  public let seek = PublishSubject<TimeInSeconds>()
  public let state = PublishSubject<PlaybackState>()

  public var time: Driver<TimeInSeconds> {
    return currentTimeVariable.asDriver()
  }

  public var duration: Driver<TimeInSeconds> {
    return durationVariable.asDriver()
  }

  public var loadedRange: Driver<LoadedTimeRange> {
    return Driver.combineLatest(progressVariable.asDriver(), duration).map { [weak self] progress, duration in
      guard let `self` = self else { return [] }
      return [0...duration * progress]
    }
  }

  public var playerState: Driver<PlayerState> {
    return playerStateRelay.asDriver(onErrorJustReturn: .idle)
  }

  public var seekCompleated: Driver<Void> {
    return seekCompletionRelay.asDriver(onErrorJustReturn: ())
  }

  fileprivate var startCount: Int = 0
  fileprivate let disposeBag = DisposeBag()

  let streamSubject = PublishSubject<Stream?>()
  let mutedRelay = BehaviorRelay<Bool>(value: true)
  let openUrlSubject = PublishSubject<URL>()

  fileprivate let seekCompletionRelay = PublishRelay<Void>()
  fileprivate let currentTimeVariable = BehaviorRelay<TimeInSeconds>(value: 0)
  fileprivate let durationVariable    = BehaviorRelay<TimeInSeconds>(value: 0)
  fileprivate let progressVariable    = BehaviorRelay<TimeInSeconds>(value: 0.0)
  fileprivate let playerStateRelay    = BehaviorRelay<PlayerState>(value: .idle)

  public override init() {
    super.init()
    seekCompletionRelay.subscribe(onNext: { [weak self] _ in
      #warning("FIXME: we need to find correct way to manage completion")
      self?.seekCompletionRelay.accept(())
    }).disposed(by: disposeBag)
  }

  public typealias Stream = String
  open var input: Input<Stream> = .cleanup {

    willSet(newInput) {
      switch newInput {
      case .content(let stream):
        startCount = 0
        streamSubject.onNext(stream)
      case .ad:
        assertionFailure("External Ad is not supported by YT")
      default:
        streamSubject.onNext(nil)
      }
    }
  }

  open var muted: Bool {
    get {
      return mutedRelay.value
    }

    set {
      mutedRelay.accept(muted)
    }
  }
}


extension YTVideoPlaybackViewModel: YTPlayerViewDelegate {

  public func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
    state.onNext(.playing)
    durationVariable.accept(TimeInSeconds(playerView.duration()))
  }

  public func playerView(_ playerView: YTPlayerView, didPlayTime playTime: Float) {
    currentTimeVariable.accept(TimeInSeconds(playTime))
    progressVariable.accept(TimeInSeconds(playerView.videoLoadedFraction()))
  }

  public func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
    switch state {
    case .buffering:
      if startCount > 0 {
        playerStateRelay.accept(PlayerState.active(state: PlaybackState.playing))
      }
      startCount += 1
      playerStateRelay.accept(PlayerState.loading)
    case .ended:
      playerStateRelay.accept(PlayerState.finished)
    case .paused:
      playerStateRelay.accept(PlayerState.active(state: PlaybackState.paused))
    case .playing:
      playerStateRelay.accept(PlayerState.active(state: PlaybackState.playing))
    default: break
    }
  }

  public func playerView(_ playerView: YTPlayerView, receivedError error: YTPlayerError) {
    playerStateRelay.accept(.error(error: nil))
  }

  public func playerViewPreferredWebViewBackgroundColor(_ playerView: YTPlayerView) -> UIColor {
    return UIColor.black
  }
}
