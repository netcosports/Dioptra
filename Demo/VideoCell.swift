//
//  VideoCell.swift
//  Demo
//
//  Created by Sergei Mikhan on 8/21/18.
//  Copyright © 2018 Sergei Mikhan. All rights reserved.
//

import Astrolabe
import Dioptra
import RxSwift

class ManualLayoutView: UIView {

  override open class var requiresConstraintBasedLayout: Bool {
    return false
  }
}

class VideoCell: CollectionViewCell, Reusable {

  let disposeBag = DisposeBag()

  weak var landscapeViewController: UIViewController?
  weak var fullscreenViewController: UIViewController?

  //typealias Player = VideoPlayerView<BCVideoPlaybackView, VideoPlayerControlsView>
  //typealias Player = VideoPlayerView<DMVideoPlaybackView, VideoPlayerControlsView>
  typealias Player = VideoPlayerView<AVVideoPlaybackView, VideoPlayerControlsView>

  let player = Player(frame: CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.width - 48,
                                    height: (UIScreen.main.bounds.width - 48) * 9.0 / 16.0))
  let playerContainer = ManualLayoutView(frame: CGRect(x: 22.0, y: 44.0,
                                         width: UIScreen.main.bounds.width - 48,
                                         height: (UIScreen.main.bounds.width - 48) * 9.0 / 16.0))

  override func setup() {
    super.setup()

    playerContainer.translatesAutoresizingMaskIntoConstraints = true

    contentView.addSubview(playerContainer)
    playerContainer.addSubview(player)

//    player.playbackView.viewModel.accountID = "4800266849001"
//    player.playbackView.viewModel.servicePolicyKey = "BCpkADawqM3n0ImwKortQqSZCgJMcyVbb8lJVwt0z16UD0a_h8MpEYcHyKbM8CGOPxBRp0nfSVdfokXBrUu3Sso7Nujv3dnLo0JxC_lNXCl88O7NJ0PR0z2AprnJ_Lwnq7nTcy1GBUrQPr5e"
//    player.playbackView.viewModel.input = .content(stream: "5754208017001")
    //player.playbackView.viewModel.input = .content(stream: "x6k8h19")
    player.playbackView.viewModel.input = .content(stream: "https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8")
    player.playbackView.viewModel.muted = true
    player.controlsView.fullscreenButton.backgroundColor = UIColor.magenta
    player.controlsView.viewModel.fullscreen.subscribe(onNext: { [weak self] in
      self?.handleFullscreen()
    }).disposed(by: disposeBag)

    NotificationCenter.default.rx.notification(.UIDeviceOrientationDidChange, object: nil)
      .map { _ in return UIDevice.current.orientation }
      .distinctUntilChanged()
      .filter { [weak self] _ in self?.fullscreenViewController == nil }
      .filter { $0 != .portraitUpsideDown }
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

  override func willDisplay() {
    super.willDisplay()
    guard let containerView = containerView else { return }
    if player.detached {
      player.attach(to: playerContainer, with: playerContainer.bounds, overView: containerView)
    }
  }

  override func endDisplay() {
    super.endDisplay()
    guard let containerViewController = containerViewController else { return }
    let frame = CGRect(x: 20.0, y: 20.0, width: 120.0, height: 120.0 * 9.0 / 16.0)
    player.detach(to: containerViewController.view, with: frame)
  }

  typealias Data = Void
  static func size(for data: Data, containerSize: CGSize) -> CGSize {
    return CGSize(width: containerSize.width, height: containerSize.width * 9.0 / 16.0)
  }
}
