//
//  Nimble+Rx.swift
//  iOSTests
//
//  Created by Sergei Mikhan on 4/8/19.
//  Copyright © 2019 Sergei Mikhan. All rights reserved.
//

import RxTest
import RxSwift
import Nimble
import Quick

public extension TestScheduler {

  func performUntil(_ time: TestTime) {
    self.scheduleAt(time) {
      self.stop()
    }
    self.start()
  }
}

public func equal<T: Equatable>(expectedEvents: [Recorded<Event<T>>]) -> Predicate<[Recorded<Event<T>>]> {
  return Predicate { (actualExpression: Expression<[Recorded<Event<T>>]>) throws -> PredicateResult in
    let msg = ExpectationMessage.expectedActualValueTo("equal <\(expectedEvents)>")
    guard let actualEvents = try actualExpression.evaluate() else {
      return PredicateResult(status: .fail, message: msg)
    }
    guard actualEvents.count == expectedEvents.count else {
      return PredicateResult(status: .fail, message: msg)
    }
    let result = zip(actualEvents, expectedEvents).reduce(true, { result, events -> Bool in
      return result &&
        events.0.time == events.1.time &&
        events.0.value == events.1.value
    })
    return PredicateResult(
      bool: result,
      message: msg
    )
  }
}

