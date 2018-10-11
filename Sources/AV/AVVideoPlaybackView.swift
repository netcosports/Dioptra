//
//  AVVideoPlaybackView.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 3/30/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import AVFoundation
import RxSwift
import RxCocoa

open class AVVideoPlaybackView: UIView, PlaybackViewModable {

  public let viewModel = AVVideoPlaybackViewModel()

  public convenience init(_ frame: CGRect, videoGravity: AVLayerVideoGravity = .resizeAspect) {
    self.init(frame: frame)
    playerLayer?.videoGravity = videoGravity
  }

  public override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .black
    playerLayer?.videoGravity = .resizeAspect
    playerLayer?.player = viewModel.player
  }
  
  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open override class var layerClass: AnyClass {
    return AVPlayerLayer.self
  }

  fileprivate var playerLayer: AVPlayerLayer? {
    return layer as? AVPlayerLayer
  }

  override open class var requiresConstraintBasedLayout: Bool {
    return false
  }
}
