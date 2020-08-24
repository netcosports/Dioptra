//
//  PlayerWrapperController.swift
//  Demo
//
//  Created by Sergei Mikhan on 12/26/19.
//

import Dioptra
import DailymotionPlayerSDK

class DMPlayerDemo {
  
  lazy var playerViewController: DMPlayerViewController = {
    let parameters: [String: Any] = [
      "autoplay": true,
      "controls": false,
      "endscreen-enable": false
    ]
    let controller = DMPlayerViewController(parameters: parameters)
    controller.delegate = self
    return controller
  }()
  
  fileprivate var seekCompletionClosure: WrapperVoidClosure?
  fileprivate var progressClosure: WrapperProgressClosure?
  fileprivate var playerStateClosure: WrapperPlayerStateClosure?
  fileprivate var availableVideoQualities: WrapperQualitiesClosure?
  fileprivate var playing = false

  var playerView: UIView {
    return playerViewController.view
  }
  
  var isMuted: Bool = false {
    didSet {
      if isMuted {
        playerViewController.mute()
      } else {
        playerViewController.unmute()
      }
    }
  }
  var playbackSpeed: Double = 1.0
  
  func set(stream: String) {
    self.playerViewController.load(videoId: stream)
  }
}

extension DMPlayerDemo: DMPlayerViewControllerDelegate {

  public func playerDidInitialize(_ player: DMPlayerViewController) {

  }

  public func player(_ player: DMPlayerViewController, didFailToInitializeWithError error: Error) {

  }

  public func player(_ player: DMPlayerViewController, didReceiveEvent event: PlayerEvent) {
    switch event {
    case let .timeEvent(name, time):
      switch name {
      case "durationchange":
        progressClosure?(.duration(time))
      case "timeupdate":
        progressClosure?(.progress(time))
      case "progress":
        progressClosure?(.buffer(time))
      case "seeked":
        playerStateClosure?(.active(state: playing ? .playing : .paused))
        seekCompletionClosure?()
      default: break
      }
    case let .namedEvent(name, _):
      switch name {
      case "playback_ready":
        playerStateClosure?(.ready)
      case "playing":
        playerStateClosure?(.active(state: .playing))
        playing = true
      case "pause":
        playerStateClosure?(.active(state: .paused))
        playing = false
      case "video_end":
        playerStateClosure?(.finished)
      case "ad_start":
        playerStateClosure?(.ad(state: .started))
      case "ad_end":
        playerStateClosure?(.ad(state: .finished))
      case "error":
				playerStateClosure?(.error(error: .playback(error: nil)))
      case "waiting":
        playerStateClosure?(.loading)
      default: break
      }
    }
  }

  public func player(_ player: DMPlayerViewController, openUrl url: URL) {
  }
}

extension DMPlayerDemo: PlayerWrapper {

  var isPlaybackSpeedSupported: Bool {
    return false
  }
  
  func seek(progress: TimeInSeconds, completion: @escaping WrapperVoidClosure) {
    playerViewController.seek(to: progress)
    self.seekCompletionClosure = completion
  }
  
  func setPlaybackState(state: PlaybackState) {
    switch state {
    case .paused:
      playerViewController.pause()
    case .playing:
      playerViewController.play()
    }
  }
  
  func selectVideoQuality(videoQuality: VideoQuality) {
    // NOT SUPPORTED
  }
  
  func setDidChangeProgress(closure: @escaping WrapperProgressClosure) {
    progressClosure = closure
  }

  func setDidChangePlayerState(closure: @escaping WrapperPlayerStateClosure) {
    playerStateClosure = closure
  }

  func setDidChangeAvailableVideoQualities(closure: @escaping WrapperQualitiesClosure) {
    availableVideoQualities = closure
  }
}

class PlayerWrapperController: UIViewController {
  
  typealias Player = VideoPlayerView<WrapperView, VideoPlayerControlsView>

  let player = Player()
  let wrapper = DMPlayerDemo()

  override func viewDidLoad() {
    super.viewDidLoad()
    player.playbackView.viewModel.player = wrapper
    view.addSubview(player)
    wrapper.set(stream: "x7pmih5")
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    player.frame = view.bounds
  }
}

