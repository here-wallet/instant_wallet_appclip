import Foundation
import UIKit

public extension String {
    var decimalValue: Decimal? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .init(identifier: "en_US")
        let clean = String(self.map { $0 == "," ? "." : $0 })
        return formatter.number(from: clean)?.decimalValue
    }
    
    static func random(len: Int = 8) -> String {
        let letters: NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomString: NSMutableString = NSMutableString(capacity: len)

        for _ in 1...len {
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.character(at: Int(rand)))
        }

        return String(randomString)
    }
}

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

public extension Data {
    static func random(length: Int) throws -> Data {
        return Data((0 ..< length).map { _ in UInt8.random(in: UInt8.min ... UInt8.max) })
    }
}

public extension UIDevice {
    static let modelIdentifier: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }()
}
