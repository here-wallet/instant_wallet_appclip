
import Foundation
import NearSwift

// MARK: - FtOverviewToken
public struct FtOverviewToken: Codable, Hashable {
    public let name, symbol, icon, contractId: String
    public let currency: Int
    public let tokenId: UInt
    public let description: String
    public let decimal: UInt
    public var amount: Decimal
    public let usdRate, usdRateYesterday: Decimal
    
    public var value: UInt128 {
        let converter = HereCryptoConverter(decimal)
        let value = converter.toChainFormat(amount)
        return UInt128(stringLiteral: value.description)
    }
    
    public var fiatAmount: Decimal {
        (amount * usdRate).rounded(scale: 2, roundingMode: .bankers)
    }

    mutating public func setAmount(_ amount: Decimal) {
        let converter = HereCryptoConverter(decimal)
        let amount: Decimal = converter.toHumanFormat(amount.description) ?? 0
        self.amount = amount.rounded(scale: 6, roundingMode: .bankers)
    }
    
    mutating public func setAmount(_ amount: UInt128) {
        let converter = HereCryptoConverter(decimal)
        let amount: Decimal = converter.toHumanFormat(amount.description) ?? 0
        self.amount = amount
    }

    public var image: Data? {
        if let dirURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dirURL.appendingPathComponent("\(contractId).png")
            if let data = try? Data(contentsOf: fileURL) {
                return data
            }
        }
        guard let data = NSCache.logoCache.object(forKey: symbol as NSString) else { return nil }
        return Data(referencing: data)
    }
    
    public var asyncImage: Data {
        get async {
            guard let data = await loadImage().value else { return .init() }
            let nsData = NSData(data: data)
            NSCache.logoCache.setObject(nsData, forKey: symbol as NSString)
            if let dirURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = dirURL.appendingPathComponent("\(contractId).png")
                _ = try? data.write(to: fileURL, options: [.atomic])
            }
            return data
        }
    }
    
    private func loadImage() -> Task<Data?, Never> {
        return Task(priority: .userInitiated) {
            guard let url = URL(string: icon) else { return nil }
            return try? Data(contentsOf: url)
        }
    }
}

public extension NSCache where KeyType == NSString, ObjectType == NSData {
    static let logoCache: NSCache = .init()
}
