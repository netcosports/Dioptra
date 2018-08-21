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

  open fileprivate(set) var detached = false

  open func detach(to view: UIView, with frame: CGRect) {
    guard detached == false else { return }
    guard let detachedOriginalContainer = view.superview else { return }
    self.detached = true
    let originalFrame = self.convert(self.bounds, to: view)
    view.addSubview(self)
    self.frame = originalFrame
    self.layoutSubviews()

    UIView.animate(withDuration: 0.27, animations: {
      self.frame = frame
      self.controlsView.viewModel.screenMode.accept(ScreenMode.minimized)
      self.layoutSubviews()
    })
  }

  open func attach(to view: UIView, with frame: CGRect, overView: UIView) {
    guard detached == true else { return }
    let targetFrame = view.convert(frame, to: overView)
    let originalFrame = self.convert(self.bounds, to: overView)
    overView.addSubview(self)
    self.frame = originalFrame
    self.layoutSubviews()

    UIView.animate(withDuration: 0.27, animations: {
      self.frame = targetFrame
      self.controlsView.viewModel.screenMode.accept(ScreenMode.compact)
      self.layoutSubviews()
    }, completion: { finished in
      view.addSubview(self)
      self.frame = frame
      self.layoutSubviews()
      self.detached = false
    })
  }
}
