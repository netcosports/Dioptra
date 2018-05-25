//
//  VideoPlayback.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 5/4/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

public typealias TimeInSeconds         = Double
public typealias TimeInSecondsRange    = ClosedRange<TimeInSeconds>
public typealias LoadedTimeRange       = [TimeInSecondsRange]

public struct Progress {
  let value: TimeInSeconds
  let total: TimeInSeconds

  static func empty() -> Progress {
    return Progress(value: 0.0, total: 0.0)
  }
}

public enum PlaybackState {
  case playing
  case paused
}

public enum AdState {
  case idle
  case started
  case finished
  case skiped
  case error
}

public enum PlayerState: Equatable {
  case active(state: PlaybackState)
  case ad(state: AdState)
  case idle
  case loading
  case stuck
  case error(error: Error?)

  public static func == (lhs: PlayerState, rhs: PlayerState) -> Bool {
    switch (lhs, rhs) {
      case (.active(let lhsState), .active(let rhsState)): return lhsState == rhsState
      case (.ad(let lhsState), .ad(let rhsState)): return lhsState == rhsState
      case (.idle, .idle): return true
      case (.loading, .loading): return true
      case (.stuck, .stuck): return true
      case (.error, .error): return true
    default: return false
    }
  }
}

public protocol VideoPlayback: class {

  // params:
  associatedtype Stream: Equatable
  var stream: Stream? { get set }
  var muted: Bool { get set }

  // RX input:
  var seek: PublishSubject<TimeInSeconds> { get }
  var state: PublishSubject<PlaybackState> { get }

  // RX output:
  var time: Driver<TimeInSeconds> { get }
  var duration: Driver<TimeInSeconds> { get }
  var progress: Driver<Progress> { get }
  var loadedRange: Driver<LoadedTimeRange> { get }
  var started: Driver<Stream> { get }
  var finished: Driver<Stream> { get }
  var playerState: Driver<PlayerState> { get }
}

public protocol PlaybackViewModable {
  associatedtype ViewModel: VideoPlayback
  var viewModel: ViewModel { get }
}
