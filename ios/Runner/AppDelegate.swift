import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Required by google_maps_flutter (LocationScreen). This key has "Maps SDK
    // for iOS" enabled; restrict it to this app's bundle id in Google Cloud.
    GMSServices.provideAPIKey("AIzaSyBn2KZPZa4KlkMSxVKkeNcWErtEeFeeclI")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
