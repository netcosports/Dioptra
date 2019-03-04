//
//  ConstraintsVideoCell.swift
//  Demo
//
//  Created by Eugen Filipkov on 10/15/18.
//  Copyright © 2018 Sergei Mikhan. All rights reserved.
//

import Astrolabe
import Dioptra
import RxSwift
import SnapKit

class ConstraintsVideoCell: CollectionViewCell, Reusable {
  
  let disposeBag = DisposeBag()
  
  weak var landscapeViewController: UIViewController?
  weak var fullscreenViewController: UIViewController?
  
//  typealias Player = VideoPlayerView<YTVideoPlaybackView, VideoPlayerControlsView>
  //typealias Player = VideoPlayerView<DMVideoPlaybackView, VideoPlayerControlsView>
  //typealias Player = VideoPlayerView<BCVideoPlaybackView, VideoPlayerControlsView>
  typealias Player = VideoPlayerView<AVVideoPlaybackView, VideoPlayerControlsView>
  
  let player = Player(frame: .zero)

  override func setup() {
    super.setup()
    
    contentView.addSubview(player)
    
    player.playbackView.viewModel.input = .content(stream: "x6k8h19")
    
    player.playbackView.viewModel.muted = true
    player.controlsView.fullscreenButton.setTitle("Full", for: .normal)
    player.controlsView.errorLabel.text = "Error"
    player.controlsView.viewModel.fullscreen.subscribe(onNext: { [weak self] in
      self?.handleFullscreen()
    }).disposed(by: disposeBag)
    
    NotificationCenter.default.rx.notification(UIDevice.orientationDidChangeNotification, object: nil)
      .map { _ in return UIDevice.current.orientation }
      .distinctUntilChanged()
      .filter { [weak self] _ in self?.fullscreenViewController == nil }
      .filter { $0.isLandscape || $0.isPortrait }
      .filter({ [weak self] _ -> Bool in
        guard let detailsViewController = self?.landscapeViewController else { return true }
        return !(detailsViewController.isBeingPresented || detailsViewController.isBeingDismissed)
      }).subscribe(onNext: { [weak self] orientation in
        if self?.landscapeViewController != nil && orientation.isPortrait {
          self?.landscapeViewController?.dismiss(animated: true)
        } else if orientation.isLandscape && self?.landscapeViewController == nil {
          self?.toLandscape()
        }
      }).disposed(by: disposeBag)
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    if self.player.superview == contentView {
      self.player.frame = contentView.bounds
    }
  }
  
  typealias TransitionableViewController = UIViewController & Transitionable
  
  fileprivate func toLandscape() {
    guard let container = containerViewController as? TransitionableViewController else {
      return
    }
    let detailsViewController = LandscapeViewController()
    self.landscapeViewController = detailsViewController
    container.present(modal: detailsViewController,
                      method: TransitionMethod.landscape(presentingView: self.player))
  }
  
  fileprivate func handleFullscreen() {
    guard let container = containerViewController as? TransitionableViewController else {
      return
    }
    if let fullscreenViewController = fullscreenViewController {
      fullscreenViewController.dismiss(animated: true)
    } else if let landscapeViewController = landscapeViewController {
      landscapeViewController.dismiss(animated: true)
    } else {
      let detailsViewController = FullscreenViewController()
      self.fullscreenViewController = detailsViewController
      container.present(modal: detailsViewController,
                        method: TransitionMethod.fullscreen(presentingView: self.player))
    }
  }
  
  typealias Data = Void
  static func size(for data: Data, containerSize: CGSize) -> CGSize {
    return CGSize(width: containerSize.width, height: containerSize.width * 9.0 / 16.0)
  }
}

