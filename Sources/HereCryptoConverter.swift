
import Foundation
import BigInt
import NearSwift

public struct HereCryptoConverter: CryptoConverter {
    private let exp: UInt
    
    public init(_ exp: UInt) {
        self.exp = .init(exp)
    }
    
    private var multiplier: Decimal {
        Decimal(string: BigUInt(10).power(Int(exp)).description)!
    }
    
    public init(coin: CoinType) {
        self.exp = coin.yoctoCoinExp
    }
    
    public func toChainFormat(_ human: Decimal) -> BigUInt {
        let decimalResult = human * multiplier
        let roundedResult = decimalResult.rounded(scale: 0, roundingMode: .bankers)

        return BigUInt(roundedResult.description) ?? 0
    }
    
    public func toChainFormat(_ rawString: String) -> BigUInt? {
        BigUInt(stringLiteral: rawString)
    }
    public func toChainFormat(_ rawString: String) -> UInt128 {
        UInt128(stringLiteral: rawString)
    }
    
    public func toChainFormat(fiat: Decimal, course: Decimal) -> BigUInt {
        let humanFormat = fiat / course
        return toChainFormat(humanFormat)
    }
    
    public func toHumanFormat(_ chain: BigUInt) -> Decimal {
        let chain = Decimal(string: chain.description) ?? 0.0
        let rawResult = chain / multiplier
        return rawResult
    }
    
    public func toHumanFormat(_ chain: UInt128) -> Decimal {
        let chain = Decimal(string: chain.description) ?? 0.0
        let rawResult = chain / multiplier
        return rawResult
    }
    
    public func toHumanFormat(_ chain: String) -> Decimal? {
        guard let yctoNear: BigUInt = toChainFormat(chain) else { return nil }
        return toHumanFormat(yctoNear)
    }
    
    public func toFiat(amount: Decimal, course: Decimal) -> Decimal {
        (amount * course)
    }
    
}

public extension Decimal {
    func rounded(
        scale: Int,
        roundingMode: NSDecimalNumber.RoundingMode
    ) -> Decimal {
        var result = self
        var copySelf = self
        NSDecimalRound(&result, &copySelf, scale, roundingMode)
        
        return result
    }
}
