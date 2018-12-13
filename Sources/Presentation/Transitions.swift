//
//  Transitions.swift
//  PSGOneApp
//
//  Created by Sergei Mikhan on 11/10/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxGesture

public protocol TransitionableMethod {
  var transition: Transitionable.Transition? { get }
}

public enum TransitionMethod: TransitionableMethod {
  case none
  case landscape(presentingView: UIView)
  case fullscreen(presentingView: UIView)

  public var transition: Transitionable.Transition? {
    switch self {
    case .landscape(let presentingView):
      return LandscapeTransition(presentingView: presentingView)
    case .fullscreen(let presentingView):
      return FullscreenTransition(presentingView: presentingView)
    case .none:
      return nil
    }
  }
}

public enum InteractiveTransitionDirection {
  case horizontal
  case vertical
}

public protocol PresentTransition: class {
  var presentation: Bool { get set }
  weak var transitionContext: UIViewControllerContextTransitioning? { get set }
}

public protocol InteractiveTransition: class {
  var interactiveTransition: UIPercentDrivenInteractiveTransition? { set get }
  var dismissGesture: ControlEvent<UIPanGestureRecognizer>? { get }
  var presentGesture: ControlEvent<UIPanGestureRecognizer>? { get }
  var direction: InteractiveTransitionDirection { get set }
  var cancelPop: Bool { get set }
  var interacting: Bool { get set }
  
  func slideTransition(recognizer: UIPanGestureRecognizer)
}

public protocol Pannable: class {
  var panView: UIView? { get }
}

public protocol Transitionable: UIViewControllerTransitioningDelegate, UINavigationControllerDelegate {
  typealias Transition = PresentTransition & UIViewControllerAnimatedTransitioning

  var currentTransition: Transition? { get set }
  var customTransitionMethod: TransitionMethod { get set }
  var presentSubscribed: Bool { get set }
  var dismissSubscribed: Bool { get set }
  var disposeBag: DisposeBag { get }
}

public enum TransitionOrientation {
  case left
  case right
  case portrait

  static func current() -> TransitionOrientation {
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

extension InteractiveTransition where Self: PresentTransition  {

  public func slideTransition(recognizer: UIPanGestureRecognizer) {

    if presentation && presentGesture == nil { return }
    if !presentation && dismissGesture == nil { return }

    guard let transitionContext = transitionContext else { return }
    guard let fromVC = transitionContext.viewController(forKey: .from) else { return }
    guard let view = fromVC.view else { return }
    guard let interactiveTransition = interactiveTransition else { return }

    let percent: CGFloat
    
    switch direction {
    case .vertical:
      let translationY = recognizer.translation(in: view).y
      let offsetY = presentation ? -translationY : translationY
      percent = min(1.0, max(0, offsetY / view.bounds.size.height))
    case .horizontal:
      let offsetX: CGFloat = recognizer.translation(in: view).x
      percent = min(1.0, max(0, offsetX / view.bounds.size.width))
    }

    switch recognizer.state {
    case .began :
      interacting = true
    case .changed :
      interacting = true
      interactiveTransition.update(percent)
    default :
      interacting = false
      if percent > 0.3 {
        cancelPop = false
        interactiveTransition.finish()
      } else {
        cancelPop = true
        interactiveTransition.cancel()
      }
      self.interactiveTransition = nil
    }
  }
}

extension Transitionable where Self: UIViewController {

  public func presentTransition(interactionStarted: (()->(Void))? = nil) -> Transitionable.Transition? {
    currentTransition?.presentation = true

    if let transition = currentTransition as? InteractiveTransition {
      if let presentGesture = transition.presentGesture {
        transition.interactiveTransition = UIPercentDrivenInteractiveTransition()
        if !presentSubscribed {
          presentSubscribed = true
          presentGesture.subscribe(onNext: { [weak self] recognizer in
            guard let transition = self?.currentTransition as? InteractiveTransition else { return }
            if recognizer.state == .possible { return }
            transition.slideTransition(recognizer: recognizer)
          }).disposed(by: disposeBag)
        }
      }

      if let dismissGesture = transition.dismissGesture, !dismissSubscribed {
        dismissSubscribed = true
        dismissGesture.subscribe(onNext: { [weak self] recognizer in
          guard let transition = self?.currentTransition as? InteractiveTransition else { return }

          if recognizer.state == .possible { return }
          if recognizer.state == .began {
            transition.interactiveTransition = UIPercentDrivenInteractiveTransition()
            interactionStarted?()
          }
          transition.slideTransition(recognizer: recognizer)
        }, onDisposed: { [weak self] in
          self?.dismissSubscribed = false
        }).disposed(by: disposeBag)
      }
    }
    return currentTransition
  }

  public var dismissTransition: Transitionable.Transition? {
    if let currentTransition = currentTransition {
      currentTransition.presentation = false
      return currentTransition
    }
    assertionFailure("we should have transition in this case")
    return nil
  }

  public func present(modal viewController: UIViewController, method: TransitionableMethod, completion: (()->Void)? = nil) {
    currentTransition = method.transition
    viewController.transitioningDelegate = self
    if let navigationController = navigationController {
      navigationController.present(viewController, animated: true, completion: completion)
    } else {
      present(viewController, animated: true, completion: completion)
    }
  }

  public func push(viewController: UIViewController, method: TransitionableMethod) {
    if let navigationController = navigationController {
      currentTransition = method.transition

      navigationController.delegate = self
      navigationController.pushViewController(viewController, animated: true)
    }
  }
}
