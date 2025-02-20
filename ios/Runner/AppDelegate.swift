import Flutter
import UIKit
import FirebaseCore
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      FirebaseApp.configure()
      //added
      FlutterLocalNotificationsPlugin.setPluginRegistrantCallback{ (registry) in
      GeneratedPluginRegistrant.register(with: registry)}
      //end of added
    GeneratedPluginRegistrant.register(with: self)

      //added
      if #available(iOS 10.0, *) {
        UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
      }
      //end of added
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
