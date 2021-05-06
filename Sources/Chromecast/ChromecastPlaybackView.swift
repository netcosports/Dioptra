//
//  ChromecastPlaybackView.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 4/12/21.
//  Copyright © 2021 Netcosports. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

import Dioptra

import GoogleCast

public protocol ChromecastStatusApplier: AnyObject {

  func apply(status: GCKMediaStatus)
}

open class ChromecastPlaybackView: UIView, PlaybackViewModable {

  public let viewModel = ChromecastPlaybackViewModel()
  fileprivate let disposeBag = DisposeBag()

  public var placeholderView: (UIView & ChromecastStatusApplier)? = nil {
    willSet {
      self.placeholderView?.removeFromSuperview()
      if let placeholderView = newValue {
        self.addSubview(placeholderView)
        self.viewModel.mediaStatusRelay.subscribe(onNext: { [weak self] status in
          self?.placeholderView?.apply(status: status)
        }).disposed(by: disposeBag)
      }
      setNeedsLayout()
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .black
  }

  open override func layoutSubviews() {
    super.layoutSubviews()
    placeholderView?.frame = bounds
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open class var requiresConstraintBasedLayout: Bool {
    return false
  }
}
