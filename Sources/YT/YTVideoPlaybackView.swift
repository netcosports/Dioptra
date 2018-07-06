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
import SnapKit
import DailymotionPlayerSDK

open class YTVideoPlaybackView: UIView, PlaybackViewModable {

  public let viewModel = YTVideoPlaybackViewModel()
  lazy var playerViewController: DMPlayerViewController = {
    let parameters: [String: Any] = [
      "autoplay": true,
      "controls": false,
      "endscreen-enable": false
    ]
    let controller = DMPlayerViewController(parameters: parameters)
    controller.delegate = viewModel
    return controller
  }()

  fileprivate let disposeBag = DisposeBag()

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .black
    addSubview(playerViewController.view)

    viewModel.seek.asDriver(onErrorJustReturn: 0.0).drive(onNext: { [weak self] seconds in
      self?.playerViewController.seek(to: seconds)
    }).disposed(by: disposeBag)

    viewModel.streamSubject.asDriver(onErrorJustReturn: nil).drive(onNext: { [weak self] stream in
      if let stream = stream {
        self?.playerViewController.view.isHidden = false
        self?.playerViewController.load(videoId: stream)
      } else {
        self?.playerViewController.view.isHidden = true
        self?.playerViewController.pause()
      }
    }).disposed(by: disposeBag)

    viewModel.mutedRelay.asDriver().drive(onNext: { [weak self] muted in
      if muted {
        self?.playerViewController.mute()
      } else {
        self?.playerViewController.unmute()
      }
    }).disposed(by: disposeBag)

    viewModel.state.asDriver(onErrorJustReturn: PlaybackState.paused).drive(onNext: { [weak self] state in
      switch state {
      case .playing:
        self?.playerViewController.play()
      case .paused:
        self?.playerViewController.pause()
      default: break
      }
    }).disposed(by: disposeBag)
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open override func updateConstraints() {
    playerViewController.view.snp.remakeConstraints { make in
      make.edges.equalToSuperview()
    }
    super.updateConstraints()
  }
}
