import Foundation

public struct Contacts: Codable {
    var contacts: [Person]
}

public struct Person: Hashable, Codable {
    public var isHereUser: Bool?
    public let address: String
    public let currency: CoinType
    
    public init(
        isHereUser: Bool = false,
        address: String = "",
        currency: CoinType = .NULL
    ) {
        self.isHereUser = isHereUser
        self.address = address
        self.currency = currency
    }
    
    enum CodingKeys: String, CodingKey {
        case isHereUser = "onWallet"
        case address = "accountId"
        case currency
    }
}
