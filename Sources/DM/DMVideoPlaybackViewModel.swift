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
import DailymotionPlayerSDK

open class DMVideoPlaybackViewModel: VideoPlayback {

  public let seek = PublishSubject<TimeInSeconds>()
  public let state = PublishSubject<PlaybackState>()

  public var time: Driver<TimeInSeconds> {
    return currentTimeRelay.asDriver().filter { $0.isFinite }
  }

  public var duration: Driver<TimeInSeconds> {
    return durationRelay.asDriver().filter { $0.isFinite }
  }

  public var loadedRange: Driver<LoadedTimeRange> {
    return progressRelay.asDriver().withLatestFrom(duration, resultSelector: { progress, duration in
      guard progress.isFinite && duration.isFinite else { return [] }
      return [0...duration * progress]
    })
  }

  public var playerState: Driver<PlayerState> {
    return playerStateRelay.asDriver(onErrorJustReturn: .idle)
  }

  public var seekCompleated: Driver<Void> {
    return seekCompleatedRelay.asDriver(onErrorJustReturn: ())
  }

  fileprivate let disposeBag = DisposeBag()

  let streamSubject = PublishSubject<Stream?>()
  let mutedRelay = BehaviorRelay<Bool>(value: true)
  let openUrlSubject = PublishSubject<URL>()
  var expectedStartTime: Double?

  fileprivate let seekCompleatedRelay = PublishRelay<Void>()
  fileprivate let currentTimeRelay    = BehaviorRelay<TimeInSeconds>(value: 0)
  fileprivate let durationRelay    = BehaviorRelay<TimeInSeconds>(value: 0)
  fileprivate let progressRelay    = BehaviorRelay<TimeInSeconds>(value: 0.0)
  fileprivate let playerStateRelay    = BehaviorRelay<PlayerState>(value: .idle)

  public typealias Stream = String
  open var input: Input<Stream> = .cleanup {

    willSet(newInput) {
      switch newInput {
      case .content(let stream):
        expectedStartTime = nil
        streamSubject.onNext(stream)
      case .contentWithStartTime(let stream, let startTime):
        expectedStartTime = startTime
        streamSubject.onNext(stream)
      case .ad:
        assertionFailure("External Ad is not supported by DM")
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
  
  init() {
    seek.bind(to: currentTimeRelay).disposed(by: disposeBag)
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
        durationRelay.accept(time)
      case "timeupdate":
        currentTimeRelay.accept(time)
      case "progress":
        progressRelay.accept(time)
      case "seeked":
        seekCompleatedRelay.accept(())
      default: break
      }
    case let .namedEvent(name, _):
      switch name {
      case "play":
        playerStateRelay.accept(PlayerState.active(state: PlaybackState.playing))
      case "pause":
        playerStateRelay.accept(PlayerState.active(state: PlaybackState.paused))
      case "video_end":
        playerStateRelay.accept(PlayerState.finished)
      case "ad_start":
        playerStateRelay.accept(.ad(state: .started))
      case "ad_end":
        playerStateRelay.accept(.ad(state: .finished))
      case "error":
        playerStateRelay.accept(.error(error: nil))
      default: break
      }
    }
  }

  public func player(_ player: DMPlayerViewController, openUrl url: URL) {
    openUrlSubject.onNext(url)
  }
}
