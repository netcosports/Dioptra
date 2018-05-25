//
//  DMVideoPlaybackViewModel.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 5/4/17.
//  Copyright © 2018 Netcosports. All rights reserved.
//

import UIKit
import SafariServices
import RxSwift
import RxCocoa
import DailymotionPlayerSDK

open class DMVideoPlaybackViewModel: VideoPlayback {

  let streamSubject = PublishSubject<Stream?>()
  public let seek = PublishSubject<TimeInSeconds>()
  public let state = PublishSubject<PlaybackState>()

  public var time: Driver<TimeInSeconds> {
    return currentTimeVariable.asDriver()
  }

  public var duration: Driver<TimeInSeconds> {
    return durationVariable.asDriver()
  }

  public var progress: Driver<Progress> {
    return Driver.combineLatest(time, duration).map { Progress(value: $0, total: $1) }
  }

  public var loadedRange: Driver<LoadedTimeRange> {
    return Driver.combineLatest(progressVariable.asDriver(), duration).map { [weak self] progress, duration in
      guard let `self` = self else { return [] }
      return [0...duration * progress / 100.0]
    }
  }

  public var started: Driver<String> {
    return streamSubject.asDriver(onErrorJustReturn: nil).flatMap {
      if let stream = $0 {
        return .just(stream)
      }
      return .empty()
    }
  }

  public var finished: Driver<String> {
    return finishedSubject.asDriver(onErrorJustReturn: "")
  }

  public var playerState: Driver<PlayerState> {
    return playerStateRelay.asDriver(onErrorJustReturn: .idle)
  }

  fileprivate var startCount: Int = 0
  fileprivate let disposeBag = DisposeBag()

  let mutedRelay = BehaviorRelay<Bool>(value: true)
  let openUrlSubject = PublishSubject<URL>()

  fileprivate let currentTimeVariable = BehaviorRelay<TimeInSeconds>(value: 0)
  fileprivate let durationVariable    = BehaviorRelay<TimeInSeconds>(value: 0)
  fileprivate let progressVariable    = BehaviorRelay<TimeInSeconds>(value: 0.0)
  fileprivate let playerStateRelay    = BehaviorRelay<PlayerState>(value: .idle)
  fileprivate let finishedSubject     = PublishSubject<Stream>()

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


extension DMVideoPlaybackViewModel: DMPlayerViewControllerDelegate {

  public func playerDidInitialize(_ player: DMPlayerViewController) {

  }

  public func player(_ player: DMPlayerViewController, didFailToInitializeWithError error: Error) {

  }

  public func player(_ player: DMPlayerViewController, didReceiveEvent event: PlayerEvent) {
    switch event {
    case let .timeEvent(name, time):
      switch name {
      case "durationchange":
        durationVariable.accept(time)
      case "timeupdate":
        currentTimeVariable.accept(time)
      case "progress":
        progressVariable.accept(time)
      default: break
      }
    case let .namedEvent(name, _):
      switch name {
      case "play":
        if startCount > 0 {
          playerStateRelay.accept(PlayerState.active(state: PlaybackState.playing))
        }
        startCount += 1
      case "pause":
        playerStateRelay.accept(PlayerState.active(state: PlaybackState.paused))
      case "video_end":
        if let stream = stream {
          finishedSubject.onNext(stream)
        }
      case "ad_start":
        playerStateRelay.accept(.ad(state: .started))
      case "ad_end":
        playerStateRelay.accept(.ad(state: .finished))
      default: break
      }
    }
  }

  public func player(_ player: DMPlayerViewController, openUrl url: URL) {
    openUrlSubject.onNext(url)
    // NOTE: go to portrait and open safari modally
    //    if containerViewController?.presentedViewController != nil {
    //      containerViewController?.presentedViewController?.dismiss(animated: true) {
    //        let controller = SFSafariViewController(url: url)
    //        self.containerViewController?.present(controller, animated: true, completion: nil)
    //      }
    //      return
    //    }
    //    let controller = SFSafariViewController(url: url)
    //    containerViewController?.present(controller, animated: true, completion: nil)
  }
}
