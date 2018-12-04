//
//  VideoPlayerControlsViewModel.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 5/13/18.
//  Copyright © 2018 Sergei Mikhan. All rights reserved.
//

import RxSwift
import RxCocoa

open class VideoPlayerControlsViewModel: VideoControls {

  public struct Settings {
    public init(autoHideTimer: Double = 3.0) {
      self.autoHideTimer = autoHideTimer
    }
    public var autoHideTimer: Double
  }

  public init(settings: Settings = Settings()) {
    self.settings = settings
    bind()
  }

  fileprivate var currentVisibility = VisibilityChangeEvent.soft(visible: false)
  fileprivate let disposeBag = DisposeBag()
  fileprivate var currentTimeRelay: PublishRelay<String>?
  fileprivate var durationRelay: PublishRelay<String>?

  public var settings: Settings
  public var seekCompleted = PublishSubject<Void>()
  public var visibilityChange = BehaviorRelay<VisibilityChangeEvent>(value: .soft(visible: false))
  public let screenMode = BehaviorRelay<ScreenMode>(value: .compact)
  public let buffer = PublishSubject<Float>()
  public let fullscreen = PublishSubject<Void>()
  public let progress = PublishSubject<Progress>()
  public let state = PublishSubject<PlayerState>()
  public var seek: Driver<SeekEvent> {
    return seekSubject.asDriver(onErrorJustReturn: SeekEvent.value(progress: 0.0))
  }
  public var play: Driver<PlaybackState> {
    return stateSubject.asDriver(onErrorJustReturn: PlaybackState.paused)
  }

  public let seekSubject = PublishRelay<SeekEvent>()
  public let stateSubject = PublishRelay<PlaybackState>()
  public let visibleRelay = BehaviorRelay<Visibility>(value: Visibility.soft(visible: true))

  public var currentTime: Driver<String> {
    let timeRelay: PublishRelay<String>
    if let currentTimeRelay = self.currentTimeRelay {
      timeRelay = currentTimeRelay
    } else {
      timeRelay = PublishRelay<String>()
      self.currentTimeRelay = timeRelay
    }
    return timeRelay.asDriver(onErrorJustReturn: "").distinctUntilChanged()
  }
  public var duration: Driver<String> {
    let durationRelay: PublishRelay<String>
    if let currentDurationRelay = self.durationRelay {
      durationRelay = currentDurationRelay
    } else {
      durationRelay = PublishRelay<String>()
      self.durationRelay = durationRelay
    }
    return durationRelay.asDriver(onErrorJustReturn: "").distinctUntilChanged()
  }
  public var bufferedValue: Driver<Float> {
    let progressFilter: Driver<Bool> = seek.map {
      switch $0 {
      case .finished: return true
      default: return false
      }
    }.startWith(true).asDriver()

    return progress.asDriver(onErrorJustReturn: Progress.empty())
      .withLatestFrom(progressFilter, resultSelector: { ($0, $1) })
      .filter { progressAndSeek -> Bool in return progressAndSeek.1 }
      .map { progressAndSeek -> Progress in return progressAndSeek.0 }
      .map { $0.total == 0.0 ? 0.0 : Float($0.value / $0.total) }
  }

  public var visible: Driver<Visibility> {
    return visibleRelay.distinctUntilChanged().asDriver(onErrorJustReturn: Visibility.soft(visible: false))
  }

  open func secondsText(with time: TimeInSeconds) -> String {
    let absTime = abs(time)
    let hours = Int(absTime / 3600)
    let minutes = Int((absTime.truncatingRemainder(dividingBy: 3600)) / 60)
    let seconds = Int(absTime.truncatingRemainder(dividingBy: 60))
    var result = ""
    if hours > 0 {
      result += "\(String(format: "%02d", hours)):"
    }
    return "\(time < 0.0 ? "-" : "")" + result + "\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds))"
  }
}

extension VideoPlayerControlsViewModel {

  fileprivate func bind() {
    progress.asDriver(onErrorJustReturn: Progress.empty()).drive(onNext: { [weak self] progress in
      guard let `self` = self else { return }
      if let currentTimeRelay = self.currentTimeRelay {
        currentTimeRelay.accept(self.secondsText(with: progress.value))
      }
      if let durationRelay = self.durationRelay {
        durationRelay.accept(self.secondsText(with: progress.total))
      }
    }).disposed(by: disposeBag)

    seekSubject.asObservable().flatMap { seekEvent -> Observable<PlaybackState> in
      switch seekEvent {
      case .started: return .just(PlaybackState.paused)
      case .finished: return .just(PlaybackState.playing)
      default: return .empty()
      }
    }.bind(to: stateSubject).disposed(by: disposeBag)

    screenMode.asDriver().map { _ in VisibilityChangeEvent.soft(visible: true) }.drive(visibilityChange).disposed(by: disposeBag)

    visibilityChange.asDriver()
      .filter { [weak self] in
        switch $0 {
        case .soft(let visible):
          return visible
        case .softToggle:
          guard let visible = self?.visibleRelay.value.visible else { return false }
          return !visible
        default:
          return false
        }
      }
      .debounce(settings.autoHideTimer)
      .map { _ in
        Visibility.soft(visible: false)
      }
      .filter { [weak self] _ -> Bool in
        guard let `self` = self else { return false }
        switch self.visibilityChange.value {
          case .force: return false
          default: return true
        }
      }
      .drive(visibleRelay)
      .disposed(by: disposeBag)

    visibilityChange.asDriver().drive(onNext: { [weak self] visibility in
      guard let `self` = self else { return }
      let controlsVisible: Visibility
      switch visibility {
      case .force(let visible):
        controlsVisible = Visibility.force(visible: visible)
      case .soft(let visible):
        switch self.currentVisibility {
        case .force: return
        case .acceptSoft, .soft, .softToggle:
          controlsVisible = Visibility.soft(visible: visible)
        }
      case .softToggle:
        switch self.currentVisibility {
        case .force: return
        case .soft, .acceptSoft, .softToggle:
          controlsVisible = Visibility.soft(visible: !self.visibleRelay.value.visible)
        }
      case .acceptSoft:
        controlsVisible = Visibility.force(visible: true)
      }
      self.currentVisibility = visibility
      self.visibleRelay.accept(controlsVisible)
    }).disposed(by: disposeBag)
  }
}
