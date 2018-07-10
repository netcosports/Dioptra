//
//  DetailsViewController.swift
//  Demo
//
//  Created by Sergei Mikhan on 7/9/18.
//  Copyright © 2018 Sergei Mikhan. All rights reserved.
//

import UIKit
import Dioptra
import RxSwift

class DetailsViewController: UIViewController, Transitionable {

  var currentTransition: Transitionable.Transition?
  var customTransitionMethod = TransitionMethod.none
  var presentSubscribed = false
  var dismissSubscribed = false
  var disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return UIInterfaceOrientationMask.landscape
  }
}
