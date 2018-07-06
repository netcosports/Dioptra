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
      return [0...duration * progress / 100.0]
    }
  }

  public var playerState: Driver<PlayerState> {
    return playerStateRelay.asDriver(onErrorJustReturn: .idle)
  }

  fileprivate var startCount: Int = 0
  fileprivate let disposeBag = DisposeBag()

  let streamSubject = PublishSubject<Stream?>()
  let mutedRelay = BehaviorRelay<Bool>(value: true)
  let openUrlSubject = PublishSubject<URL>()

  fileprivate let currentTimeVariable = BehaviorRelay<TimeInSeconds>(value: 0)
  fileprivate let durationVariable    = BehaviorRelay<TimeInSeconds>(value: 0)
  fileprivate let progressVariable    = BehaviorRelay<TimeInSeconds>(value: 0.0)
  fileprivate let playerStateRelay    = BehaviorRelay<PlayerState>(value: .idle)

  public typealias Stream = String
  open var stream: String? {

    willSet(newStream) {
      if let newStream = newStream {
        if newStream != stream {
          startCount = 0
          streamSubject.onNext(newStream)
        }
      } else {
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

  }

  public func playerView(_ playerView: YTPlayerView, didPlayTime playTime: Float) {

  }

  public func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
    switch state {
    case .unstarted:
      
    default:
    }
  }

  public func playerView(_ playerView: YTPlayerView, receivedError error: YTPlayerError) {

  }

  public func playerViewPreferredWebViewBackgroundColor(_ playerView: YTPlayerView) -> UIColor {
    return UIColor.black
  }

//  public func playerDidInitialize(_ player: DMPlayerViewController) {
//
//  }
//
//  public func player(_ player: DMPlayerViewController, didFailToInitializeWithError error: Error) {
//
//  }
//
//  public func player(_ player: DMPlayerViewController, didReceiveEvent event: PlayerEvent) {
//    switch event {
//    case let .timeEvent(name, time):
//      switch name {
//      case "durationchange":
//        durationVariable.accept(time)
//      case "timeupdate":
//        currentTimeVariable.accept(time)
//      case "progress":
//        progressVariable.accept(time)
//      default: break
//      }
//    case let .namedEvent(name, _):
//      switch name {
//      case "play":
//        if startCount > 0 {
//          playerStateRelay.accept(PlayerState.active(state: PlaybackState.playing))
//        }
//        startCount += 1
//      case "pause":
//        playerStateRelay.accept(PlayerState.active(state: PlaybackState.paused))
//      case "video_end":
//        playerStateRelay.accept(PlayerState.finished)
//      case "ad_start":
//        playerStateRelay.accept(.ad(state: .started))
//      case "ad_end":
//        playerStateRelay.accept(.ad(state: .finished))
//      default: break
//      }
//    }
//  }
//
//  public func player(_ player: DMPlayerViewController, openUrl url: URL) {
//    openUrlSubject.onNext(url)
//    // NOTE: go to portrait and open safari modally
//    //    if containerViewController?.presentedViewController != nil {
//    //      containerViewController?.presentedViewController?.dismiss(animated: true) {
//    //        let controller = SFSafariViewController(url: url)
//    //        self.containerViewController?.present(controller, animated: true, completion: nil)
//    //      }
//    //      return
//    //    }
//    //    let controller = SFSafariViewController(url: url)
//    //    containerViewController?.present(controller, animated: true, completion: nil)
//  }
}
