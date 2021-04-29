//
//  VideosInListViewController.swift
//  Demo
//
//  Created by Sergei Mikhan on 8/21/18.
//  Copyright © 2018 Sergei Mikhan. All rights reserved.
//

import Astrolabe
import Dioptra
import RxSwift

class VideosInListViewController: BaseChromecastController, Accessor, Transitionable {

  var currentTransition: Transitionable.Transition?
  var customTransitionMethod = TransitionMethod.none
  var presentSubscribed = false
  var dismissSubscribed = false
  var disposeBag = DisposeBag()

  var sections: [Sectionable] {
    get {
      return source.sections
    }

    set {
      source.sections = newValue
    }
  }

  let containerView = CollectionView<CollectionViewSource>()

  typealias Video = CollectionCell<VideoCell>
  typealias ConstraintsVideo = CollectionCell<ConstraintsVideoCell>
  typealias Placeholder = CollectionCell<PlaceholderCell>

  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(containerView)
    source.hostViewController = self
    let cells: [Cellable] = [
      Video(data: ()),
      //ConstraintsVideo(data: ()),
      Placeholder(data: ()),
      Placeholder(data: ()),
      Placeholder(data: ()),
      Placeholder(data: ()),
      Placeholder(data: ()),
      Placeholder(data: ()),
      Placeholder(data: ()),
      Placeholder(data: ()),
      Placeholder(data: ()),
      Placeholder(data: ()),
      Placeholder(data: ()),
      Placeholder(data: ()),
      Placeholder(data: ()),
      Placeholder(data: ()),
      Placeholder(data: ()),
      Placeholder(data: ()),
      Placeholder(data: ()),
      Placeholder(data: ()),
      Placeholder(data: ()),
      Placeholder(data: ()),
      Placeholder(data: ())
    ]

    containerView.source.sections = [Section(cells: cells)]
    containerView.reloadData()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    containerView.frame = view.bounds
  }

  func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {

    return presentTransition() { [weak presented] in
      presented?.dismiss(animated: true)
    }
  }

  override var prefersStatusBarHidden: Bool {
    return true
  }

  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return .portrait
  }

  func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    return dismissTransition
  }
}
