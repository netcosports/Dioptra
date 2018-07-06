//
//  VideoPlayerControlsView.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 3/31/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RxGesture

open class VideoPlayerControlsView: UIView, ControlsViewModable {

  public let viewModel = VideoPlayerControlsViewModel()

  enum Sizes: CGFloat {
    case sliderHeight = 20.0
    case button = 62.0
  }

  private(set) var playButton: PlaybackButton = {
    let frame = CGRect(origin: CGPoint.zero, size: CGSize(width: Sizes.button.rawValue, height: Sizes.button.rawValue))
    let playButton = PlaybackButton(frame: frame)
    playButton.contentEdgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    return playButton
  }()

  fileprivate let slider: BufferedSlider = {
    let slider = BufferedSlider()
    slider.minimumValue = 0.0
    slider.maximumValue = 1.0
    slider.value = 0.3
    slider.sliderPosition = .center
    slider.borderWidth = 0.0
    slider.progressColor = .white
    slider.bufferColor = .lightGray
    slider.baseColor = .darkGray
    slider.roundedSlider = false
    slider.hollow = false
    slider.isContinuous = true
    slider.tintColor = .white
    return slider
  }()

  fileprivate let fullScreenModeButton: UIButton = {
    let fullScreenModeButton = UIButton()
    fullScreenModeButton.contentMode = .center
    fullScreenModeButton.backgroundColor = .orange
    return fullScreenModeButton
  }()

  fileprivate let startTimeLabel: UILabel = {
    let startTimeLabel = UILabel()
    startTimeLabel.textColor = .white
    startTimeLabel.textAlignment = .center
    return startTimeLabel
  }()

  fileprivate let endTimeLabel: UILabel = {
    let endTimeLabel = UILabel()
    endTimeLabel.textColor = .white
    endTimeLabel.textAlignment = .center
    return endTimeLabel
  }()

  fileprivate let indicatorView: UIActivityIndicatorView = {
    let indicatorView = UIActivityIndicatorView()
    indicatorView.color = .white
    return indicatorView
  }()

  let disposeBag = DisposeBag()
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
    bind()
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  fileprivate func bind() {
    viewModel.currentTime.drive(startTimeLabel.rx.text).disposed(by: disposeBag)
    viewModel.duration.drive(endTimeLabel.rx.text).disposed(by: disposeBag)
    viewModel.buffer.bind(to: slider.rx.buffer).disposed(by: disposeBag)
    viewModel.bufferedValue.drive(slider.rx.bufferedValue).disposed(by: disposeBag)
    self.rx.tapGesture().when(.recognized).map { _ -> VisibilityChangeEvent in return .softToggle }
      .bind(to: viewModel.visibilityChange).disposed(by: disposeBag)

    viewModel.state.map {
      switch $0 {
      case .active(let state):
        switch state {
        case .playing: return PlaybackButtonState.playing
        case .paused: return PlaybackButtonState.pausing
        }
      default: return PlaybackButtonState.pausing
      }
    }.bind(to: playButton.rx.state).disposed(by: disposeBag)

    viewModel.visible.asDriver().drive(onNext: { [weak self] visibility in
        switch visibility {
        case .force(let visible):
          self?.isHidden = !visible
        case .soft(let visible):
          self?.isHidden = false
      }
      UIView.animate(withDuration: 0.33) {
        self?.subviews.forEach { $0.alpha = (visibility.visible ? 1.0 : 0.0) }
        self?.setNeedsUpdateConstraints()
        self?.layoutIfNeeded()
      }
    }).disposed(by: disposeBag)

    viewModel.state.map {
      switch $0 {
      case .loading, .stuck: return true
      default: return false
      }
    }.bind(to: indicatorView.rx.isAnimating).disposed(by: disposeBag)

    playButton.rx.tap.asObservable().map { [weak self] () -> PlaybackState in
      if self?.playButton.buttonState == .playing {
        return PlaybackState.paused
      } else {
        return PlaybackState.playing
      }
      self?.viewModel.visibilityChange.accept(VisibilityChangeEvent.soft(visible: true))
    }.bind(to: viewModel.stateSubject).disposed(by: disposeBag)

    slider.rx.controlEvent(.touchDown).asObservable().flatMap { [weak self] _ -> Observable<SeekEvent> in
      guard let `self` = self else { return .empty() }
      self.viewModel.visibilityChange.accept(VisibilityChangeEvent.force(visible: true))
      return Observable<SeekEvent>.just(SeekEvent.started(progress: self.slider.value))
    }.bind(to: viewModel.seekSubject).disposed(by: disposeBag)

    slider.rx.controlEvent(.touchUpInside).asObservable().flatMap { [weak self] _ -> Observable<SeekEvent> in
      guard let `self` = self else { return .empty() }
      self.viewModel.visibilityChange.accept(VisibilityChangeEvent.acceptSoft)
      self.viewModel.visibilityChange.accept(VisibilityChangeEvent.soft(visible: true))
      return Observable<SeekEvent>.just(SeekEvent.finished(progress: self.slider.value))
    }.bind(to: viewModel.seekSubject).disposed(by: disposeBag)

    slider.rx.controlEvent(.valueChanged).asObservable().flatMap { [weak self] event -> Observable<SeekEvent> in
      guard let `self` = self else { return .empty() }
      return Observable<SeekEvent>.just(SeekEvent.value(progress: self.slider.value))
    }.bind(to: viewModel.seekSubject).disposed(by: disposeBag)


  }

  fileprivate func setup() {
    addSubview(playButton)
    addSubview(indicatorView)
    addSubview(slider)
    addSubview(fullScreenModeButton)
    addSubview(startTimeLabel)
    addSubview(endTimeLabel)
  }

  open override func updateConstraints() {
    playButton.snp.remakeConstraints {
      $0.width.height.equalTo(Sizes.button.rawValue)
      $0.center.equalToSuperview()
    }
    startTimeLabel.snp.remakeConstraints {
      $0.width.equalTo(80.0)
      $0.leading.equalToSuperview()
      $0.centerY.equalTo(slider)
    }
    slider.snp.remakeConstraints {
      $0.leading.equalTo(startTimeLabel.snp.trailing).inset(5.0)
      $0.trailing.equalTo(endTimeLabel.snp.leading).inset(5.0)
      $0.bottom.equalToSuperview().inset(Sizes.sliderHeight.rawValue / 2.0)
      $0.height.equalTo(Sizes.sliderHeight.rawValue)
    }
    endTimeLabel.snp.remakeConstraints {
      $0.width.equalTo(80.0)
      $0.trailing.equalTo(fullScreenModeButton.snp.leading).inset(5.0)
      $0.centerY.equalTo(slider)
    }
    fullScreenModeButton.snp.remakeConstraints {
      $0.trailing.equalToSuperview().inset(5.0)
      $0.width.height.equalTo(30.0)
      $0.bottom.equalTo(slider.snp.top)
    }
    indicatorView.snp.remakeConstraints {
      $0.width.height.equalTo(Sizes.button.rawValue)
      $0.center.equalToSuperview()
    }
    super.updateConstraints()
  }
}
