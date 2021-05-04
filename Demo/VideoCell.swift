//
//  VideoCell.swift
//  Demo
//
//  Created by Sergei Mikhan on 8/21/18.
//  Copyright © 2018 Sergei Mikhan. All rights reserved.
//

import Astrolabe
import Dioptra
//import Dioptra_BC

import Kingfisher

//import GoogleCast

import RxSwift

class ManualLayoutView: UIView {

  override open class var requiresConstraintBasedLayout: Bool {
    return false
  }
}
//
//class PlaceholderView: UIView, ChromecastStatusApplier {
//
//  let title = UILabel()
//  let image = UIImageView()
//
//  override init(frame: CGRect) {
//    super.init(frame: .zero)
//
//    addSubview(image)
//    addSubview(title)
//  }
//
//  required init?(coder: NSCoder) {
//    fatalError("init(coder:) has not been implemented")
//  }
//
//  override func layoutSubviews() {
//    super.layoutSubviews()
//
//    image.frame = bounds
//    title.frame = bounds
//
//    title.textColor = .white
//  }
//
//  func apply(status: GCKMediaStatus) {
//    guard let imageUrl = (status.mediaInformation?.metadata?.images() as? [GCKImage])?.first?.url else {
//      return
//    }
//    image.kf.setImage(with: imageUrl)
//    title.text = status.mediaInformation?.metadata?.string(forKey: kGCKMetadataKeyTitle)
//  }
//}

class VideoCell: CollectionViewCell, Reusable {

  let disposeBag = DisposeBag()

  weak var landscapeViewController: UIViewController?
  weak var fullscreenViewController: UIViewController?

//  typealias Playback = YTVideoPlaybackView
//  typealias Playback = DMVideoPlaybackView
//  typealias Playback = BCVideoPlaybackView
  typealias Playback = AVVideoPlaybackView
//  typealias Playback = BCVideoPlaybackWithControlsView

  //typealias Playback = CompositePlaybackView<ChromecastPlaybackView, AVVideoPlaybackView>
  typealias Player = VideoPlayerView<Playback, VideoPlayerControlsView>

  let videoPlayerView = AVVideoPlaybackView()

  let player = Player(frame: CGRect(
    x: 0.0, y: 0.0,
    width: UIScreen.main.bounds.width - 48,
    height: (UIScreen.main.bounds.width - 48) * 9.0 / 16.0
  ))
  let playerContainer = ManualLayoutView(frame: CGRect(x: 22.0, y: 44.0,
                                         width: UIScreen.main.bounds.width - 48,
                                         height: (UIScreen.main.bounds.width - 48) * 9.0 / 16.0))

  override func setup() {
    super.setup()

//    let metadata = GCKMediaMetadata()
//    metadata.setString("Big Buck Bunny (2008)", forKey: kGCKMetadataKeyTitle)
//    metadata.setString("Big Buck Bunny tells the story of a giant rabbit with a heart bigger than " +
//      "himself. When one sunny day three rodents rudely harass him, something " +
//      "snaps... and the rabbit ain't no bunny anymore! In the typical cartoon " +
//      "tradition he prepares the nasty rodents a comical revenge.",
//                       forKey: kGCKMetadataKeySubtitle)
//    metadata.addImage(GCKImage(url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg")!,
//                               width: 480,
//                               height: 360))
//
//    player.playbackView.firstPlaybackView.placeholderView = PlaceholderView()
//
//    player.playbackView.firstPlaybackView.viewModel.metadata = metadata
//
//
//    player.playbackView.firstPlaybackView.viewModel.rx.connected.debug("TEST").bind(
//      to: player.playbackView.rx.firstActive
//    ).disposed(by: disposeBag)

    playerContainer.translatesAutoresizingMaskIntoConstraints = true

    contentView.addSubview(playerContainer)
    playerContainer.addSubview(player)

    player.playbackView.viewModel.input = .content(stream: "https://commondatastorage.googleapis.com/gtv-videos-bucket/CastVideos/hls/DesigningForGoogleCast.m3u8")
    player.playbackView.viewModel.state.onNext(.playing)

//    player.playbackView.viewModel.servicePolicyKey = "BCpkADawqM0OUY2p9f8mN-yz3AYZG5JGObBFziLyu8f14LJ-g6hnM2eOFAN_IASTrVaNkpdNlq4bCQdoMTuKyRBbBMH4B4lpupOOXyfb18avJp_vBH-xZNaRqAE"
//    player.playbackView.viewModel.accountID = "887906353001"
//    player.playbackView.viewModel.input = .content(stream: "6095183635001")
//		player.playbackView.viewModel.input = .content(stream: "h7hEgE0S-uM")

    player.playbackView.viewModel.muted = true
    player.controlsView.fullscreenButton.setTitle("Full", for: .normal)
    player.controlsView.errorLabel.text = "Error"
    player.controlsView.viewModel.fullscreen.subscribe(onNext: { [weak self] in
      self?.handleFullscreen()
    }).disposed(by: disposeBag)

    player.playbackView.viewModel.playerState.asObservable().subscribe(onNext: { [weak self] playerState in
      switch playerState {
      case .ready:
        self?.player.playbackView.viewModel.state.onNext(PlaybackState.playing)
      default: break
      }
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
                        method: TransitionMethod.fullscreen(presentingView: self.player, dismissTarget: .frame))
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
