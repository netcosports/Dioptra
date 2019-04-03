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
  lazy var playback: BCOVPlaybackController? = {
    guard let playback = self.playbackCreation?() else { return nil }
    if let targetView = self.targetView {
    targetView.addSubview(playback.view)
    }
    playback.delegate = self
    playback.isAutoAdvance = true
    playback.isAutoPlay = true
    playback.allowsExternalPlayback = true
    return playback
  }()

  public typealias PlaybackCreationBlock = ()->(BCOVPlaybackController?)

  open var accountID = ""
  open var servicePolicyKey = ""
  open var playbackCreation: PlaybackCreationBlock?
  open var targetView: UIView?

  override func startPlayback(with stream: String) {
    super.startPlayback(with: stream)
    guard let service = BCOVPlaybackService(accountId: accountID, policyKey: servicePolicyKey) else {
      return
    }
    service.findVideo(withVideoID: stream, parameters: [:]) { [weak self] (video, params, error) in
      guard let video = video else {
        self?.stateRelay.accept(.error(error: error))
        return
      }
      self?.playback?.setVideos([video] as NSFastEnumeration)
    }
    self.service = service
  }

  public func playbackController(_ controller: BCOVPlaybackController!, didAdvanceTo session: BCOVPlaybackSession!) {
    guard let player = session.player else { return }
    bind(to: player)
    guard let item = player.currentItem else { return }
    bind(to: item)
  }

  override func play() {
    playback?.play()
  }

  override func pause() {
    playback?.pause()
  }

  override func stop() {
    player?.replaceCurrentItem(with: nil)
  }

  override func seek(to seconds: TimeInSeconds) {
    if let timeRange = player?.currentItem?.seekableTimeRanges.last?.timeRangeValue {
      let duration = timeRange.end
      let progress = seconds / CMTimeGetSeconds(duration)
      let time = CMTime(value: CMTimeValue(Double(duration.value) * progress), timescale: duration.timescale)
      let tolerance = CMTime(seconds: 0.5, preferredTimescale: 1)
      playback?.seek(to: time, toleranceBefore: tolerance, toleranceAfter: tolerance, completionHandler: { [weak self] finished in
        if finished {
          self?.seekCompleatedRelay.accept(())
        }
      })
    }
  }
}
