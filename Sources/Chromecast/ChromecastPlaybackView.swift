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

import GoogleCast

open class ChromecastPlaybackView: UIView, PlaybackViewModable {

  public let viewModel = ChromecastPlaybackViewModel()
  fileprivate let disposeBag = DisposeBag()

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .orange
  }

  open override func layoutSubviews() {
    super.layoutSubviews()
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open class var requiresConstraintBasedLayout: Bool {
    return false
  }
}
