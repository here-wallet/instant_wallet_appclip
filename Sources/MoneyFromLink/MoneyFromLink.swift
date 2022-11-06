import Foundation
import NearSwift
import Combine
import CryptoKit
import Base58Swift

public enum MoneyFromLinkModelState: String {
    case loading
    case success
    case failure
}

public enum LinkDropType: Equatable {
    case partner(_ key: String)
    case link(_ key: String)
}

public class MoneyFromLinkModel {
    private let userSession: UserSession
    private let api: PhoneTransferWebRepository = .init()
    private let key: LinkDropType
    
    @Published
    private var state: MoneyFromLinkModelState = .loading
    public var statePublisher: AnyPublisher<MoneyFromLinkModelState, Never> {
        $state.eraseToAnyPublisher()
    }
    
    public init(key: LinkDropType, userSession: UserSession) {
        self.userSession = userSession
        self.key = key
    }
    
    public func receiveMoney() async {
        switch key {
        case let .link(key): await receiveLink(key: key)
        case let .partner(key): await receivePartner(key: key)
        }
    }
    
    private func receivePartner(key: String) async {
        state = .loading
        do {
            try await api.partnerDrop(key: key)
            state = .success
        } catch {
            print("receivePartner", error)
            state = .failure
        }
    }
    
    private func receiveLink(key:String) async {
        state = .loading
        do {
            guard let keyData = Base58.base58Decode(key)
            else { throw "Key decode error" }
            
            let hash = SHA256.hash(data: keyData)
            let requestId = Base58.base58Encode(hash.bytes)

            let account = userSession.userProfile.account
            _ = try await account.functionCall(
                contractId: "l.herewallet.near",
                methodName: "receive_transfer",
                args: [
                    "key": key,
                    "request_id": requestId,
                    "account_id": account.address
                ],
                gas: nil,
                amount: 0
            )
            
            state = .success
        } catch {
            state = .failure
        }
    }
}
