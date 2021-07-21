//
//  BufferedSlider.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 4/4/17.
//  Copyright © 2017 Netcosports. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

open class BufferedSlider: UISlider {

  public enum VerticalPosition {
    case top
    case center
    case bottom
  }

  open var padding: CGFloat = 0

  open var bufferStartValue: Double = 0 {
    didSet {
      if bufferStartValue < 0.0 {
        bufferStartValue = 0
      }
      if bufferStartValue > bufferEndValue {
        bufferStartValue = bufferEndValue
      }
      self.setNeedsDisplay()
    }
  }

  open var bufferEndValue: Double = 0 {
    didSet {
      if bufferEndValue > 1.0 {
        bufferEndValue = 1
      }
      if bufferEndValue < bufferStartValue {
        bufferEndValue = bufferStartValue
      }
      self.setNeedsDisplay()
    }
  }

  open var baseColor: UIColor = UIColor.lightGray
  open var progressColor: UIColor?
  open var bufferColor: UIColor?

  open var borderWidth: Double = 0.5 {
    didSet {
      if borderWidth < 0.1 {
        borderWidth = 0.1
      }
      self.setNeedsDisplay()
    }
  }

  open var sliderHeight: Double = 1 {
    didSet {
      if sliderHeight < 1 {
        sliderHeight = 1
      }
    }
  }

  open var sliderPosition: VerticalPosition = .center

  open var roundedSlider: Bool = true

  open var hollow: Bool = true

  public let centerView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 5.0, height: 5.0))
  private var thumWidth: CGFloat = 0.0

  public override init(frame: CGRect) {
    super.init(frame: frame)
    addSubview(centerView)
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  ///Do not call this delegate mehtod directly. This is for hiding built-in slider drawing
  open override func trackRect(forBounds bounds: CGRect) -> CGRect {
    var result = super.trackRect(forBounds: bounds)
    result.size.height = 0.01
    return result
  }
  
  open override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
    var result = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
    if result.width > 0.0 {
      thumWidth = result.width
    }
    centerView.frame.origin.x = result.origin.x + thumWidth / 2.0 - centerView.frame.width / 2.0
    result.origin.y = 0.5 * (frame.height - result.height) + 1.0// shadow
    return result
  }

  open override func draw(_ rect: CGRect) {
    baseColor.set()

    let rect = self.bounds.insetBy(dx: CGFloat(borderWidth) + padding, dy: CGFloat(borderWidth))
    let height = sliderHeight.CGFloatValue
    let radius = height/2
    var sliderRect = CGRect(x: rect.origin.x, y: rect.origin.y + (rect.height/2-radius), width: rect.width, height: height) //default center
    switch sliderPosition {
    case .top:
      sliderRect.origin.y = rect.origin.y
    case .bottom:
      sliderRect.origin.y = rect.origin.y + rect.height - sliderRect.height
    default:
      break
    }

    let path = UIBezierPath()
    if roundedSlider {
      path.addArc(withCenter: CGPoint(x: sliderRect.minX + radius, y: sliderRect.minY+radius),
                  radius: radius, startAngle: CGFloat.pi / 2, endAngle: -CGFloat.pi / 2, clockwise: true)
      path.addLine(to: CGPoint(x: sliderRect.maxX-radius, y: sliderRect.minY))
      path.addArc(withCenter: CGPoint(x: sliderRect.maxX-radius, y: sliderRect.minY+radius),
                  radius: radius, startAngle: -CGFloat.pi / 2, endAngle: CGFloat.pi / 2, clockwise: true)
      path.addLine(to: CGPoint(x: sliderRect.minX + radius, y: sliderRect.minY+height))
    } else {
      path.move(to: CGPoint(x: sliderRect.minX, y: sliderRect.minY+height))
      path.addLine(to: sliderRect.origin)
      path.addLine(to: CGPoint(x: sliderRect.maxX, y: sliderRect.minY))
      path.addLine(to: CGPoint(x: sliderRect.maxX, y: sliderRect.minY+height))
      path.addLine(to: CGPoint(x: sliderRect.minX, y: sliderRect.minY+height))
    }

    baseColor.setStroke()
    path.lineWidth = borderWidth.CGFloatValue
    path.stroke()
    if !hollow {
      path.fill()
    }
    path.addClip()

    var fillHeight = sliderRect.size.height-borderWidth.CGFloatValue
    if fillHeight < 0 {
      fillHeight = 0
    }

    let fillRect = CGRect(
      x: sliderRect.origin.x + sliderRect.size.width*CGFloat(bufferStartValue),
      y: sliderRect.origin.y + borderWidth.CGFloatValue/2,
      width: sliderRect.size.width*CGFloat(bufferEndValue-bufferStartValue),
      height: fillHeight)
    if let color = bufferColor {
      color.setFill()
    } else if let color = self.superview?.tintColor {
      color.setFill()
    } else {
      UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0).setFill()
    }

    UIBezierPath(rect: fillRect).fill()

    if let color = progressColor {
      color.setFill()
      let fillRect = CGRect(
        x: sliderRect.origin.x,
        y: sliderRect.origin.y + borderWidth.CGFloatValue/2,
        width: sliderRect.size.width*CGFloat((value-minimumValue)/(maximumValue-minimumValue)),
        height: fillHeight)
      UIBezierPath(rect: fillRect).fill()
    }
  }

  override open class var requiresConstraintBasedLayout: Bool {
    return false
  }
}

public extension Reactive where Base: BufferedSlider {

  public var buffer: ControlProperty<Float> {
    return base.rx.controlProperty(editingEvents: UIControl.Event.allEvents, getter: { slider in
      return Float(slider.bufferEndValue)
    }, setter: { slider, buffer in
      slider.bufferStartValue = 0.0
      slider.bufferEndValue = Double(buffer)
      slider.setNeedsDisplay()
    })
  }

  public var bufferedValue: ControlProperty<Float> {
    return base.rx.controlProperty(editingEvents: UIControl.Event.allEvents, getter: { slider in
      return slider.value
    }, setter: { slider, value in
      slider.value = value
      slider.setNeedsDisplay()
    })
  }
}

extension CGFloat {

  static var pixel: CGFloat {
    return 1.0 / UIScreen.main.scale
  }
}

extension Double {

  var CGFloatValue: CGFloat {
    return CGFloat(self)
  }
}
