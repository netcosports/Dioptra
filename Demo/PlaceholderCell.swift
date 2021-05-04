//
//  PlaceholderCell.swift
//  Demo
//
//  Created by Sergei Mikhan on 8/21/18.
//  Copyright © 2018 Sergei Mikhan. All rights reserved.
//

import Astrolabe

class PlaceholderCell: CollectionViewCell, Reusable {

  let label: UILabel = {
    let label = UILabel()
    label.text = "PLACEHOLDER"
    label.textAlignment = .center
    label.textColor = .black
    return label
  }()

  override func setup() {
    super.setup()
    contentView.addSubview(label)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    label.frame = bounds
  }

  typealias Data = Void
  static func size(for data: Data, containerSize: CGSize) -> CGSize {
    return CGSize(width: containerSize.width, height: containerSize.width / 3.0)
  }
}
