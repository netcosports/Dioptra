//
//  BCVideoPlaybackWithControlsViewModel.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 7/05/18.
//  Copyright © 2019 Sergei Mikhan. All rights reserved.
//

import AVKit
import BrightcovePlayerSDK
import RxSwift
import RxCocoa

open class BCVideoPlaybackWithControlsViewModel: NSObject, VideoPlayback {

  var service: BCOVPlaybackService?
  lazy var playback: BCOVPlaybackController? = {
    guard let playback = self.playbackCreation?() else { return nil }
    playback.delegate = self
    playback.isAutoAdvance = true
    playback.isAutoPlay = true
    playback.allowsExternalPlayback = true
    return playback
  }()

  public typealias PlaybackCreationBlock = ()->(BCOVPlaybackController?)

  open var accountID = ""
  open var servicePolicyKey = ""
  open var playbackCreation: PlaybackCreationBlock?

  public let seek = PublishSubject<TimeInSeconds>()
  public let state = PublishSubject<PlaybackState>()
  fileprivate var playing = true

  public var time: Driver<TimeInSeconds> {
    return currentTimeRelay.asDriver(onErrorJustReturn: 0.0).filter { $0.isFinite }
  }

  public var duration: Driver<TimeInSeconds> {
    return durationRelay.asDriver(onErrorJustReturn: 0.0).filter { $0.isFinite && $0 > 0.0 }
  }

  public var loadedRange: Driver<LoadedTimeRange> {
    return progressRelay.asDriver(onErrorJustReturn: 0.0).withLatestFrom(duration, resultSelector: { progress, duration in
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


  let mutedRelay = BehaviorRelay<Bool>(value: true)
  let openUrlSubject = PublishSubject<URL>()
  var expectedStartTime: Double?

  fileprivate let seekCompleatedRelay = PublishRelay<Void>()
  fileprivate let currentTimeRelay    = PublishRelay<TimeInSeconds>()
  fileprivate let durationRelay    = PublishRelay<TimeInSeconds>()
  fileprivate let progressRelay    = PublishRelay<TimeInSeconds>()
  fileprivate let playerStateRelay    = PublishRelay<PlayerState>()
  fileprivate let availableQualitiesRelay = PublishRelay<[VideoQuality]>()

  public typealias Stream = String
  open var input: Input<Stream> = .cleanup {

    willSet(newInput) {
      switch newInput {
      case .content(let stream):
        expectedStartTime = nil
        startPlayback(with: stream)
        playerStateRelay.accept(.loading)
      case .contentWithStartTime(let stream, let startTime):
        expectedStartTime = startTime
        startPlayback(with: stream)
        playerStateRelay.accept(.loading)
      case .ad:
        assertionFailure("External Ad is not supported by BC")
      default:
        playback?.setVideos([] as NSFastEnumeration)
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

  public var speedUpdated: Driver<Double> {
    return .empty()
  }

  public var quality = VideoQuality.auto
  public var speed: Double = 1.0

  override init() {
    super.init()
    seek.bind(to: currentTimeRelay).disposed(by: disposeBag)

    state.subscribe(onNext: { [weak self] state in
      switch state {
      case .paused: self?.playback?.pause()
      case .playing: self?.playback?.play()
      }
    }).disposed(by: disposeBag)
  }

  public var availableQualities: Driver<[VideoQuality]> {
    return availableQualitiesRelay.asDriver(onErrorJustReturn: [])
  }

  private func startPlayback(with stream: String) {
    guard let service = BCOVPlaybackService(accountId: accountID, policyKey: servicePolicyKey) else {
      return
    }
    service.findVideo(withVideoID: stream, parameters: [:]) { [weak self] (video, params, error) in
      guard let video = video else {
        self?.playerStateRelay.accept(.error(error: error))
        return
      }
      self?.playback?.setVideos([video] as NSFastEnumeration)
    }
    self.service = service
  }
}

extension BCVideoPlaybackWithControlsViewModel: BCOVPlaybackControllerDelegate {


  public func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {

  }

  public func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didProgressTo progress: TimeInterval) {
    currentTimeRelay.accept(progress)
  }

  public func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didChangeDuration duration: TimeInterval) {
    durationRelay.accept(duration)
  }

  public func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didEnter ad: BCOVAd!) {
    playerStateRelay.accept(.ad(state: .started))
  }

  public func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didExitAd ad: BCOVAd!) {
    playerStateRelay.accept(.ad(state: .finished))
  }

  public func playbackController(_ controller: BCOVPlaybackController!, playbackSession session: BCOVPlaybackSession!, didReceive lifecycleEvent: BCOVPlaybackSessionLifecycleEvent!) {
    switch lifecycleEvent.eventType {
    case kBCOVPlaybackSessionLifecycleEventReady, kBCOVPlaybackSessionLifecycleEventFailedToPlayToEndTime:
      playerStateRelay.accept(.ready)
    case kBCOVPlaybackSessionLifecycleEventFail, kBCOVPlaybackSessionLifecycleEventError:
      playerStateRelay.accept(.error(error: nil))
    case kBCOVPlaybackSessionLifecycleEventPlay:
      playerStateRelay.accept(.active(state: .playing))
      playing = true
    case kBCOVPlaybackSessionLifecycleEventPause:
      playerStateRelay.accept(.active(state: .paused))
      playing = false
    case kBCOVPlaybackSessionLifecycleEventPlaybackBufferEmpty:
      playerStateRelay.accept(.stuck)
    case kBCOVPlaybackSessionLifecycleEventEnd:
      playerStateRelay.accept(.finished)
    default: break
    }
  }
}
