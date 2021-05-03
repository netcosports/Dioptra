//
//  ChromecastPlaybackViewModel.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 4/12/21.
//  Copyright © 2021 Netcosports. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

import GoogleCast

open class ChromecastPlaybackViewModel: NSObject, VideoPlayback {

  private var sessionManager: GCKSessionManager = GCKCastContext.sharedInstance().sessionManager
  private let mediaStatusRelay = PublishRelay<GCKMediaStatus>()
  private let currentStreamPositionRelay = BehaviorRelay<TimeInSeconds>(value: .nan)

  fileprivate let hasActiveSessionRelay = BehaviorRelay<Bool>(value: false)

  public let seek = PublishSubject<TimeInSeconds>()
  public let state = PublishSubject<PlaybackState>()

  fileprivate var currentSeekRequest: GCKRequest?

  public var time: Driver<TimeInSeconds> {
    return currentStreamPositionRelay.asDriver(onErrorJustReturn: 0.0).filter { $0.isFinite }
  }

  public var duration: Driver<TimeInSeconds> {
    return mediaStatusRelay.asDriver(onErrorJustReturn: .init())
      .map { [weak self] mediaStatus -> TimeInSeconds in
        guard let remoteMediaClient = self?.sessionManager.currentSession?.remoteMediaClient else {
          return 0.0
        }
        if remoteMediaClient.isPlayingLiveStream {
          return remoteMediaClient.approximateLiveSeekableRangeEnd()
        } else {
          return mediaStatus.currentQueueItem?.playbackDuration ?? 0.0
        }
    }.filter { $0.isFinite && $0 > 0.0 }
  }

  public var loadedRange: Driver<LoadedTimeRange> {
    // NOTE: not sure we need to display this
    return .empty()
  }

  public var playerState: Driver<PlayerState> {
    return playerStateRelay
      .distinctUntilChanged()
      .asDriver(onErrorJustReturn: .idle)
  }

  public var seekCompleated: Driver<Void> {
    return seekCompleatedRelay.asDriver(onErrorJustReturn: ())
  }

  fileprivate let disposeBag = DisposeBag()
  fileprivate let playerStateRelay = PublishRelay<PlayerState>()
  fileprivate let availableQualitiesRelay = PublishRelay<[VideoQuality]>()

  public let seekCompleatedRelay = PublishRelay<Void>()

  public typealias Stream = String
  open var input: Input<Stream> = .cleanup {

    willSet(newInput) {
      let expectedStartTime: Double
      let currentStream: Stream
      switch newInput {
      case .content(let stream):
        currentStream = stream
        expectedStartTime = 0.0
        playerStateRelay.accept(.loading)
      case .contentWithStartTime(let stream, let startTime):
        currentStream = stream
        expectedStartTime = startTime
        playerStateRelay.accept(.loading)
      default:
        return
      }

      guard let url = URL(string: currentStream), hasActiveSessionRelay.value else { return }

      let builder = GCKMediaLoadRequestDataBuilder()
      builder.startTime = expectedStartTime ?? 0.0
      let mediaInfoBuilder = GCKMediaInformationBuilder(contentURL: url)
      mediaInfoBuilder.contentID = currentStream
      mediaInfoBuilder.streamType = .buffered
      mediaInfoBuilder.contentType = "application/x-mpegurl"
//      mediaInfoBuilder.metadata = metadata
//      mediaInfoBuilder.mediaTracks = mediaTracks
//      mediaInfoBuilder.textTrackStyle = trackStyle
      builder.mediaInformation = mediaInfoBuilder.build()
      self.sessionManager.currentCastSession?.remoteMediaClient?.loadMedia(with: builder.build())
    }
  }

  open var muted: Bool {
    get {
      sessionManager.currentCastSession?.currentDeviceMuted ?? false
    }

    set {
      sessionManager.currentCastSession?.setDeviceMuted(muted)
    }
  }

  open var volume: Float = 1.0 {
    didSet {
      sessionManager.currentCastSession?.setDeviceVolume(volume)
    }
  }

  public var speedUpdated: Driver<Double> {
    return .empty()
  }

  public var quality = VideoQuality.auto
  public var speed: Double = 1.0

  override init() {
    super.init()

    hasActiveSessionRelay.asDriver().distinctUntilChanged()
      .flatMapLatest { [weak self] sessionIsActive -> Driver<TimeInSeconds> in
        guard let self = self, sessionIsActive else {
          return .empty()
        }
        return self.playerStateRelay.map { playerState -> Bool in
          switch playerState {
          case .active(let state):
            switch state {
            case .paused:
              return false
            default:
              return true
            }
          case .finished, .error:
            return false
          default:
            return false
          }
        }
        .asDriver(onErrorJustReturn: false)
        .distinctUntilChanged()
        .flatMapLatest { [weak self] heartbeat -> Driver<TimeInSeconds> in
          if heartbeat {
            return Driver<Int>.timer(.seconds(1), period: .seconds(1))
              .flatMap { [weak self] _ -> Driver<TimeInSeconds> in
              guard let remoteMediaClient = self?.sessionManager.currentSession?.remoteMediaClient else {
                return .empty()
              }
              switch remoteMediaClient.mediaStatus?.playerState {
              case .paused, .playing:
                return .just(remoteMediaClient.approximateStreamPosition())
              default: return .empty()
              }

            }
          } else {
            return .empty()
          }
        }
      }
      .drive(currentStreamPositionRelay)
      .disposed(by: disposeBag)

    state.asObservable().subscribe(onNext: { [weak self] state in
      switch state {
      case .paused:
        self?.sessionManager.currentSession?.remoteMediaClient?.pause()
      case .playing:
        self?.sessionManager.currentSession?.remoteMediaClient?.play()
      }
    }).disposed(by: disposeBag)

    seek.asObservable().subscribe(onNext: { [weak self] progress in
      let seekOptions = GCKMediaSeekOptions()
      seekOptions.interval = progress
      self?.currentSeekRequest?.cancel()
      self?.currentSeekRequest = self?.sessionManager.currentSession?.remoteMediaClient?.seek(with: seekOptions)
      self?.currentSeekRequest?.delegate = self
    }).disposed(by: disposeBag)

    sessionManager.add(self)
  }

  public var availableQualities: Driver<[VideoQuality]> {
    return availableQualitiesRelay.asDriver(onErrorJustReturn: [])
  }
}

extension ChromecastPlaybackViewModel: GCKSessionManagerListener {

  public func sessionManager(_: GCKSessionManager,
                      didStart session: GCKSession) {
    session.remoteMediaClient?.add(self)
    hasActiveSessionRelay.accept(true)
  }

  public func sessionManager(_: GCKSessionManager,
                      didResumeSession session: GCKSession) {
    session.remoteMediaClient?.add(self)
    hasActiveSessionRelay.accept(true)
  }

  public func sessionManager(_: GCKSessionManager,
                      didEnd session: GCKSession,
                      withError error: Error?) {
    session.remoteMediaClient?.remove(self)
    if let error = error {
      playerStateRelay.accept(.error(error: .connection(error: error)))
    }
    hasActiveSessionRelay.accept(false)
  }

  public func sessionManager(_: GCKSessionManager,
                      didFailToStart session: GCKSession,
                      withError error: Error) {
    session.remoteMediaClient?.remove(self)
  }
}

extension ChromecastPlaybackViewModel: GCKRemoteMediaClientListener {

  public func remoteMediaClient(_: GCKRemoteMediaClient,
                         didUpdate mediaStatus: GCKMediaStatus?) {
    guard let mediaStatus = mediaStatus else {
      return
    }
    mediaStatusRelay.accept(mediaStatus)
    switch mediaStatus.playerState {
    case .buffering:
      playerStateRelay.accept(.stuck)
    case .idle:
      // FIXME: correct management
      playerStateRelay.accept(.ready)
    case .loading:
      playerStateRelay.accept(.loading)
    case .paused:
      playerStateRelay.accept(.active(state: .paused))
    case .playing:
      playerStateRelay.accept(.active(state: .playing))
    default: break
    }
  }
}

extension ChromecastPlaybackViewModel: GCKRequestDelegate {

  public func requestDidComplete(_ request: GCKRequest) {
    // NOTE: we set callback only for seek request
    print("TEST requestDidComplete")
    seekCompleatedRelay.accept(())
  }

  public func request(_ request: GCKRequest,
               didFailWithError error: GCKError) {
    print("request \(Int(request.requestID)) didFailWithError \(error)")
  }

  public func request(_ request: GCKRequest,
               didAbortWith abortReason: GCKRequestAbortReason) {
    print("request \(Int(request.requestID)) didAbortWith reason \(abortReason)")
  }
}


public extension Reactive where Base == ChromecastPlaybackViewModel {

  var connected: Observable<Bool> {
    base.hasActiveSessionRelay.asObservable().distinctUntilChanged()
  }
}
