@preconcurrency import ShopifyCheckoutSheetKit
import UIKit

func getLogLevel(key: String) -> LogLevel {
    guard
        let rawLogLevel = UserDefaults.standard.string(
            forKey: key
        ),
        let logLevel = LogLevel(rawValue: rawLogLevel)
    else { return .all }

    return logLevel
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _: UIApplication,
        willFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let checkoutSheetKitLogLevel: LogLevel = getLogLevel(
            key: AppStorageKeys.checkoutSheetKitLogLevel.rawValue
        )

        ShopifyCheckoutSheetKit.configure {
            $0.colorScheme = .automatic
            $0.tintColor = ColorPalette.primaryColor
            $0.preloading.enabled = true
            $0.logger = FileLogger("log.txt")
            $0.logLevel = checkoutSheetKitLogLevel
        }

        print("[MobileBuyIntegration] CheckoutSheetKit Log level set to \(checkoutSheetKitLogLevel)")

        UIBarButtonItem.appearance().tintColor = ColorPalette.primaryColor

        return true
    }

    func application(
        _: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
        options _: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default", sessionRole: connectingSceneSession.role)
    }
}
