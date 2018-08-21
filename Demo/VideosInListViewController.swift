//
//  VideosInListViewController.swift
//  Demo
//
//  Created by Sergei Mikhan on 8/21/18.
//  Copyright © 2018 Sergei Mikhan. All rights reserved.
//

import Astrolabe

class VideosInListViewController: UIViewController, Accessor {

  let containerView = CollectionView<CollectionViewSource>()

  typealias Video = CollectionCell<VideoCell>
  typealias Placeholder = CollectionCell<PlaceholderCell>

  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(containerView)
    source.hostViewController = self
    let cells: [Cellable] = [
      Video(data: ()),
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
}
