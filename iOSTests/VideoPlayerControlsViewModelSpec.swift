//
//  VideoPlayerControlsViewModelSpec.swift
//  iOSTests
//
//  Created by Sergei Mikhan on 18/10/18.
//  Copyright © 2018 Sergei Mikhan. All rights reserved.
//

import Dioptra
import XCTest
import Nimble

import RxBlocking
import RxSwift
import RxCocoa
import RxTest

class VideoPlayerControlsViewModelSpec: XCTestCase {
    
  override func setUp() {
    super.setUp()
  }

  override func tearDown() {
    super.tearDown()
  }

  let disposeBag = DisposeBag()

  func testVisibilityForce() {
    let testObserver = TestScheduler(initialClock: 0).createObserver(Dioptra.Visibility.self)
    let testViewModel = VideoPlayerControlsViewModel()

    testViewModel.visible.drive(testObserver).disposed(by: disposeBag)

    testViewModel.visibilityChange.accept(.force(visible: true))
    testViewModel.visibilityChange.accept(.softToggle)
    testViewModel.visibilityChange.accept(.soft(visible: false))
    testViewModel.visibilityChange.accept(.soft(visible: true))
    testViewModel.visibilityChange.accept(.force(visible: false))

    let expectedEvents: [Recorded<Event<Dioptra.Visibility>>] = [
      next(0, Visibility.soft(visible: true)),
      next(0, Visibility.force(visible: true)),
      next(0, Visibility.force(visible: false))
    ]
    XCTAssertEqual(testObserver.events, expectedEvents)
  }

  func testVisibilityAutohide() {
    let settings = VideoPlayerControlsViewModel.Settings(autoHideTimer: 0.01)
    let testViewModel = VideoPlayerControlsViewModel(settings: settings)
    let actual = try? testViewModel.visible.asObservable().take(2).toBlocking(timeout: 0.1).toArray()
    let expected: [Dioptra.Visibility] = [
      Visibility.soft(visible: true),
      Visibility.soft(visible: false)
    ]
    XCTAssertEqual(actual, expected)
  }

  func testVisibilityAutohideAndToggle() {
    let testObserver = TestScheduler(initialClock: 0).createObserver(Dioptra.Visibility.self)
    let settings = VideoPlayerControlsViewModel.Settings(autoHideTimer: 0.01)
    let testViewModel = VideoPlayerControlsViewModel(settings: settings)
    testViewModel.visible.drive(testObserver).disposed(by: disposeBag)

    let actual = try? testViewModel.visible.asObservable().take(2).toBlocking(timeout: 0.1).toArray()
    testViewModel.visibilityChange.accept(.softToggle)

    let expectedEvents: [Recorded<Event<Dioptra.Visibility>>] = [
      next(0, Visibility.soft(visible: true)),
      next(0, Visibility.soft(visible: false)),
      next(0, Visibility.soft(visible: true)),
    ]
    XCTAssertEqual(testObserver.events, expectedEvents)
  }

  func testVisibilitySoftToggle() {
    let testObserver = TestScheduler(initialClock: 0).createObserver(Dioptra.Visibility.self)
    let settings = VideoPlayerControlsViewModel.Settings(autoHideTimer: 0.01)
    let testViewModel = VideoPlayerControlsViewModel(settings: settings)
    testViewModel.visible.drive(testObserver).disposed(by: disposeBag)

    testViewModel.visibilityChange.accept(.softToggle)

    let expectedEvents: [Recorded<Event<Dioptra.Visibility>>] = [
      next(0, Visibility.soft(visible: true)),
      next(0, Visibility.soft(visible: false))
    ]
    XCTAssertEqual(testObserver.events, expectedEvents)
  }

  func testVisibilitySoftMultiple() {
    let testObserver = TestScheduler(initialClock: 0).createObserver(Dioptra.Visibility.self)
    let settings = VideoPlayerControlsViewModel.Settings(autoHideTimer: 0.01)
    let testViewModel = VideoPlayerControlsViewModel(settings: settings)
    testViewModel.visible.drive(testObserver).disposed(by: disposeBag)

    testViewModel.visibilityChange.accept(.soft(visible: true))
    testViewModel.visibilityChange.accept(.soft(visible: true))
    testViewModel.visibilityChange.accept(.soft(visible: true))

    let expectedEvents: [Recorded<Event<Dioptra.Visibility>>] = [
      next(0, Visibility.soft(visible: true))
    ]
    XCTAssertEqual(testObserver.events, expectedEvents)
  }

  func testVisibilityAcceptSoft() {
    let testObserver = TestScheduler(initialClock: 0).createObserver(Dioptra.Visibility.self)
    let settings = VideoPlayerControlsViewModel.Settings(autoHideTimer: 0.01)
    let testViewModel = VideoPlayerControlsViewModel(settings: settings)
    testViewModel.visible.drive(testObserver).disposed(by: disposeBag)

    testViewModel.visibilityChange.accept(VisibilityChangeEvent.force(visible: false))
    testViewModel.visibilityChange.accept(VisibilityChangeEvent.soft(visible: true))
    testViewModel.visibilityChange.accept(VisibilityChangeEvent.acceptSoft)
    testViewModel.visibilityChange.accept(VisibilityChangeEvent.soft(visible: true))
    testViewModel.visibilityChange.accept(VisibilityChangeEvent.softToggle)

    let expectedEvents: [Recorded<Event<Dioptra.Visibility>>] = [
      next(0, Visibility.soft(visible: true)),
      next(0, Visibility.force(visible: false)),
      next(0, Visibility.force(visible: true)),
      next(0, Visibility.soft(visible: true)),
      next(0, Visibility.soft(visible: false)),
    ]
    XCTAssertEqual(testObserver.events, expectedEvents)
  }
}
