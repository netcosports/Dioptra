//
//  TestPlayback.swift
//  iOSTests
//
//  Created by Sergei Mikhan on 5/30/18.
//  Copyright © 2018 Sergei Mikhan. All rights reserved.
//

import Dioptra
import RxSwift
import RxCocoa

class TestPlayback: VideoPlayback {

  typealias Stream = String
  var input: Input<Stream> = .cleanup
  var muted = true

  let seek = PublishSubject<TimeInSeconds>()
  let state = PublishSubject<PlaybackState>()

  let timeRelay = BehaviorRelay<TimeInSeconds>(value: 0.0)
  let durationRelay = BehaviorRelay<TimeInSeconds>(value: 0.0)
  let loadedRangeRelay = BehaviorRelay<LoadedTimeRange>(value: [])
  let startedSubject = PublishSubject<String>()
  let finishedSubject = PublishSubject<String>()
  let playerStateRelay = BehaviorRelay<PlayerState>(value: PlayerState.idle)
  var seekCompleatedRelay = PublishRelay<Void>()

  var seekCompleated: Driver<Void> {
    return seekCompleatedRelay.asDriver(onErrorJustReturn: ())
  }

  var time: Driver<TimeInSeconds> {
    return timeRelay.asDriver()
  }

  var duration: Driver<TimeInSeconds> {
    return durationRelay.asDriver()
  }

  var progress: Driver<Dioptra.Progress> {
    return Driver.combineLatest(time, duration).map { time, duration -> Dioptra.Progress in
      return Dioptra.Progress(value: time, total: duration)
    }
  }

  var loadedRange: Driver<LoadedTimeRange> {
    return loadedRangeRelay.asDriver()
  }

  var playerState: Driver<PlayerState> {
    return playerStateRelay.asDriver()
  }
}
