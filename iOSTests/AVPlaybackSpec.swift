//
//  AVPlaybackSpec.swift
//  iOSTests
//
//  Created by Sergei Mikhan on 5/30/18.
//  Copyright © 2018 Sergei Mikhan. All rights reserved.
//

import Dioptra
import XCTest
import Nimble

import RxBlocking
import RxSwift
import RxCocoa
import RxTest

class AVPlaybackSpec: XCTestCase {

  let disposeBag = DisposeBag()
  typealias ViewModel = VideoPlayerViewModel<AVVideoPlaybackViewModel, TestControls>

  func testPlay() {
    let testScheduler = TestScheduler(initialClock: 0)
    let testObserver = testScheduler.createObserver(Dioptra.Progress.self)

    let testViewModel = ViewModel(playback: TestPlayback(), controls: VideoPlayerControlsViewModel())

    testViewModel.controls.progress.bind(to: testObserver).disposed(by: disposeBag)

    playback.durationRelay.accept(1.0)
    playback.timeRelay.accept(0.5)
    playback.timeRelay.accept(1.0)

    let expectedEvents: [Recorded<Event<Dioptra.Progress>>] = [
      next(0, Progress(value: 0.0, total: 1.0)),
      next(0, Progress(value: 0.5, total: 1.0)),
      next(0, Progress(value: 1.0, total: 1.0))
    ]
    XCTAssertEqual(testObserver.events, expectedEvents)
  }
}
