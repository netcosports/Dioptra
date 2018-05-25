//
//  ViewController.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 4/3/18.
//  Copyright © 2018 Sergei Mikhan. All rights reserved.
//

import UIKit
import SnapKit
import Dioptra

class ViewController: UIViewController {

  //typealias Player = VideoPlayerView<AVVideoPlaybackView, VideoPlayerControlsView>
  typealias Player = VideoPlayerView<DMVideoPlaybackView, VideoPlayerControlsView>
  let player = Player()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(player)
    player.snp.remakeConstraints {
      $0.top.leading.trailing.equalToSuperview()
      $0.height.equalTo(view.snp.width).multipliedBy(9.0 / 16.0)
    }
//    player.playbackView.viewModel.stream = "https://bitdash-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.m3u8"
    player.playbackView.viewModel.stream = "x6k8h19"

    player.playbackView.viewModel.muted = true
  }
}

