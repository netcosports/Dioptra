//
//  CompositePlaybackView.swift
//  Pods
//
//  Created by Sergei Mikhan on 15.04.21.
//

import UIKit
import RxSwift
import RxCocoa

public protocol CompositionSelectable: class {
  var firstActive: Bool { get set }
}

open class CompositePlaybackView<T1: PlaybackViewModable & UIView,
                                 T2: PlaybackViewModable & UIView>: UIView, PlaybackViewModable, CompositionSelectable
    where T1.ViewModel.Stream == T2.ViewModel.Stream {

  public typealias ViewModel = CompositePlaybackViewModel<T1.ViewModel, T2.ViewModel>

  public let firstPlaybackView = T1(frame: .zero)
  public let secondPlaybackView = T2(frame: .zero)
  public let viewModel: ViewModel

  public var firstActive = true {
    didSet {
      viewModel.firstActive = firstActive

      firstPlaybackView.isHidden = !firstActive
      secondPlaybackView.isHidden = firstActive

      if firstActive {
        firstPlaybackView.viewModel.state.onNext(.playing)
        secondPlaybackView.viewModel.state.onNext(.paused)
      } else {
        firstPlaybackView.viewModel.state.onNext(.paused)
        secondPlaybackView.viewModel.state.onNext(.playing)
      }
    }
  }

  fileprivate let disposeBag = DisposeBag()

  public override init(frame: CGRect) {
    self.viewModel = .init(
      firstPlayback: firstPlaybackView.viewModel,
      secondPlayback: secondPlaybackView.viewModel
    )
    super.init(frame: frame)

    self.addSubview(firstPlaybackView)
    self.addSubview(secondPlaybackView)
  }

  open override func layoutSubviews() {
    super.layoutSubviews()

    firstPlaybackView.frame = self.bounds
    secondPlaybackView.frame = self.bounds
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override open class var requiresConstraintBasedLayout: Bool {
    return false
  }
}

public extension Reactive where Base: CompositionSelectable {

  var firstActive: AnyObserver<Bool> {
    Binder<Bool>(base, binding: { target, value in
      target.firstActive = value
    }).asObserver()
  }
}

