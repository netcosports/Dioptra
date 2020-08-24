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

public struct Progress: Equatable {
  public let value: TimeInSeconds
  public let total: TimeInSeconds

  public init(value: TimeInSeconds, total: TimeInSeconds) {
    self.value = value
    self.total = total
  }

  static func empty() -> Progress {
    return Progress(value: 0.0, total: 0.0)
  }

  public static func == (lhs: Progress, rhs: Progress) -> Bool {
    return lhs.total == rhs.total && lhs.value == rhs.value
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

// NOTE: input enum is necessary for advertisement engines
// which uses same stream type with content stream
// current idea is to support 3 types of AD
// - Embeded AD in playback(DM and youtube for example)
// - Internal playback AD (setup different inputs)
// - Overlay playback AD
public enum Input<T> where T: Equatable {
  case ad(stream: T)
  case content(stream: T)
  case contentWithStartTime(stream: T, startTime: TimeInterval)
  case cleanup
}
extension Input: Equatable {

  public static func == (lhs: Input<T>, rhs: Input<T>) -> Bool {
    switch (lhs, rhs) {
    case (.ad(let lhsStream), .ad(let rhsStream)):
      return lhsStream == rhsStream
    case (.content(let lhsStream), .content(let rhsStream)):
      return lhsStream == rhsStream
    case (.contentWithStartTime(let lhsStream, let lTime), .contentWithStartTime(let rhsStream, let rTime)):
      return lhsStream == rhsStream && lTime == rTime
    case (.cleanup, .cleanup):
      return true
    default: return false
    }
  }
}

public enum DioptraError {
	case connection(error: Error?)
	case playback(error: Error?)
}

public enum PlayerState: Equatable {

  case ready
  case active(state: PlaybackState)
  case ad(state: AdState)
  case idle
  case loading
  case stuck
  case error(error: DioptraError)
  case finished

  public static func == (lhs: PlayerState, rhs: PlayerState) -> Bool {
    switch (lhs, rhs) {
      case (.ready, .ready): return true
      case (.active(let lhsState), .active(let rhsState)): return lhsState == rhsState
      case (.ad(let lhsState), .ad(let rhsState)): return lhsState == rhsState
      case (.idle, .idle): return true
      case (.loading, .loading): return true
      case (.stuck, .stuck): return true
      case (.error, .error): return true
      case (.finished, .finished): return true
    default: return false
    }
  }
}

public enum VideoQuality: Equatable {
  case auto
  case stream(bandwidth: Double, resolution: CGSize, url: String, description: String)

  public var preferredPeakBitRate: Double {
    switch self {
    case .auto:
      return 0.0
    case .stream(let bandwidth, _, _, _):
      return bandwidth + 1.0
    }
  }

  public func closest(in list: [VideoQuality]) -> VideoQuality {
    switch self {
    case .auto: return .auto
    case .stream(let bandwidth, _, _, _):
      if let quality = list.first(where: { abs($0.preferredPeakBitRate - bandwidth) < 100.0 }) {
        return quality
      }
    }
    return .auto
  }
}

public protocol VideoPlayback: class {

  // input:
  associatedtype Stream: Equatable
  var input: Input<Stream> { get set }

  // params:
  var muted: Bool { get set }
  var volume: Float { get set }
  var quality: VideoQuality { get set }
  var speed: Double { set get }

  // RX input:
  var seek: PublishSubject<TimeInSeconds> { get }
  var state: PublishSubject<PlaybackState> { get }

  // RX output:
  var time: Driver<TimeInSeconds> { get }
  var duration: Driver<TimeInSeconds> { get }
  var loadedRange: Driver<LoadedTimeRange> { get }
  var playerState: Driver<PlayerState> { get }
  var seekCompleated: Driver<Void> { get }
  var speedUpdated: Driver<Double> { get }
  var availableQualities: Driver<[VideoQuality]> { get }
}

extension VideoPlayback {

  public var progress: Driver<Progress> {
    return Driver.combineLatest(time, duration).map { Progress(value: $0, total:$1) }
  }
}

public enum AdPluginEvent<T> {
  case resumeContent
  case pauseContent

  case start(ad: T)
  case stopAd
}

public protocol AdPlugin: class {
  associatedtype Stream

  func startSession(with stream: Stream)
  func stopSession()

  var eventQueue: PublishSubject<AdPluginEvent<Stream>> { get }
}

public protocol PlaybackViewModable {
  associatedtype ViewModel: VideoPlayback
  var viewModel: ViewModel { get }
}
