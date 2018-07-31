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

  let viewModel: ViewModel
  let disposeBag = DisposeBag()

  public override init(frame: CGRect) {
    viewModel = ViewModel(playback: playbackView.viewModel, controls: controlsView.viewModel)
    super.init(frame: frame)

    addSubview(playbackView)
    addSubview(controlsView)
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open override func layoutSubviews() {
    super.layoutSubviews()
    playbackView.frame = bounds
    controlsView.frame = bounds
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
