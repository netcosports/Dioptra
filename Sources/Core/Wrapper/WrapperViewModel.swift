//
//  WrapperViewModel.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 12/24/19.
//

import RxSwift
import RxCocoa

open class WrapperViewModel: NSObject, VideoPlayback {

  fileprivate var disposeBag: DisposeBag?

  fileprivate let currentTimeRelay        = PublishRelay<TimeInSeconds>()
  fileprivate let durationRelay           = PublishRelay<TimeInSeconds>()
  fileprivate let bufferedRelay           = PublishRelay<TimeInSeconds>()
  fileprivate let speedRelay              = PublishRelay<Double>()
  fileprivate let availableQualitiesRelay = BehaviorSubject<[VideoQuality]>(value: [.auto])
  fileprivate let stateRelay              = PublishRelay<PlayerState>()
  fileprivate let seekCompleatedRelay     = PublishRelay<Void>()
  let wrapperInstanceRelay    = PublishRelay<PlayerWrapper?>()
  
  public var player: PlayerWrapper? {
    didSet {
      wrapperInstanceRelay.accept(player)
      bind()
    }
  }
  
  private func bind() {
    let disposeBag = DisposeBag()
    player?.setDidChangePlayerState(closure: { [weak self] playerState in
      self?.stateRelay.accept(playerState)
    })
    
    player?.setDidChangeAvailableVideoQualities(closure: { [weak self] qualities in
      self?.availableQualitiesRelay.onNext(qualities)
    })
    
    player?.setDidChangeProgress(closure: { [weak self] event in
      switch event {
      case .progress(let time):
        self?.currentTimeRelay.accept(time)
      case .duration(let duration):
        self?.durationRelay.accept(duration)
      case .buffer(let buffer):
        self?.bufferedRelay.accept(buffer)
      }
    })
    
    seek.asDriver(onErrorJustReturn: 0.0).drive(onNext: { [weak self] seconds in
      self?.player?.seek(progress: seconds, completion: {
        self?.seekCompleatedRelay.accept(())
      })
      // TODO: we need to clarify is it necessary since we have periodic updates
      self?.currentTimeRelay.accept(seconds)
    }).disposed(by: disposeBag)

    state
      .observeOn(MainScheduler.asyncInstance)
      .asDriver(onErrorJustReturn: .paused).drive(onNext: { [weak self] state in
        self?.player?.setPlaybackState(state: state)
      }).disposed(by: disposeBag)
    self.disposeBag = disposeBag
  }

  public typealias Stream = String
  public var input: Input<Stream> = .cleanup {

    didSet {
      print("No actions here...")
    }
  }

  public var muted: Bool = false {
    didSet {
      player?.isMuted = muted
    }
  }

  public var volume: Float  = 1.0 {
    didSet {
      // Not implemented for wrapper
    }
  }

  public var quality = VideoQuality.auto {
    didSet {
      player?.selectVideoQuality(videoQuality: quality)
    }
  }
  public var speed: Double = 1.0 {
    didSet {
      player?.playbackSpeed = speed
    }
  }
  public let seek = PublishSubject<TimeInSeconds>()
  public var state = PublishSubject<PlaybackState>()
  public var availableQualities: Driver<[VideoQuality]> {
    return availableQualitiesRelay.asDriver(onErrorJustReturn: [])
  }

  public var speedUpdated: Driver<Double> {
    return speedRelay.asDriver(onErrorJustReturn: 0.0)
  }

  public var time: Driver<TimeInSeconds> {
    return currentTimeRelay.asDriver(onErrorJustReturn: 0.0)
  }

  public var duration: Driver<TimeInSeconds> {
    return durationRelay.asDriver(onErrorJustReturn: 0.0)
  }

  public var loadedRange: Driver<LoadedTimeRange> {
    return bufferedRelay.map { [0...$0] }.asDriver(onErrorJustReturn: [])
  }

  public var playerState: Driver<PlayerState> {
    return stateRelay.asDriver(onErrorJustReturn: .idle)
  }

  public var seekCompleated: Driver<Void> {
    return seekCompleatedRelay.asDriver(onErrorJustReturn: ())
  }
}
