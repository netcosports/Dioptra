//
//  ChromecastManager.swift
//  Dioptra
//
//  Created by Sergei Mikhan on 30.04.21.
//

import GoogleCast

public class ChromecastManager: NSObject {

  let kDebugLoggingEnabled = true

  private override init() {
    super.init()
  }

  public static var shared = ChromecastManager()

  public func initialize(with receiverAppID: String) {
    let criteria = GCKDiscoveryCriteria(applicationID: receiverAppID)
    let options = GCKCastOptions(discoveryCriteria: criteria)
    options.physicalVolumeButtonsWillControlDeviceVolume = true

    let launchOptions = GCKLaunchOptions()
    launchOptions.androidReceiverCompatible = true
    options.launchOptions = launchOptions

    GCKCastContext.setSharedInstanceWith(options)
    GCKCastContext.sharedInstance().setLaunch(GCKCredentialsData(credentials: "{\"userId\": \"123\"}"))

    UINavigationBar.appearance().barTintColor = .lightGray
    let colorAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
    UINavigationBar().titleTextAttributes = colorAttributes
    GCKUICastButton.appearance().tintColor = .gray

    let castStyle = GCKUIStyle.sharedInstance()
    castStyle.castViews.deviceControl.buttonTextColor = .white
    castStyle.apply()

    GCKCastContext.sharedInstance().useDefaultExpandedMediaControls = false

    GCKLogger.sharedInstance().delegate = self
    let filter = GCKLoggerFilter()
    filter.minimumLevel = .error
    GCKLogger.sharedInstance().filter = filter
  }
}

// MARK: - GCKLoggerDelegate
extension ChromecastManager: GCKLoggerDelegate {

  public func logMessage(_ message: String,
                  at _: GCKLoggerLevel,
                  fromFunction function: String,
                  location: String) {
    if kDebugLoggingEnabled {
      print("\(location): \(function) - \(message)")
    }
  }
}
