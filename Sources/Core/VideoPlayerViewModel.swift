//
//  VideoPlayerViewModel.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 5/14/18.
//  Copyright © 2018 Sergei Mikhan. All rights reserved.
//

import RxSwift
import RxCocoa

class VideoPlayerViewModel<P: VideoPlayback, C: VideoControls> {

  let disposeBag = DisposeBag()
  let playback: P
  let controls: C

  init(playback: P, controls: C) {
    self.playback = playback
    self.controls = controls
    bind()
  }

  func bind() {
    playback.playerState
      .flatMap { state -> Driver<Visibility> in
        switch state {
        case .ad(let adState):
          switch adState {
            case .started: return .just(.force(visible: false))
            case .finished: return .just(.acceptSoft)
            default: return .empty()
          }
        default: return .empty()
        }
      }
      .drive(controls.visibilityChange)
      .disposed(by: disposeBag)

    playback.progress
      .drive(controls.progress)
      .disposed(by: disposeBag)

    Driver.combineLatest(playback.loadedRange, playback.duration)
      .map { range, duration -> Float in
        guard let buffer = range.max(by: { $0.upperBound > $1.upperBound })?.upperBound else { return 0.0 }
        return Float(buffer / duration)
      }.drive(controls.buffer)
      .disposed(by: disposeBag)

    Driver.combineLatest(controls.seek, playback.duration)
      .map { seekAndDuration -> TimeInSeconds in
        return TimeInSeconds(seekAndDuration.0.progress) * seekAndDuration.1
      }.drive(playback.seek)
      .disposed(by: disposeBag)

    controls.play
      .drive(playback.state)
      .disposed(by: disposeBag)

    playback.playerState.asObservable()
      .bind(to: controls.state)
      .disposed(by: disposeBag)
  }
}
