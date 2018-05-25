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
import SnapKit

open class VideoPlayerView<P: PlaybackViewModable & UIView, C: ControlsViewModable & UIView>: UIView {

  typealias ViewModel = VideoPlayerViewModel<P.ViewModel, C.ViewModel>
  typealias Stream = P.ViewModel.Stream

  public let playbackView = P(frame: CGRect.zero)
  public let controlsView = C(frame: CGRect.zero)

  let viewModel: ViewModel
  let disposeBag = DisposeBag()
  public init() {
    viewModel = ViewModel(playback: playbackView.viewModel, controls: controlsView.viewModel)
    super.init(frame: CGRect.zero)

    addSubview(playbackView)
    addSubview(controlsView)
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open override func updateConstraints() {
    playbackView.snp.remakeConstraints {
      $0.edges.equalToSuperview()
    }
    controlsView.snp.remakeConstraints {
      $0.edges.equalToSuperview()
    }
    super.updateConstraints()
  }

  var stream: Stream? {
    didSet {
      if let stream = stream {
        playbackView.viewModel.stream = stream
        controlsView.viewModel.visibilityChange.accept(Visibility.soft(visible: true))
      } else {
        playbackView.viewModel.stream = nil
      }
    }
  }
}
