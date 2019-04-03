//
//  NSTVideoPlayerView.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 3/30/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxGesture

public protocol Detachable: class {
  var detached: Bool { get set }
  var detachOriginalPoint: CGPoint { get set }
  var detachDisposeBag: DisposeBag? { get set }
  func minimize()
  func compact()
}

extension Detachable where Self: UIView {

  public func detach(to view: UIView, with frame: CGRect) {
    guard detached == false else { return }
    guard let detachedOriginalContainer = view.superview else { return }
    self.detached = true
    let originalFrame = self.convert(self.bounds, to: view)
    view.addSubview(self)
    self.frame = originalFrame
    self.layoutSubviews()

    UIView.animate(withDuration: 0.27, animations: {
      self.frame = frame
      self.minimize()
      self.layoutSubviews()
    }, completion: { finished in
      self.registerForPanGeture()
    })
  }

  public func attach(to view: UIView, with frame: CGRect, overView: UIView) {
    guard detached == true else { return }
    let targetFrame = view.convert(frame, to: overView)
    let originalFrame = self.convert(self.bounds, to: overView)
    overView.addSubview(self)
    self.frame = originalFrame
    self.layoutSubviews()

    UIView.animate(withDuration: 0.27, animations: {
      self.frame = targetFrame
      //self.controlsView.viewModel.screenMode.accept(ScreenMode.compact)
      self.compact()
      self.layoutSubviews()
    }, completion: { finished in
      view.addSubview(self)
      self.frame = frame
      self.layoutSubviews()
      self.detached = false
      self.unregisterForPanGeture()
    })
  }

  fileprivate func registerForPanGeture() {
    let detachDisposeBag = DisposeBag()
    self.detachDisposeBag = detachDisposeBag

    let panGesture = self.rx.panGesture().share(replay: 1)
    panGesture.when(.began).subscribe(onNext: { [weak self] recognizer in
      guard let `self` = self else { return }
      self.detachOriginalPoint = self.center
    }).disposed(by: detachDisposeBag)
    panGesture.when(.changed).subscribe(onNext: { [weak self] recognizer in
      guard let `self` = self else { return }
      let translation = recognizer.translation(in: self.superview)
      let center = CGPoint(x: self.detachOriginalPoint.x + translation.x,
                           y: self.detachOriginalPoint.y + translation.y)
      self.center = center
    }).disposed(by: detachDisposeBag)
  }

  fileprivate func unregisterForPanGeture() {
    self.detachDisposeBag = nil
  }
}
