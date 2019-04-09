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
import Quick

import RxSwift
import RxCocoa
import RxTest

class VideoPlayerControlsViewModelSpecQuick: QuickSpec {

  var scheduler: TestScheduler!
  var disposeBag: DisposeBag!
  var controlsViewModel: VideoPlayerControlsViewModel!

  override func spec() {

    describe("'Visibility'") {

      beforeEach {

      }

      context("changes") {
        beforeEach {
          let settings = VideoPlayerControlsViewModel.Settings(autoHideTimer: 5.0)
          self.scheduler = TestScheduler(initialClock: 0)
          self.disposeBag = DisposeBag()
          self.controlsViewModel = VideoPlayerControlsViewModel(settings: settings, scheduler: self.scheduler)
        }

        it("between force update events") {
          self.scheduler.createColdObservable([
            .next(1, VisibilityChangeEvent.force(visible: true)),
            .next(20, VisibilityChangeEvent.softToggle),
            .next(30, VisibilityChangeEvent.soft(visible: false)),
            .next(40, VisibilityChangeEvent.soft(visible: true)),
            .next(50, VisibilityChangeEvent.force(visible: false))
          ]).bind(to: self.controlsViewModel.visibilityChange).disposed(by: self.disposeBag)

          let visibilities = self.scheduler.createObserver(Dioptra.Visibility.self)
          self.controlsViewModel.visible.drive(visibilities).disposed(by: self.disposeBag)
          self.scheduler.performUntil(60)

          expect(visibilities.events).to(equal(expectedEvents: [
            .next(0, Visibility.soft(visible: true)),
            .next(1, Visibility.force(visible: true)),
            .next(50, Visibility.force(visible: false))
          ]))
        }

        it("automatically after timeout") {
          let visibilities = self.scheduler.createObserver(Dioptra.Visibility.self)
          self.controlsViewModel.visible.drive(visibilities).disposed(by: self.disposeBag)
          self.scheduler.performUntil(60)

          expect(visibilities.events).to(equal(expectedEvents: [
            .next(0, Visibility.soft(visible: true)),
            .next(5, Visibility.soft(visible: false))
          ]))
        }

        it("automatically after timeout then toggle") {
          self.scheduler.createColdObservable([
            .next(10, VisibilityChangeEvent.softToggle)
          ]).bind(to: self.controlsViewModel.visibilityChange).disposed(by: self.disposeBag)

          let visibilities = self.scheduler.createObserver(Dioptra.Visibility.self)
          self.controlsViewModel.visible.drive(visibilities).disposed(by: self.disposeBag)
          self.scheduler.performUntil(11)

          expect(visibilities.events).to(equal(expectedEvents: [
            .next(0, Visibility.soft(visible: true)),
            .next(5, Visibility.soft(visible: false)),
            .next(10, Visibility.soft(visible: true))
          ]))
        }

        it("automatically after timeout then toggle and hide again automatically") {
          self.scheduler.createColdObservable([
            .next(10, VisibilityChangeEvent.softToggle)
            ]).bind(to: self.controlsViewModel.visibilityChange).disposed(by: self.disposeBag)

          let visibilities = self.scheduler.createObserver(Dioptra.Visibility.self)
          self.controlsViewModel.visible.drive(visibilities).disposed(by: self.disposeBag)
          self.scheduler.performUntil(11)

          expect(visibilities.events).to(equal(expectedEvents: [
            .next(0, Visibility.soft(visible: true)),
            .next(5, Visibility.soft(visible: false)),
            .next(10, Visibility.soft(visible: true))
          ]))
        }

        it("after force update event") {
          self.scheduler.createColdObservable([
            .next(2, VisibilityChangeEvent.soft(visible: true)),
            .next(10, VisibilityChangeEvent.force(visible: true))
          ]).bind(to: self.controlsViewModel.visibilityChange).disposed(by: self.disposeBag)

          let visibilities = self.scheduler.createObserver(Dioptra.Visibility.self)
          self.controlsViewModel.visible.drive(visibilities).disposed(by: self.disposeBag)
          self.scheduler.performUntil(60)

          expect(visibilities.events).to(equal(expectedEvents: [
            .next(0, Visibility.soft(visible: true)),
            .next(7, Visibility.soft(visible: false)),
            .next(10, Visibility.force(visible: true))
          ]))
        }

        it("after toogle event") {
          self.scheduler.createColdObservable([
            .next(2, VisibilityChangeEvent.softToggle),
            .next(4, VisibilityChangeEvent.softToggle)
          ]).bind(to: self.controlsViewModel.visibilityChange).disposed(by: self.disposeBag)

          let visibilities = self.scheduler.createObserver(Dioptra.Visibility.self)
          self.controlsViewModel.visible.drive(visibilities).disposed(by: self.disposeBag)
          self.scheduler.performUntil(60)

          expect(visibilities.events).to(equal(expectedEvents: [
            .next(0, Visibility.soft(visible: true)),
            .next(2, Visibility.soft(visible: false)),
            .next(4, Visibility.soft(visible: true)),
            .next(9, Visibility.soft(visible: false)),
          ]))
        }

        it("after multiple soft events") {
          self.scheduler.createColdObservable([
            .next(4, VisibilityChangeEvent.soft(visible: true)),
            .next(8, VisibilityChangeEvent.soft(visible: true)),
            .next(12, VisibilityChangeEvent.soft(visible: true)),
            .next(15, VisibilityChangeEvent.soft(visible: true))
          ]).bind(to: self.controlsViewModel.visibilityChange).disposed(by: self.disposeBag)

          let visibilities = self.scheduler.createObserver(Dioptra.Visibility.self)
          self.controlsViewModel.visible.drive(visibilities).disposed(by: self.disposeBag)
          self.scheduler.performUntil(60)

          expect(visibilities.events).to(equal(expectedEvents: [
            .next(0, Visibility.soft(visible: true)),
            .next(20, Visibility.soft(visible: false))
          ]))
        }

        it("after accept soft events between the autohiding timer") {
          self.scheduler.createColdObservable([
            .next(4, VisibilityChangeEvent.force(visible: false)),
            .next(8, VisibilityChangeEvent.soft(visible: true)),
            .next(12, VisibilityChangeEvent.acceptSoft),
            .next(15, VisibilityChangeEvent.soft(visible: true)),
            .next(19, VisibilityChangeEvent.softToggle)
          ]).bind(to: self.controlsViewModel.visibilityChange).disposed(by: self.disposeBag)

          let visibilities = self.scheduler.createObserver(Dioptra.Visibility.self)
          self.controlsViewModel.visible.drive(visibilities).disposed(by: self.disposeBag)
          self.scheduler.performUntil(60)

          expect(visibilities.events).to(equal(expectedEvents: [
            .next(0, Visibility.soft(visible: true)),
            .next(4, Visibility.force(visible: false)),
            .next(15, Visibility.soft(visible: true)),
            .next(19, Visibility.soft(visible: false))
          ]))
        }

        it("after accept soft events") {
          self.scheduler.createColdObservable([
            .next(4, VisibilityChangeEvent.force(visible: false)),
            .next(8, VisibilityChangeEvent.soft(visible: true)),
            .next(15, VisibilityChangeEvent.acceptSoft),
            .next(20, VisibilityChangeEvent.soft(visible: true)),
            .next(24, VisibilityChangeEvent.softToggle)
          ]).bind(to: self.controlsViewModel.visibilityChange).disposed(by: self.disposeBag)

          let visibilities = self.scheduler.createObserver(Dioptra.Visibility.self)
          self.controlsViewModel.visible.drive(visibilities).disposed(by: self.disposeBag)
          self.scheduler.performUntil(60)

          expect(visibilities.events).to(equal(expectedEvents: [
            .next(0, Visibility.soft(visible: true)),
            .next(4, Visibility.force(visible: false)),
            .next(20, Visibility.soft(visible: true)),
            .next(24, Visibility.soft(visible: false))
          ]))
        }
      }
    }
  }
}
