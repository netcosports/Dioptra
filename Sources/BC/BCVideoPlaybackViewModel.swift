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

  static var AccountID = "3636334163001"
  static var ServicePolicyKey = "BCpkADawqM1W-vUOMe6RSA3pA6Vw-VWUNn5rL0lzQabvrI63-VjS93gVUugDlmBpHIxP16X8TSe5LSKM415UHeMBmxl7pqcwVY_AZ4yKFwIpZPvXE34TpXEYYcmulxJQAOvHbv2dpfq-S_cm"

  let service: BCOVPlaybackService
  let playback: BCOVPlaybackController

  override init() {
    service = BCOVPlaybackService(accountId: BCVideoPlaybackViewModel.AccountID,
                                  policyKey: BCVideoPlaybackViewModel.ServicePolicyKey)
    playback = BCOVPlayerSDKManager.shared().createPlaybackController()
    super.init()

    playback.delegate = self
    playback.isAutoAdvance = true
    playback.isAutoPlay = true
    playback.setAllowsExternalPlayback(true)
  }

  override func startPlayback(with stream: String) {
    service.findVideo(withVideoID: stream, parameters: [:]) { [weak self] (video, params, error) in
      guard let video = video else { return }
      self?.playback.setVideos([video] as NSFastEnumeration)
    }
  }

  public func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
    guard let player = session.player else { return }
    bind(to: player)
    guard let item = player.currentItem else { return }
    bind(to: item)
  }
}
