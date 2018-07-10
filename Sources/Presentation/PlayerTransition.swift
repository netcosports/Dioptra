  //
//  PlayerTransition.swift
//  PSGOneApp
//
//  Created by Sergei Mikhan on 11/9/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxGesture
import SnapKit

public enum Transition {
  case left
  case right
  case portrait

  static func current() -> Transition {
    if UIDevice.current.orientation == .landscapeLeft {
      return .left
    }
    if UIDevice.current.orientation == .landscapeRight {
      return .right
    }
    return .portrait
  }
}

public protocol Compactable: class {
  var compact: Bool { get set }
}

public class PlayerTransition: NSObject, UIViewControllerAnimatedTransitioning, PresentTransition {

  public var presentation = true
  public weak var transitionContext: UIViewControllerContextTransitioning?

  fileprivate var presentingView: UIView
  fileprivate var dismissTarget: UIView?

  public init(presentingView: UIView) {
    self.presentingView = presentingView
    self.dismissTarget = presentingView.superview

    super.init()
  }

  open func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    return 0.36
  }

  // swiftlint:disable:next function_body_length
  open func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    guard let fromVC = transitionContext.viewController(forKey: .from) else { return }
    guard let toVC = transitionContext.viewController(forKey: .to) else { return }
    guard let dismissTarget = dismissTarget else { return }

    let containerView = transitionContext.containerView
    let startFrame = dismissTarget.convert(presentingView.frame, to: fromVC.view)
    let finalFrame = UIScreen.main.bounds
    var targetFrame = UIScreen.main.bounds
    let transition = Transition.current()
    let midX: CGFloat
    let midY: CGFloat
    let angle: CGFloat
    let targetView: UIView

    containerView.addSubview(fromVC.view)
    containerView.addSubview(toVC.view)
    containerView.addSubview(presentingView)

    if let compactableView = presentingView as? Compactable {
      compactableView.compact = !presentation
    }
    if presentation {
      targetView = toVC.view
      midY = startFrame.midX
      switch transition {
      case .left:
        angle = -CGFloat.pi * 0.5
        midX = startFrame.midY
      case .right:
        angle = CGFloat.pi * 0.5
        midX = UIScreen.main.bounds.width - startFrame.midY
      default:
        angle = CGFloat.pi * 0.5
        midX = UIScreen.main.bounds.width - startFrame.midY
      }
    } else {
      midX = UIScreen.main.bounds.width * 0.5
      midY = UIScreen.main.bounds.height * 0.5
      targetView = dismissTarget
      targetFrame = dismissTarget.superview?.convert(dismissTarget.frame, to: toVC.view) ?? .zero
      switch transition {
      case .left:
        angle = -3.0 * CGFloat.pi * 0.5
      case .right:
        angle = 3.0 * CGFloat.pi * 0.5
      default:
        angle = -3.0 * CGFloat.pi * 0.5
      }
    }

    presentingView.bounds.size = startFrame.size
    presentingView.center = CGPoint(x: midX, y: midY)
    toVC.view.frame = finalFrame
    presentingView.transform = CGAffineTransform(rotationAngle: angle)
    fromVC.view.transform = CGAffineTransform(rotationAngle: angle)

    UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .curveEaseInOut, animations: {
      // FIXME: need to manage frame manually
      self.presentingView.transform = CGAffineTransform.identity
      self.presentingView.snp.remakeConstraints { make in
        make.leading.equalToSuperview().offset(targetFrame.origin.x)
        make.top.equalToSuperview().offset(targetFrame.origin.y)
        make.width.equalTo(targetFrame.size.width)
        make.height.equalTo(targetFrame.size.height)
      }
      containerView.layoutIfNeeded()
    }) { _ in
      transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
      self.presentingView.removeFromSuperview()
      targetView.insertSubview(self.presentingView, at: 0)
      self.presentingView.snp.remakeConstraints { make in
        make.edges.equalToSuperview()
      }
      fromVC.view.layoutIfNeeded()
    }
  }
}

