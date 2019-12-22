//
//  BCVideoPlaybackView.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 7/05/18.
//  Copyright © 2018 Netcosports. All rights reserved.
//

import UIKit
import Dioptra
import AVFoundation
import BrightcovePlayerSDK
import RxSwift
import RxCocoa

open class BCVideoPlaybackWithControlsView: UIView, PlaybackViewModable, Detachable {

  public let viewModel = BCVideoPlaybackWithControlsViewModel()

  public var detached = false
  public var detachOriginalPoint = CGPoint.zero
  public var detachDisposeBag: DisposeBag?

  public lazy var playerView: BCOVPUIPlayerView? = {
    let options = BCOVPUIPlayerViewOptions()
    guard let _playerView = BCOVPUIPlayerView(playbackController: nil, options: options, controlsView: self.controls) else {
      return nil
    }
    _playerView.playbackController = viewModel.playback
    self.addSubview(_playerView)
    return _playerView
  }()

  public override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .black
  }

  open override func layoutSubviews() {
    super.layoutSubviews()
    viewModel.playback?.view.frame = bounds
    playerView?.frame = bounds
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open class var requiresConstraintBasedLayout: Bool {
    return false
  }

  open var controls: BCOVPUIBasicControlView {
    return BCOVPUIBasicControlView.withVODLayout()
  }

  open func minimize() {

  }

  open func compact() {

  }
}
