import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    let appModel = AppClipWallet()
    var window: UIWindow?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = AppViewController(model: appModel)
        window?.makeKeyAndVisible()
        return true
    }
    
    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        guard
            userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let urlToOpen = userActivity.webpageURL
        else { return false }
        
        appModel.deeplink.clear()
        appModel.deeplink.push(url: urlToOpen)
        return true
    }
}
