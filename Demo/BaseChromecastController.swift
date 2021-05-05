//
//  BaseChromecastController.swift
//  Demo
//
//  Created by Sergei Mikhan on 14.04.21.
//

import GoogleCast
import UIKit

class BaseChromecastController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    let castButton = GCKUICastButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
    castButton.tintColor = .darkGray
    navigationItem.rightBarButtonItem = UIBarButtonItem(customView: castButton)
  }
}

