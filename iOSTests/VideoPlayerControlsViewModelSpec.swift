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

  func testForce() {
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

  func testAutohide() {
    let settings = VideoPlayerControlsViewModel.Settings(autoHideTimer: 0.01)
    let testViewModel = VideoPlayerControlsViewModel(settings: settings)
    let actual = try? testViewModel.visible.asObservable().take(2)
      .toBlocking(timeout: 0.1).toArray()
    let expected: [Dioptra.Visibility] = [
      Visibility.soft(visible: true),
      Visibility.soft(visible: false)
    ]
    XCTAssertEqual(actual, expected)
  }

  func testAutohideAndToggle() {
    let testObserver = TestScheduler(initialClock: 0).createObserver(Dioptra.Visibility.self)
    let settings = VideoPlayerControlsViewModel.Settings(autoHideTimer: 0.01)
    let testViewModel = VideoPlayerControlsViewModel(settings: settings)
    testViewModel.visible.drive(testObserver).disposed(by: disposeBag)

    let _ = try? testViewModel.visible.asObservable().skip(1).take(1).toBlocking(timeout: 0.1).toArray()
    testViewModel.visibilityChange.accept(.softToggle)

    let expectedEvents: [Recorded<Event<Dioptra.Visibility>>] = [
      next(0, Visibility.soft(visible: true)),
      next(0, Visibility.soft(visible: false)),
      next(0, Visibility.soft(visible: true)),
    ]
    XCTAssertEqual(testObserver.events, expectedEvents)
  }

  func testAutohideToggleAutohide() {
    let testObserver = TestScheduler(initialClock: 0).createObserver(Dioptra.Visibility.self)
    let settings = VideoPlayerControlsViewModel.Settings(autoHideTimer: 0.01)
    let testViewModel = VideoPlayerControlsViewModel(settings: settings)
    testViewModel.visible.drive(testObserver).disposed(by: disposeBag)

    let _ = try? testViewModel.visible.asObservable().skip(1).take(1).toBlocking(timeout: 0.1).toArray()
    testViewModel.visibilityChange.accept(.softToggle)
    let _ = try? testViewModel.visible.asObservable().skip(1).take(1).toBlocking(timeout: 0.1).toArray()

    let expectedEvents: [Recorded<Event<Dioptra.Visibility>>] = [
      next(0, Visibility.soft(visible: true)),
      next(0, Visibility.soft(visible: false)),
      next(0, Visibility.soft(visible: true)),
      next(0, Visibility.soft(visible: false))
      ]
    XCTAssertEqual(testObserver.events, expectedEvents)
  }

  func testSoftForceVisible() {
    let testObserver = TestScheduler(initialClock: 0).createObserver(Dioptra.Visibility.self)
    let settings = VideoPlayerControlsViewModel.Settings(autoHideTimer: 0.01)
    let testViewModel = VideoPlayerControlsViewModel(settings: settings)
    testViewModel.visible.drive(testObserver).disposed(by: disposeBag)

    testViewModel.visibilityChange.accept(.soft(visible: true))
    testViewModel.visibilityChange.accept(.force(visible: true))
    let _ = try? testViewModel.visible.asObservable().skip(1).take(1).toBlocking(timeout: 0.1).toArray()

    let expectedEvents: [Recorded<Event<Dioptra.Visibility>>] = [
      next(0, Visibility.soft(visible: true)),
      next(0, Visibility.force(visible: true))
    ]
    XCTAssertEqual(testObserver.events, expectedEvents)
  }

  func testSoftToggle() {
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

  func testSoftMultiple() {
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

  func testAcceptSoft() {
    let testObserver = TestScheduler(initialClock: 0).createObserver(Dioptra.Visibility.self)
    let settings = VideoPlayerControlsViewModel.Settings(autoHideTimer: 0.01)
    let testViewModel = VideoPlayerControlsViewModel(settings: settings)
    testViewModel.visible.drive(testObserver).disposed(by: disposeBag)

    testViewModel.visibilityChange.accept(.force(visible: false))
    testViewModel.visibilityChange.accept(.soft(visible: true))
    testViewModel.visibilityChange.accept(.acceptSoft)
    testViewModel.visibilityChange.accept(.soft(visible: true))
    testViewModel.visibilityChange.accept(.softToggle)

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
