//
//  AppDelegate.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 4/3/18.
//  Copyright © 2018 Sergei Mikhan. All rights reserved.
//

import UIKit

import AVKit

import GoogleCast

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GCKLoggerDelegate {

  var window: UIWindow?

  let kReceiverAppID = "0CAF644C"
  let kDebugLoggingEnabled = true

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback)
      try AVAudioSession.sharedInstance().setMode(.moviePlayback)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print("ttt error \(error)")
    }

    // Set your receiver application ID.
    let criteria = GCKDiscoveryCriteria(applicationID: kReceiverAppID)
    let options = GCKCastOptions(discoveryCriteria: criteria)
    options.physicalVolumeButtonsWillControlDeviceVolume = true

    // Following code enables Cast Connect
     let launchOptions = GCKLaunchOptions()
     launchOptions.androidReceiverCompatible = true
     options.launchOptions = launchOptions

    GCKCastContext.setSharedInstanceWith(options)
    GCKCastContext.sharedInstance().setLaunch(GCKCredentialsData(credentials: "{\"userId\": \"123\"}"))
    // Configure widget styling.
    // Theme using UIAppearance.
    UINavigationBar.appearance().barTintColor = .lightGray
    let colorAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
    UINavigationBar().titleTextAttributes = colorAttributes
    GCKUICastButton.appearance().tintColor = .gray

    // Theme using GCKUIStyle.
    let castStyle = GCKUIStyle.sharedInstance()
    // Set the property of the desired cast widgets.
    castStyle.castViews.deviceControl.buttonTextColor = .darkGray
    // Refresh all currently visible views with the assigned styles.
    castStyle.apply()

    // Enable default expanded controller.
    GCKCastContext.sharedInstance().useDefaultExpandedMediaControls = true

    // Enable logger.
    GCKLogger.sharedInstance().delegate = self

    // Set logger filter.
    let filter = GCKLoggerFilter()
    filter.minimumLevel = .error
    GCKLogger.sharedInstance().filter = filter

    let controller = VideosInListViewController()
    let navigation = UINavigationController(rootViewController: controller)

    window = UIWindow(frame: UIScreen.main.bounds)
    window?.rootViewController = navigation
    window?.makeKeyAndVisible()

    return true
  }

  // MARK: - GCKLoggerDelegate
  func logMessage(_ message: String,
                  at _: GCKLoggerLevel,
                  fromFunction function: String,
                  location: String) {
    if kDebugLoggingEnabled {
      print("\(location): \(function) - \(message)")
    }
  }
}

