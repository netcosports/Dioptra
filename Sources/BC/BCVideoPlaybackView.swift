//
//  BCVideoPlaybackView.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 7/05/18.
//  Copyright © 2018 Netcosports. All rights reserved.
//

import UIKit
import AVFoundation
import BrightcovePlayerSDK
import Dioptra
import RxSwift
import RxCocoa

open class BCVideoPlaybackView: UIView, PlaybackViewModable {

  public let viewModel = BCVideoPlaybackViewModel()

  public override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .black
    // FIXME: need to setup parent view controller
    viewModel.targetView = self
  }

  open override func layoutSubviews() {
    super.layoutSubviews()
    viewModel.playback?.view.frame = bounds
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open class var requiresConstraintBasedLayout: Bool {
    return false
  }
}
