//
//  VideoPlayerViewModelSpec.swift
//  iOSTests
//
//  Created by Sergei Mikhan on 5/12/18.
//  Copyright © 2018 Sergei Mikhan. All rights reserved.
//

import Dioptra
import XCTest
import Nimble

import RxBlocking
import RxSwift
import RxCocoa
import RxTest

class VideoPlayerViewModelSpec: XCTestCase {
    
  override func setUp() {
    super.setUp()
  }

  override func tearDown() {
    super.tearDown()
  }

  let disposeBag = DisposeBag()
  typealias ViewModel = VideoPlayerViewModel<TestPlayback, VideoPlayerControlsViewModel>

  func testProgress() {
    let testObserver = TestScheduler(initialClock: 0).createObserver(Dioptra.Progress.self)
    let testViewModel = ViewModel(playback: TestPlayback(),
                                  controls: VideoPlayerControlsViewModel())

    testViewModel.controls.progress.bind(to: testObserver).disposed(by: disposeBag)

    testViewModel.playback.durationRelay.accept(1.0)
    testViewModel.playback.timeRelay.accept(0.5)
    testViewModel.playback.timeRelay.accept(1.0)

    let expectedEvents: [Recorded<Event<Dioptra.Progress>>] = [
      next(0, Progress(value: 0.0, total: 1.0)),
      next(0, Progress(value: 0.5, total: 1.0)),
      next(0, Progress(value: 1.0, total: 1.0))
    ]
    XCTAssertEqual(testObserver.events, expectedEvents)
  }
}
