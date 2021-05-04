//
//  VideoControls.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 4/3/18.
//  Copyright © 2018 Sergei Mikhan. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa


public enum ScreenMode {
  case fullscreen
  case compact
  case minimized
}

public enum SeekEvent: Equatable {
  case started(progress: Double)
  case value(progress: Double)
  case finished(progress: Double)

  public var progress: Double {
    switch self {
    case .started(let progress), .finished(let progress), .value(let progress):
      return progress
    }
  }

  public static func == (lhs: SeekEvent, rhs: SeekEvent) -> Bool {
    switch (lhs, rhs) {
    case (.started(let lprogress), .started(let rprogress)):
      return lprogress == rprogress
    case (.value(let lprogress), .value(let rprogress)):
      return lprogress == rprogress
    case (.finished(let lprogress), .finished(let rprogress)):
      return lprogress == rprogress
    default: return false
    }
  }
}

public enum Visibility: Equatable {
  case force(visible: Bool)
  case soft(visible: Bool)

  public var visible: Bool {
    switch self {
    case .force(let visible), .soft(let visible):
      return visible
    }
  }

  public static func == (lhs: Visibility, rhs: Visibility) -> Bool {
    switch (lhs, rhs) {
    case (.force(let lVisible), .force(let rVisible)):
      return lVisible == rVisible
    case (.soft(let lVisible), .soft(let rVisible)):
      return lVisible == rVisible
    default: return false
    }
  }
}

public enum VisibilityChangeEvent {
  case force(visible: Bool)
  case soft(visible: Bool)
  case acceptSoft
  case softToggle
}

public protocol VideoControls: class {

  // RX inputs/outputs
  var visibilityChange: BehaviorRelay<VisibilityChangeEvent> { get }
  var screenMode: BehaviorRelay<ScreenMode> { get }

  // RX inputs
  var seekCompleted: PublishSubject<Void> { get }
  var buffer: PublishSubject<Float> { get }
  var progress: PublishSubject<Progress> { get }
  var state: PublishSubject<PlayerState> { get }
  // FIXME: is it input?
  var fullscreen: PublishSubject<Void> { get }

  // RX outputs
  var seek: Driver<SeekEvent> { get }
  var play: Driver<PlaybackState> { get }
}

public protocol ControlsViewModable {
  associatedtype ViewModel: VideoControls
  var viewModel: ViewModel { get }
}
