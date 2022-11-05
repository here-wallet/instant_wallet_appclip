import Foundation
import CryptoKit

public enum NearAddress: Hashable {
    
    case raw(RawNearAddress)
    case named(NamedNearAddress)
    
    public var accountId: String {
        switch self {
        case .raw(let rawNearAddress):
            return rawNearAddress.address
        case .named(let namedNearAddress):
            return namedNearAddress.address
        }
    }
    
    public static func all(address: String) -> NearAddress? {
        let named = named(address: address)
        let raw = raw(address: address)
        
        if case let .success(named) = named {
            return .named(named)
        } else if case let .success(raw) = raw {
            return .raw(raw)
        } else {
            return nil
        }
    }
    
    static func raw(address: String) -> Result<RawNearAddress, [RawNearAddress.ParseError]> {
        RawNearAddress.parse(address: address)
    }
    static func named(address: String) -> Result<NamedNearAddress, [NamedNearAddress.ParseError]> {
        NamedNearAddress.parse(address: address)
    }
}

public struct RawNearAddress: Hashable {
    
    let address: String
    
    enum ParseError: CaseIterable, Error {
        case specialSymbols
        case length
    }
    
    static func parse(address: String) -> Result<RawNearAddress, [ParseError]> {
        let onlyCharAndNumber = address.range(of: ".*[^A-Za-z0-9].*", options: .regularExpression) == nil
        let rigthLength = address.count == 64
        
        let errors = ParseError.allCases
            .filter { error in
                switch error {
                case .specialSymbols: return !onlyCharAndNumber
                case .length: return !rigthLength
                }
            }
        
        return errors.isEmpty ? .success(.init(address: address)) : .failure(errors)
    }
}

public struct NamedNearAddress: Hashable {
    
    let address: String
    
    enum ParseError: CaseIterable, Error {
        case notMatchPattern
        case incorrectEnd
        case specialSymbols
        case length
    }
    
    static func parse(address: String) -> Result<NamedNearAddress, [ParseError]> {
        guard (2...64).contains(address.count) else {
            return .failure([.length])
        }
        let regexPattern: String = "^(([a-z\\d]+[-_])*[a-z\\d]+\\.)*([a-z\\d]+[-_])*[a-z\\d]+$"
        let correctPattern = address.range(of: regexPattern, options: .regularExpression) != nil
        
        let domain = AppInfo.shared.nearDomain
        let correctEnd = address.suffix(domain.count) == domain
        let withoutRestrictedSymbols = !(
            address.filter { $0 == "." }.count > 1 || address.contains("@")
        )
        
        let errors = ParseError.allCases
            .filter { error in
                switch error {
                case .notMatchPattern: return !correctPattern
                case .specialSymbols: return !withoutRestrictedSymbols
                case .incorrectEnd: return !correctEnd
                case .length: return false
                }
            }
        
        return errors.isEmpty ? .success(.init(address: address)) : .failure(errors)
    }
}
