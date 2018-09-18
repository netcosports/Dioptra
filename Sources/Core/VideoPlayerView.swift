//
//  NSTVideoPlayerView.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 3/30/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

open class VideoPlayerView<P: PlaybackViewModable & UIView, C: ControlsViewModable & UIView>: UIView {

  public typealias ViewModel = VideoPlayerViewModel<P.ViewModel, C.ViewModel>
  public typealias Stream = P.ViewModel.Stream

  public let playbackView = P(frame: CGRect.zero)
  public let controlsView = C(frame: CGRect.zero)
  public let overlayView: UIView = {
    let overlayView = UIView()
    overlayView.isUserInteractionEnabled = false
    return overlayView
  }()

  let viewModel: ViewModel
  let disposeBag = DisposeBag()

  public internal(set) var detached = false
  internal var detachDisposeBag: DisposeBag?
  internal var detachOriginalPoint: CGPoint = .zero

  public override init(frame: CGRect) {
    viewModel = ViewModel(playback: playbackView.viewModel, controls: controlsView.viewModel)
    super.init(frame: frame)

    clipsToBounds = true
    addSubview(playbackView)
    addSubview(controlsView)
    addSubview(overlayView)
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open override func layoutSubviews() {
    super.layoutSubviews()
    playbackView.frame = bounds
    controlsView.frame = bounds
    overlayView.frame = bounds
    // FIXME: need to find correct way to manage subviews layout
    overlayView.subviews.forEach {
      $0.frame = self.bounds
    }
  }

  override open class var requiresConstraintBasedLayout: Bool {
    return false
  }

  open var input: Input<Stream> = .cleanup {
    didSet {
      playbackView.viewModel.input = input
      switch input {
      case .content:
        controlsView.viewModel.visibilityChange.accept(VisibilityChangeEvent.soft(visible: true))
      default: break
      }
    }
  }
}
