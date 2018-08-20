//
//  LandscapeTransition.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 11/9/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxGesture

public class LandscapeTransition: NSObject, UIViewControllerAnimatedTransitioning, PresentTransition {

  public var presentation = true
  public weak var transitionContext: UIViewControllerContextTransitioning?

  fileprivate var presentingView: UIView
  fileprivate var dismissTarget: UIView?
  fileprivate var presentingOrientation = TransitionOrientation.current()

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
    let transition = TransitionOrientation.current()
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
      presentingOrientation = TransitionOrientation.current()
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
        switch presentingOrientation {
          case .left: angle = CGFloat.pi * 0.5
          case .right: angle = -CGFloat.pi * 0.5
          default: angle = -3.0 * CGFloat.pi * 0.5
        }
      }
    }

    presentingView.bounds.size = startFrame.size
    presentingView.center = CGPoint(x: midX, y: midY)
    presentingView.transform = CGAffineTransform(rotationAngle: angle)
    self.presentingView.layoutIfNeeded()
    toVC.view.frame = finalFrame

    UIView.animate(withDuration: transitionDuration(using: transitionContext),
                   delay: 0, options: .curveEaseInOut, animations: {
      self.presentingView.transform = CGAffineTransform.identity
      self.presentingView.frame = targetFrame
      self.presentingView.layoutIfNeeded()
    }) { _ in
      transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
      targetView.insertSubview(self.presentingView, at: 0)
      self.presentingView.frame = targetView.bounds
    }
  }
}

