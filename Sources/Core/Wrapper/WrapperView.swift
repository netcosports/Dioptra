//
//  WrapperView.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 12/24/19.
//

import UIKit
import RxSwift
import RxCocoa

open class WrapperView: UIView, PlaybackViewModable {

  public let viewModel = WrapperViewModel()
  let disposeBag = DisposeBag()
  public override init(frame: CGRect) {
    super.init(frame: frame)
    viewModel.wrapperInstanceRelay.subscribe(onNext: { [weak self] wrapper in
      guard let self = self, let wrapper = wrapper else { return }
      self.addSubview(wrapper.playerView)
    }).disposed(by: disposeBag)
  }
  
  open override func layoutSubviews() {
    super.layoutSubviews()
    self.subviews.forEach {
      $0.frame = self.bounds
    }
  }
  
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open class var requiresConstraintBasedLayout: Bool {
    return false
  }
}
