import Foundation

public struct AppInfo {
    public static let shared: AppInfo = .init()
    
    public var appName : String {
        return readFromInfoPlist(withKey: "CFBundleName") ?? "Unknown"
    }
    
    public var version : String {
        return readFromInfoPlist(withKey: "CFBundleShortVersionString") ?? "Unknown"
    }
    
    public var build : String {
        return readFromInfoPlist(withKey: "CFBundleVersion") ?? "Unknown"
    }
    
    public var bundleIdentifier : String {
        return readFromInfoPlist(withKey: "CFBundleIdentifier") ?? "Unknown"
    }
    
    public var hereHost : String {
        return "api.herewallet.app"
    }
    
    public var hereContract : String {
        return "storage.herewallet.near"
    }
    
    public var nearRpc : URL {
        return URL(string: "https://rpc.mainnet.near.org")!
    }
    
    public var nearWallet : String {
        return "wallet.near.org"
    }
    
    public var nearNetwork : String {
        return "default"
    }

    public var nearDomain : String {
        switch AppInfo.shared.nearNetwork {
        case "default", "mainnet": return ".near"
        case "testnet": return ".testnet"
        default: return ".near"
        }
    }

    // lets hold a reference to the Info.plist of the app as Dictionary
    private let infoPlistDictionary = Bundle.main.infoDictionary
    
    /// Retrieves and returns associated values (of Type String) from info.Plist of the app.
    private func readFromInfoPlist(withKey key: String) -> String? {
        return infoPlistDictionary?[key] as? String
    }
}
