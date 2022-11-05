import Foundation
import UIKit

public struct HTTPHeader: Hashable {
    public let name: String
    public let value: String
    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
    
    public static func userAgent(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "User-Agent", value: value)
    }
    
    public static func acceptLanguage(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Accept-Language", value: value)
    }
    
    public static func acceptEncoding(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Accept-Encoding", value: value)
    }
    
    public static func timezone(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Timezone", value: value)
    }
    
    public static func contentType(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Content-Type", value: value)
    }
    
    public static func accept(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Accept", value: value)
    }
}


extension HTTPHeader {
    
    public static let `default`: [HTTPHeader] = [
        .defaultAcceptEncoding,
        .defaultAcceptLanguage,
        .defaultAccept,
        .defaultContentType,
        .defaultUserAgent,
        .timezone
    ]
    
    public static let defaultUserAgent: HTTPHeader = {
        let appName = AppInfo.shared.appName
        let bundle = AppInfo.shared.bundleIdentifier
        let appVersion = AppInfo.shared.version
        let appBuild = AppInfo.shared.build

        let osNameVersion: String = {
            let version = ProcessInfo.processInfo.operatingSystemVersion
            let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
            let osName: String = UIDevice.current.systemName

            return "\(osName) \(versionString)"
        }()

        let userAgent = "\(appName)/\(appVersion) (\(bundle); build:\(appBuild); \(osNameVersion))"

        return .userAgent(userAgent)
    }()
    
    public static let defaultAcceptEncoding: HTTPHeader = {
        let encodings: [String]
        if #available(iOS 11.0, macOS 10.13, tvOS 11.0, watchOS 4.0, *) {
            encodings = ["br", "gzip", "deflate"]
        } else {
            encodings = ["gzip", "deflate"]
        }

        return .acceptEncoding(encodings.qualityEncoded())
    }()
    
    public static let defaultAcceptLanguage: HTTPHeader = .acceptLanguage(Locale.preferredLanguages.prefix(6).qualityEncoded())

    public static let defaultAccept: HTTPHeader = .accept("application/json")
    public static let defaultContentType: HTTPHeader = .contentType("application/json")
    
    public static let timezone: HTTPHeader = .timezone(TimeZone.autoupdatingCurrent.identifier)
}

extension Collection where Element == String {
    func qualityEncoded() -> String {
        enumerated().map { index, encoding in
            let quality = 1.0 - (Double(index) * 0.1)
            return "\(encoding);q=\(quality)"
        }.joined(separator: ", ")
    }
}
