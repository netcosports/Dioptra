//
//  VideoPlayerViewModel.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 5/14/18.
//  Copyright © 2018 Sergei Mikhan. All rights reserved.
//

import RxSwift
import RxCocoa

open class VideoPlayerViewModel<P: VideoPlayback, C: VideoControls> {

  let disposeBag = DisposeBag()
  public let playback: P
  public let controls: C

  public init(playback: P, controls: C) {
    self.playback = playback
    self.controls = controls
    bind()
  }

  func bind() {
    playback.playerState
      .flatMap { state -> Driver<VisibilityChangeEvent> in
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

    playback.loadedRange.withLatestFrom(playback.duration, resultSelector: { range, duration -> Float in
      guard let buffer = range.max(by: { $0.upperBound > $1.upperBound })?.upperBound else {
        return 0.0
      }
      return Float(buffer / duration)
    })
      .drive(controls.buffer)
      .disposed(by: disposeBag)

    controls.seek.withLatestFrom(playback.duration, resultSelector: { seek, duration in
      return TimeInSeconds(seek.progress) * duration
    }).drive(playback.seek)
      .disposed(by: disposeBag)

    controls.seek.withLatestFrom(playback.duration, resultSelector: { seek, duration in
      return TimeInSeconds(seek.progress) * duration
    }).drive(playback.seek)
      .disposed(by: disposeBag)

    controls.play
      .drive(playback.state)
      .disposed(by: disposeBag)

    playback.playerState.asObservable()
      .bind(to: controls.state)
      .disposed(by: disposeBag)

    playback.seekCompleated.drive(controls.seekCompleted).disposed(by: disposeBag)
  }
}
