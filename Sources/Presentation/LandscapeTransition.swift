import UIKit
import RxSwift
import RxCocoa
import RxGesture

public class LandscapeTransition: NSObject, UIViewControllerAnimatedTransitioning, PresentTransition {

  public var presentation = true
  public weak var transitionContext: UIViewControllerContextTransitioning?

  fileprivate weak var presentingView: UIView?
  fileprivate weak var dismissTarget: UIView?
  fileprivate var dismissTargetFrame: CGRect

  fileprivate var presentingOrientation = TransitionOrientation.current()

  public init(presentingView: UIView) {
    self.presentingView = presentingView
    self.dismissTarget = presentingView.superview
    if let window = presentingView.window {
      self.dismissTargetFrame = dismissTarget?.convert(presentingView.frame, to: window) ?? .zero
    } else {
      self.dismissTargetFrame = .zero
    }
    super.init()
  }

  open func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    return 0.36
  }

  // swiftlint:disable:next function_body_length
  open func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    guard let fromVC = transitionContext.viewController(forKey: .from) else { return }
    guard let toVC = transitionContext.viewController(forKey: .to) else { return }
    guard let presentingView = presentingView, let dismissTarget = dismissTarget else { return }

    let transition = TransitionOrientation.current()
    let screenBounds = UIScreen.main.bounds
    var correctBounds = screenBounds
    if screenBounds.height > screenBounds.width && presentation {
      correctBounds.size = CGSize(width: screenBounds.height, height: screenBounds.width)
    } else if screenBounds.height < screenBounds.width && !presentation {
      correctBounds.size = CGSize(width: screenBounds.height, height: screenBounds.width)
    }

    let containerView = transitionContext.containerView
    let startFrame = dismissTarget.convert(presentingView.frame, to: fromVC.view)
    let finalFrame = correctBounds
    var targetFrame = correctBounds
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
      switch transition {
      case .left:
        angle = -CGFloat.pi * 0.5
        midX = startFrame.midY
        midY = startFrame.midX
      case .right:
        angle = CGFloat.pi * 0.5
        midX = correctBounds.width - startFrame.midY
        midY = startFrame.midX
      default:
        angle = -CGFloat.pi * 0.5
        midX = startFrame.midY
        midY = startFrame.midX
      }
      let invertedSize = CGSize(width: correctBounds.height, height: correctBounds.width)
      fromVC.view.transform = CGAffineTransform.identity
      fromVC.view.bounds = CGRect(origin: .zero, size: invertedSize)
      fromVC.view.transform = CGAffineTransform(rotationAngle: angle)
    } else {
      midX = correctBounds.width * 0.5
      midY = correctBounds.height * 0.5
      targetView = dismissTarget
      targetFrame = dismissTargetFrame
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

    presentingView.setNeedsUpdateConstraints()
    presentingView.layoutIfNeeded()

    toVC.view.frame = finalFrame

    UIView.animate(withDuration: transitionDuration(using: transitionContext),
                   delay: 0, options: .curveEaseInOut, animations: {
                    presentingView.transform = CGAffineTransform.identity
                    presentingView.frame = targetFrame
                    presentingView.setNeedsUpdateConstraints()
                    presentingView.layoutIfNeeded()
    }) { _ in
      transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
      targetView.insertSubview(presentingView, at: 0)
      presentingView.frame = targetView.bounds
    }
  }
}

