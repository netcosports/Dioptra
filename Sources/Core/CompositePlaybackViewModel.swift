//
//  CompositePlaybackViewModel.swift
//  Pods
//
//  Created by Sergei Mikhan on 12.04.21.
//

import Foundation

import RxSwift
import RxCocoa

final public class CompositePlaybackViewModel<T1: VideoPlayback,
                                     T2: VideoPlayback>: VideoPlayback
where T1.Stream == T2.Stream {

  public typealias Stream = T1.Stream

  private let firstPlayback: T1
  private let secondPlayback: T2

  private let seekIntermediateSubject = PublishSubject<TimeInSeconds>()
  private let stateIntermediateSubject = PublishSubject<PlaybackState>()

  private var lastProgressTime: Double?

  public var firstActive = true {
    didSet {
      guard let lastProgressTime = lastProgressTime else {
        return
      }
      let stream: Stream
      switch self.input {
      case .content(let current), .contentWithStartTime(let current, _):
        stream = current
      default:
        return
      }
      if firstActive {
        self.firstPlayback.input = .contentWithStartTime(stream: stream, startTime: lastProgressTime)
      } else {
        self.secondPlayback.input = .contentWithStartTime(stream: stream, startTime: lastProgressTime)
      }
    }
  }

  private let disposeBag = DisposeBag()

  public init(firstPlayback: T1, secondPlayback: T2) {
    self.firstPlayback = firstPlayback
    self.secondPlayback = secondPlayback

    stateIntermediateSubject.filter { [weak self] _ in self?.firstActive ?? false }
      .bind(to: firstPlayback.state).disposed(by: disposeBag)
    stateIntermediateSubject.filter { [weak self] _ in !(self?.firstActive ?? false) }
      .bind(to: secondPlayback.state).disposed(by: disposeBag)

    seekIntermediateSubject.filter { [weak self] _ in self?.firstActive ?? false }
      .bind(to: firstPlayback.seek, secondPlayback.seek).disposed(by: disposeBag)
    seekIntermediateSubject.filter { [weak self] _ in !(self?.firstActive ?? false) }
      .bind(to: firstPlayback.seek, secondPlayback.seek).disposed(by: disposeBag)
  }

  public var input: Input<Stream> = .cleanup {
    didSet {
      firstPlayback.input = input
      secondPlayback.input = input
    }
  }

  public var muted: Bool = false {
    didSet {
      firstPlayback.muted = muted
      secondPlayback.muted = muted
    }
  }

  public var volume: Float = 0.0 {
    didSet {
      firstPlayback.volume = volume
      secondPlayback.volume = volume
    }
  }

  public var quality: VideoQuality = .auto {
    didSet {
      firstPlayback.quality = quality
      secondPlayback.quality = quality
    }
  }

  public var speed: Double = 1.0 {
    didSet {
      firstPlayback.speed = speed
      secondPlayback.speed = speed
    }
  }

  public var seek: PublishSubject<TimeInSeconds> {
    seekIntermediateSubject
  }

  public var state: PublishSubject<PlaybackState> {
    stateIntermediateSubject
  }

  public var time: Driver<TimeInSeconds> {
    return Driver<TimeInSeconds>.merge(
      firstPlayback.time,
      secondPlayback.time
    ).do(onNext: { [weak self] time in
      self?.lastProgressTime = time
    })
  }

  public var duration: Driver<TimeInSeconds> {
    .merge(
      firstPlayback.duration,
      secondPlayback.duration
    )
  }

  public var loadedRange: Driver<LoadedTimeRange> {
    .merge(
      firstPlayback.loadedRange,
      secondPlayback.loadedRange
    )
  }

  public var playerState: Driver<PlayerState> {
    .merge(
      firstPlayback.playerState,
      secondPlayback.playerState
    )
  }

  public var seekCompleated: Driver<Void> {
    .merge(
      firstPlayback.seekCompleated,
      secondPlayback.seekCompleated
    )
  }

  public var speedUpdated: Driver<Double> {
    .merge(
      firstPlayback.speedUpdated,
      secondPlayback.speedUpdated
    )
  }

  public var availableQualities: Driver<[VideoQuality]> {
    .merge(
      firstPlayback.availableQualities,
      secondPlayback.availableQualities
    )
  }
}
