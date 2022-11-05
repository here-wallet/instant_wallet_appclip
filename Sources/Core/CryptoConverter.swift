import Foundation
import BigInt
import NearSwift

public protocol CryptoConverter: Hashable {
    init(coin: CoinType)
    
    func toChainFormat(_ human: Decimal) -> BigUInt
    func toChainFormat(_ human: Decimal) -> UInt128
    func toChainFormat(_ rawString: String) -> BigUInt?
    func toChainFormat(_ rawString: String) -> UInt128
    func toChainFormat(fiat: Decimal, course: Decimal) -> BigUInt
    func toChainFormat(fiat: Decimal, course: Decimal) -> UInt128
    func toHumanFormat(_ chain: BigUInt) -> Decimal
    func toHumanFormat(_ chain: UInt128) -> Decimal
    func toHumanFormat(_ chain: String) -> Decimal?
    func toFiat(amount: Decimal, course: Decimal) -> Decimal
}

extension CryptoConverter {
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        return true
    }
    
    public func toChainFormat(_ human: Decimal) -> UInt128 {
        let big: BigUInt = self.toChainFormat(human)
        return self.toChainFormat(big.description)
    }
    
    public func toChainFormat(fiat: Decimal, course: Decimal) -> UInt128 {
        let buint: BigUInt = self.toChainFormat(fiat: fiat, course: course)
        return .init(stringLiteral: buint.description)
    }
}

