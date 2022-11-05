
import Foundation

public struct BIP70: Equatable {
    public enum ParsingError: Error, Equatable {
        case notSupported
    }
    
    public let coin: CoinType
    public let address: String
    public let amount: String?
    
    public init(
        coin: CoinType,
        address: String,
        amount: String?
    ) {
        self.coin = coin
        self.address = address
        self.amount = amount
    }
    
    public static func parse(from urlComponents: URLComponents) -> Result<BIP70, ParsingError> {
        guard
            !urlComponents.path.isEmpty,
            let scheme = urlComponents.scheme
        else {
            return .failure(.notSupported)
        }
        
        switch scheme {
        case "bitcoin":
            let amount = urlComponents.queryItems?.first { $0.name == "amount" }?.value
            let bip70 = BIP70(coin: .BITCOIN, address: urlComponents.path, amount: amount)
            return .success(bip70)
        case "near":
            let amount = urlComponents.queryItems?.first { $0.name == "amount" }?.value
            let bip70 = BIP70(coin: .NEAR, address: urlComponents.path, amount: amount)
            return .success(bip70)
        default:
            return .failure(.notSupported)
        }
    }
}


