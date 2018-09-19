//
//  YTVideoPlaybackView.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 5/4/17.
//  Copyright © 2018 Netcosports. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import youtube_ios_player_helper

open class YTVideoPlaybackView: UIView, PlaybackViewModable {

  public let viewModel = YTVideoPlaybackViewModel()
  lazy var playerView: YTPlayerView = {
    let playerView = YTPlayerView(frame: CGRect.zero)
    playerView.delegate = viewModel
    return playerView
  }()

  fileprivate let disposeBag = DisposeBag()

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .black
    addSubview(playerView)

    viewModel.seek.asDriver(onErrorJustReturn: 0.0).drive(onNext: { [weak self] seconds in
      self?.playerView.seek(toSeconds: Float(seconds), allowSeekAhead: true)
    }).disposed(by: disposeBag)

    viewModel.streamSubject.asDriver(onErrorJustReturn: nil).drive(onNext: { [weak self] stream in
      if let stream = stream {
        self?.playerView.isHidden = false
        let vars: [String: Any] = [
           "controls": 0,
           "autoplay": 1,
           "showinfo": 0,
           "rel": 0,
           "playsinline": 1,
           "origin": "http://www.youtube.com"
        ]
        self?.playerView.load(withVideoId: stream, playerVars: vars)
      } else {
        self?.playerView.isHidden = true
        self?.playerView.pauseVideo()
      }
    }).disposed(by: disposeBag)

//    viewModel.mutedRelay.asDriver().drive(onNext: { [weak self] muted in
//      if muted {
//        self?.playerView.mute()
//      } else {
//        self?.playerViewController.unmute()
//      }
//    }).disposed(by: disposeBag)

    viewModel.state.asDriver(onErrorJustReturn: PlaybackState.paused).drive(onNext: { [weak self] state in
      switch state {
      case .playing:
        self?.playerView.playVideo()
      case .paused:
        self?.playerView.pauseVideo()
      default: break
      }
    }).disposed(by: disposeBag)
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open override func layoutSubviews() {
    super.layoutSubviews()
    playerView.frame = bounds
  }
}
