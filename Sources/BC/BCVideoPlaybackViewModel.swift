//
//  BCVideoPlaybackViewModel.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 7/05/18.
//  Copyright © 2018 Sergei Mikhan. All rights reserved.
//

import AVKit
import BrightcovePlayerSDK
import RxSwift
import RxCocoa

open class BCVideoPlaybackViewModel: AVVideoPlaybackManagableViewModel, BCOVPlaybackControllerDelegate {

  var service: BCOVPlaybackService?
  let playback: BCOVPlaybackController

  open var accountID = ""
  open var servicePolicyKey = ""

  override init() {
    playback = BCOVPlayerSDKManager.shared().createPlaybackController()
    super.init()

    playback.delegate = self
    playback.isAutoAdvance = true
    playback.isAutoPlay = true
    playback.setAllowsExternalPlayback(true)
  }

  override func startPlayback(with stream: String) {
    guard let service = BCOVPlaybackService(accountId: accountID, policyKey: servicePolicyKey) else {
      return
    }
    service.findVideo(withVideoID: stream, parameters: [:]) { [weak self] (video, params, error) in
      guard let video = video else { return }
      self?.playback.setVideos([video] as NSFastEnumeration)
    }
    self.service = service
  }

  public func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
    guard let player = session.player else { return }
    bind(to: player)
    guard let item = player.currentItem else { return }
    bind(to: item)
  }
}
