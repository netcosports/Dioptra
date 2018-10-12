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

public enum SeekEvent {
  case started(progress: Float)
  case value(progress: Float)
  case finished(progress: Float)

  public var progress: Float {
    switch self {
    case .started(let progress), .finished(let progress), .value(let progress):
      return progress
    }
  }
}

public enum Visibility {
  case force(visible: Bool)
  case soft(visible: Bool)

  public var visible: Bool {
    switch self {
    case .force(let visible), .soft(let visible):
      return visible
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
