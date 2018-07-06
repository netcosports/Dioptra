//
//  TestControls.swift
//  iOSTests
//
//  Created by Sergei Mikhan on 5/30/18.
//  Copyright © 2018 Sergei Mikhan. All rights reserved.
//

import Dioptra
import RxSwift
import RxCocoa

class TestControls: VideoControls {

  let seekRelay = PublishRelay<SeekEvent>()
  let screenModeRelay = PublishRelay<ScreenModeEvent>()
  let playRelay = PublishRelay<PlaybackState>()

  var visibilityChange = BehaviorRelay<VisibilityChangeEvent>(value: VisibilityChangeEvent.soft(visible: true))
  var progress = PublishSubject<Dioptra.Progress>()
  var buffer = PublishSubject<Float>()
  var state = PublishSubject<PlayerState>()

  var seek: Driver<SeekEvent> {
    return seekRelay.asDriver(onErrorJustReturn: SeekEvent.started(progress: 0.0))
  }

  var screenMode: Driver<ScreenModeEvent> {
    return screenModeRelay.asDriver(onErrorJustReturn: ScreenModeEvent.compact)
  }

  var play: Driver<PlaybackState> {
    return playRelay.asDriver(onErrorJustReturn: PlaybackState.playing)
  }
}
