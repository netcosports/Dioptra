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

  init() {
    bind()
  }

  fileprivate var currentVisibility = Visibility.soft(visible: false)
  fileprivate let disposeBag = DisposeBag()
  fileprivate let currentTimeRelay = PublishRelay<String>()
  fileprivate let durationRelay = PublishRelay<String>()
  fileprivate let screenModeSubject = PublishRelay<ScreenModeEvent>()

  public var visibilityChange = BehaviorRelay<Visibility>(value: .soft(visible: false))
  public let buffer = PublishSubject<Float>()
  public let progress = PublishSubject<Progress>()
  public let state = PublishSubject<PlayerState>()
  public var seek: Driver<SeekEvent> {
    return seekSubject.asDriver(onErrorJustReturn: SeekEvent.value(progress: 0.0))
  }
  public var screenMode: Driver<ScreenModeEvent> {
    return screenModeSubject.asDriver(onErrorJustReturn: ScreenModeEvent.compact)
  }
  public var play: Driver<PlaybackState> {
    return stateSubject.asDriver(onErrorJustReturn: PlaybackState.paused)
  }

  let seekSubject = PublishRelay<SeekEvent>()
  let stateSubject = PublishRelay<PlaybackState>()
  let visible = BehaviorRelay<Bool>(value: true)
  var currentTime: Driver<String> {
    return currentTimeRelay.asDriver(onErrorJustReturn: "").distinctUntilChanged()
  }
  var duration: Driver<String> {
    return durationRelay.asDriver(onErrorJustReturn: "").distinctUntilChanged()
  }
  var bufferedValue: Driver<Float> {
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
}

extension VideoPlayerControlsViewModel {

  fileprivate func bind() {
    progress.asDriver(onErrorJustReturn: Progress.empty()).drive(onNext: { [weak self] progress in
      guard progress.value.isNaN == false && progress.total.isNaN == false else { return }
      self?.currentTimeRelay.accept(VideoPlayerControlsViewModel.secondsText(with: progress.value))
      self?.durationRelay.accept(VideoPlayerControlsViewModel.secondsText(with: progress.total))
    }).disposed(by: disposeBag)

    seekSubject.asObservable().flatMap { seekEvent -> Observable<PlaybackState> in
      switch seekEvent {
      case .started: return .just(PlaybackState.paused)
      case .finished: return .just(PlaybackState.playing)
      default: return .empty()
      }
    }.bind(to: stateSubject).disposed(by: disposeBag)

    screenMode.map { _ in Visibility.soft(visible: true) }.drive(visibilityChange).disposed(by: disposeBag)

    visibilityChange.asDriver()
      .debounce(3.0)
      .filter { [weak self] in
        switch $0 {
        case .soft(let visible): return visible
        case .softToggle: return self?.visible.value ?? false
        default: return false
        }
      }
      .map { _ in false }
      .drive(visible)
      .disposed(by: disposeBag)

    visibilityChange.asDriver().drive(onNext: { [weak self] visibility in
      guard let `self` = self else { return }
      let controlsVisible: Bool
      switch visibility {
      case .force(let visible):
        controlsVisible = visible
      case .soft(let visible):
        switch self.currentVisibility {
        case .force: return
        case .acceptSoft, .soft, .softToggle: controlsVisible = visible
        }
      case .softToggle:
        switch self.currentVisibility {
        case .force: return
        case .soft(let previousVisibility): controlsVisible = previousVisibility
        case .acceptSoft, .softToggle: controlsVisible = !self.visible.value
        }
      case .acceptSoft:
        self.currentVisibility = visibility
        return
      }
      self.currentVisibility = visibility
      self.visible.accept(controlsVisible)
    }).disposed(by: disposeBag)
  }

  fileprivate static func secondsText(with time: TimeInSeconds) -> String {
    let hours = Int(time / 3600)
    let minutes = Int((time.truncatingRemainder(dividingBy: 3600)) / 60)
    let seconds = Int(time.truncatingRemainder(dividingBy: 60))
    var result = ""
    if hours > 0 {
      result += "\(String(format: "%02d", hours)):"
    }
    return result + "\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds))"
  }
}
