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
  public var quality: VideoQuality = .auto
  public var speed: Double = 1.0

  public var time: Driver<TimeInSeconds> {
    return currentTimeVariable.asDriver(onErrorJustReturn: 0.0).filter { $0.isFinite }
  }

  public var duration: Driver<TimeInSeconds> {
    return durationVariable.asDriver(onErrorJustReturn: 0.0).filter { $0.isFinite && $0 > 0.0 }
  }

  public var loadedRange: Driver<LoadedTimeRange> {
    return progressVariable.asDriver(onErrorJustReturn: 0.0).withLatestFrom(duration, resultSelector: { progress, duration in
      guard progress.isFinite && duration.isFinite else { return [] }
      return [0...duration * progress]
    })
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
  fileprivate let currentTimeVariable = PublishRelay<TimeInSeconds>()
  fileprivate let durationVariable    = PublishRelay<TimeInSeconds>()
  fileprivate let progressVariable    = PublishRelay<TimeInSeconds>()
  fileprivate let playerStateRelay    = PublishRelay<PlayerState>()
  fileprivate let availableQualitiesRelay = PublishRelay<[VideoQuality]>()

  var expectedStartTime: Double?

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
        expectedStartTime = nil
        startCount = 0
        streamSubject.onNext(stream)
      case .contentWithStartTime(let stream, let startTime):
        expectedStartTime = startTime
        startCount = 0
        streamSubject.onNext(stream)
      case .ad:
        assertionFailure("External Ad is not supported by YT")
      default:
        streamSubject.onNext(nil)
      }
    }
  }

  public var speedUpdated: Driver<Double> {
    return .empty()
  }

  public var availableQualities: Driver<[VideoQuality]> {
    return availableQualitiesRelay.asDriver(onErrorJustReturn: [])
  }

  open var muted: Bool {
    get {
      return mutedRelay.value
    }

    set {
      mutedRelay.accept(muted)
    }
  }

  open var volume: Float = 1.0
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
