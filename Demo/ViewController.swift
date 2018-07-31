//
//  ViewController.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 4/3/18.
//  Copyright © 2018 Sergei Mikhan. All rights reserved.
//

import UIKit
import RxSwift
import Dioptra

class Container: UIView {

  override open class var requiresConstraintBasedLayout: Bool {
    return false
  }
}

class ViewController: UIViewController, Transitionable {

  var currentTransition: Transitionable.Transition?
  var customTransitionMethod = TransitionMethod.none
  var presentSubscribed = false
  var dismissSubscribed = false
  var disposeBag = DisposeBag()
  weak var detailsViewController: DetailsViewController?
  typealias Player = VideoPlayerView<BCVideoPlaybackView, VideoPlayerControlsView>
  //typealias Player = VideoPlayerView<AVVideoPlaybackView, VideoPlayerControlsView>
  //typealias Player = VideoPlayerView<DMVideoPlaybackView, VideoPlayerControlsView>

  let player = Player(frame: CGRect(x: 0.0, y: 0.0,
                                    width: UIScreen.main.bounds.width,
                                    height: UIScreen.main.bounds.width * 9.0 / 16.0))
  let playerContainer = Container(frame: CGRect(x: 0.0, y: 44.0,
                                                width: UIScreen.main.bounds.width,
                                                height: UIScreen.main.bounds.width * 9.0 / 16.0))

  override func viewDidLoad() {
    super.viewDidLoad()

    playerContainer.translatesAutoresizingMaskIntoConstraints = true

    view.addSubview(playerContainer)
    playerContainer.addSubview(player)

    player.playbackView.viewModel.accountID = "4800266849001"
    player.playbackView.viewModel.servicePolicyKey = "BCpkADawqM3n0ImwKortQqSZCgJMcyVbb8lJVwt0z16UD0a_h8MpEYcHyKbM8CGOPxBRp0nfSVdfokXBrUu3Sso7Nujv3dnLo0JxC_lNXCl88O7NJ0PR0z2AprnJ_Lwnq7nTcy1GBUrQPr5e"
    player.playbackView.viewModel.input = .content(stream: "5754208017001")
//    player.playbackView.viewModel.input = .content(stream: "https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8")
//    player.playbackView.viewModel.stream = .content(stream: "x6k8h19")
    player.playbackView.viewModel.muted = true

    NotificationCenter.default.rx.notification(.UIDeviceOrientationDidChange, object: nil).map({ _ -> UIDeviceOrientation in
      return UIDevice.current.orientation
    })
    .distinctUntilChanged()
    .filter({ orientation in
      return orientation != .portraitUpsideDown
    }).filter({ [weak self] _ -> Bool in
      guard let strongSelf = self else { return false }
      return true//strongSelf.playerView?.videoStreamUrl != nil
    }).filter({ [weak self] _ -> Bool in
      guard let detailsViewController = self?.detailsViewController else { return true }
      return !(detailsViewController.isBeingPresented || detailsViewController.isBeingDismissed)
    }).subscribe(onNext: { [weak self] orientation in
      if self?.detailsViewController != nil && orientation.isPortrait {
        //self?.setControlsWindowState(.window)
        self?.detailsViewController?.dismiss(animated: true)
      } else if orientation.isLandscape && self?.detailsViewController == nil {
        self?.toFullscreen()
      }
    }).disposed(by: disposeBag)
  }

  fileprivate func toFullscreen() {
    let detailsViewController = DetailsViewController()
    self.detailsViewController = detailsViewController
    present(modal: detailsViewController, method: .player(presentingView: self.player))
  }

  func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {

    return presentTransition() { [weak presented] in
      presented?.dismiss(animated: true)
    }
  }

  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return .portrait
  }

  func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    return dismissTransition
  }
}

