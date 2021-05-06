//
//  AppDelegate.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 4/3/18.
//  Copyright © 2018 Sergei Mikhan. All rights reserved.
//

import UIKit

import AVKit

import Dioptra
import Dioptra_Chromecast

import GoogleCast

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GCKLoggerDelegate {

  var window: UIWindow?
  let kReceiverAppID = "0CAF644C"

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback)
      try AVAudioSession.sharedInstance().setMode(.moviePlayback)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print("ttt error \(error)")
    }

    ChromecastManager.shared.initialize(with: kReceiverAppID)

    let controller = VideosInListViewController()
    let navigation = UINavigationController(rootViewController: controller)

    window = UIWindow(frame: UIScreen.main.bounds)
    window?.rootViewController = navigation
    window?.makeKeyAndVisible()

    return true
  }
}

