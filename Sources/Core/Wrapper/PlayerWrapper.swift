//
//  PlayerWrapper.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 12/24/19.
//

public typealias WrapperVoidClosure = () -> Void
public typealias WrapperProgressClosure = (ProgressEvent) -> Void
public typealias WrapperPlayerStateClosure = (PlayerState) -> Void
public typealias WrapperQualitiesClosure = ([VideoQuality]) -> Void

public enum ProgressEvent {
  case progress(TimeInSeconds)
  case duration(TimeInSeconds)
  case buffer(TimeInSeconds)
}

public protocol PlayerWrapper: class {
  
  var playerView: UIView { get }

  var isMuted: Bool { get set }
  var playbackSpeed: Double { get set }

  var isPlaybackSpeedSupported: Bool { get }

  func seek(progress: TimeInSeconds, completion: @escaping WrapperVoidClosure)
  func setPlaybackState(state: PlaybackState)
  func selectVideoQuality(videoQuality: VideoQuality)

  func setDidChangeProgress(closure:  @escaping WrapperProgressClosure)
  func setDidChangePlayerState(closure:  @escaping WrapperPlayerStateClosure)
  func setDidChangeAvailableVideoQualities(closure:  @escaping WrapperQualitiesClosure)
}
