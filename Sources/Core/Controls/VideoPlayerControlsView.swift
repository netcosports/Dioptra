//
//  VideoPlayerControlsView.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 3/31/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxGesture

open class VideoPlayerControlsView: UIView, ControlsViewModable {

  public let viewModel = VideoPlayerControlsViewModel()
  var screenMode = ScreenMode.compact

  enum Sizes: CGFloat {
    case sliderHeight = 48.0
    case button       = 88.0
  }

  public private(set) var contentView = UIView()

  public private(set) var playButton: PlaybackButton = {
    let playButton = PlaybackButton()
    let inset: CGFloat = 20
    playButton.contentEdgeInsets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
    return playButton
  }()

  public private(set) var slider: BufferedSlider = {
    let slider = BufferedSlider()
    slider.minimumValue = 0.0
    slider.maximumValue = 1.0
    slider.sliderPosition = .center
    slider.borderWidth = 0.0
    slider.sliderHeight = 5.0
    slider.progressColor = .white
    slider.bufferColor = .lightGray
    slider.baseColor = .white
    slider.roundedSlider = true
    slider.hollow = false
    slider.padding = 5.0
    slider.isContinuous = true
    slider.tintColor = .white
    return slider
  }()

  public private(set) var overlayView: UIView = {
    let overlayView = UIView()
    overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.33)
    overlayView.isUserInteractionEnabled = true
    return overlayView
  }()

  public private(set) var startTimeLabel: UILabel = {
    let startTimeLabel = UILabel()
    startTimeLabel.textColor = .white
    startTimeLabel.textAlignment = .center
    return startTimeLabel
  }()

  public private(set) var endTimeLabel: UILabel = {
    let endTimeLabel = UILabel()
    endTimeLabel.textColor = .white
    endTimeLabel.textAlignment = .center
    return endTimeLabel
  }()

  public private(set) var errorLabel: UILabel = {
    let errorLabel = UILabel()
    errorLabel.textColor = .white
    errorLabel.textAlignment = .center
    errorLabel.alpha = 0.0
    return errorLabel
  }()

  public private(set) var fullscreenButton: UIButton = {
    let button = UIButton()
    return button
  }()

  public private(set) var indicatorView: UIActivityIndicatorView = {
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

  open override func layoutSubviews() {
    super.layoutSubviews()
    let margin: CGFloat = 2.0
    let labelWidth: CGFloat = 80.0
    let width = frame.width
    let height = frame.height
    let size = CGSize(width: Sizes.button.rawValue, height: Sizes.button.rawValue)

    contentView.frame = bounds
    errorLabel.frame = bounds
    overlayView.frame = bounds
    playButton.center = center
    playButton.bounds = CGRect(origin: .zero, size: size)
    indicatorView.center = center
    indicatorView.bounds = CGRect(origin: .zero, size: size)

    slider.frame = CGRect(x: labelWidth + margin,
                          y: height - Sizes.sliderHeight.rawValue,
                          width: width - 2.0 * (margin + labelWidth) - (Sizes.sliderHeight.rawValue + margin),
                          height: Sizes.sliderHeight.rawValue)
    startTimeLabel.frame = CGRect(x: 0.0, y: height - Sizes.sliderHeight.rawValue,
                                  width: labelWidth, height: Sizes.sliderHeight.rawValue)
    endTimeLabel.frame = CGRect(x: slider.frame.maxX + margin, y: height - Sizes.sliderHeight.rawValue,
                                width: labelWidth, height: Sizes.sliderHeight.rawValue)
    fullscreenButton.frame = CGRect(x: slider.frame.maxX + margin + labelWidth + margin,
                                    y: height - Sizes.sliderHeight.rawValue,
                                    width: Sizes.sliderHeight.rawValue, height: Sizes.sliderHeight.rawValue)
  }

  open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    if viewModel.visibleRelay.value.visible {
      self.viewModel.visibilityChange.accept(.soft(visible: true))
    }
    return super.hitTest(point, with: event)
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

    viewModel.visible.drive(onNext: { [weak self] visibility in
      guard let `self` = self else { return }
        switch visibility {
        case .force(let visible):
          self.contentView.isHidden = !visible
        case .soft(let visible):
          self.contentView.isHidden = false
      }
      UIView.animate(withDuration: 0.33) {
        self.update(with: visibility.visible)
        self.layoutIfNeeded()
      }
    }).disposed(by: disposeBag)

    viewModel.state.subscribe(onNext: { state in
      switch state {
      case .error:
        self.viewModel.visibilityChange.accept(VisibilityChangeEvent.force(visible: false))
        self.errorLabel.alpha = 1.0
      default:
        if self.errorLabel.alpha == 1.0 {
          self.viewModel.visibilityChange.accept(VisibilityChangeEvent.force(visible: true))
          self.errorLabel.alpha = 0.0
        }
      }
    }).disposed(by: disposeBag)

    viewModel.state.map {
      switch $0 {
      case .loading, .stuck: return true
      default: return false
      }
    }.bind(to: indicatorView.rx.isAnimating).disposed(by: disposeBag)

    playButton.rx.tap.asObservable().map { [weak self] () -> PlaybackState in
      guard let `self` = self else { return .paused }
      if self.playButton.buttonState == .playing {
        return .paused
      } else {
        return .playing
      }
    }.bind(to: viewModel.stateSubject).disposed(by: disposeBag)

    slider.rx.controlEvent(.touchDown).asObservable().flatMap { [weak self] _ -> Observable<SeekEvent> in
      guard let `self` = self else { return .empty() }
      return .just(SeekEvent.started(progress: self.slider.value))
    }.bind(to: viewModel.seekSubject).disposed(by: disposeBag)

    slider.rx.controlEvent(.touchUpInside).asObservable().flatMap { [weak self] _ -> Observable<SeekEvent> in
      guard let `self` = self else { return .empty() }
      return .just(SeekEvent.finished(progress: self.slider.value))
    }.bind(to: viewModel.seekSubject).disposed(by: disposeBag)

    slider.rx.controlEvent(.touchUpOutside).asObservable().flatMap { [weak self] _ -> Observable<SeekEvent> in
      guard let `self` = self else { return .empty() }
      return .just(SeekEvent.finished(progress: self.slider.value))
    }.bind(to: viewModel.seekSubject).disposed(by: disposeBag)

    slider.rx.controlEvent(.valueChanged).asObservable().flatMap { [weak self] event -> Observable<SeekEvent> in
      guard let `self` = self else { return .empty() }
      self.viewModel.visibilityChange.accept(.acceptSoft)
      self.viewModel.visibilityChange.accept(.soft(visible: true))
      return .just(SeekEvent.value(progress: self.slider.value))
    }.bind(to: viewModel.seekSubject).disposed(by: disposeBag)

    fullscreenButton.rx.tap.bind(to: viewModel.fullscreen).disposed(by: disposeBag)

    viewModel.screenMode.asDriver().drive(onNext: { [weak self] screenMode in
      self?.update(with: screenMode)
    }).disposed(by: disposeBag)
  }

  fileprivate func update(with screenMode: ScreenMode) {
    self.screenMode = screenMode
    update(with: true)
    setNeedsLayout()
  }

  fileprivate func update(with visibility: Bool) {
    // FIXME: we need to setup correct way to manage this
    guard self.errorLabel.alpha == 0.0 else { return }
    self.playButton.alpha = visibility ? 1.0 : 0.0
    switch self.screenMode {
    case .minimized:
      self.overlayView.alpha = 0.0
      self.fullscreenButton.alpha = 0.0
      self.slider.alpha = 0.0
      self.startTimeLabel.alpha = 0.0
      self.endTimeLabel.alpha = 0.0
    default:
      self.overlayView.alpha = visibility ? 1.0 : 0.0
      self.fullscreenButton.alpha = visibility ? 1.0 : 0.0
      self.slider.alpha = visibility ? 1.0 : 0.0
      self.startTimeLabel.alpha = visibility ? 1.0 : 0.0
      self.endTimeLabel.alpha = visibility ? 1.0 : 0.0
    }
  }

  fileprivate func setup() {
    addSubview(contentView)
    contentView.addSubview(overlayView)
    contentView.addSubview(playButton)
    contentView.addSubview(indicatorView)
    contentView.addSubview(slider)
    contentView.addSubview(startTimeLabel)
    contentView.addSubview(endTimeLabel)
    contentView.addSubview(fullscreenButton)
    addSubview(errorLabel)
  }

  override open class var requiresConstraintBasedLayout: Bool {
    return false
  }
}
