import Foundation
import Combine
import NearSwift
import HDWallet

public class UserSession: ObservableObject {
    @Published public private(set) var userProfile: UserProfile
    @Published public private(set) var todayPrice: Decimal?
    @Published public private(set) var tokens: [FtOverviewToken] = []
    @Published public private(set) var apy: Decimal?

    private let keyStore = HereKeychain()
    private let remoteAPI: BackendAPI = HereWebAPI()
    private let subscriptions = CancelBag()
    
    public func getMnemonic() -> [String] {
        guard let entropy = try? keyStore.keychain.getData("entropy")
        else { return [] }
        return BIP39.toMnemonic(entropy.bytes)
    }
        
    public init(userProfile: UserProfile) {
        self.userProfile = userProfile
        
        Task {
            let (today) = await remoteAPI.getExchangeCourse(coinType: .NEAR)
            Task { @MainActor in self.todayPrice = today.0 }
        }
    
        Task { try? await self.updateTokens() }
        Timer.publish(every: 5, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task { try? await self.updateTokens() }
            }
            .store(in: subscriptions)
    }

    public var nearToken: FtOverviewToken? {
        self.tokens.first { $0.symbol == "NEAR" }
    }
    
    @Sendable
    public func updateTokens() async throws {
        let tokens = await remoteAPI.getFungibleTokens(accountId: userProfile.account.address)
        let _ = await userProfile.account.fetchState()
        let amount = userProfile.account.accountAmount ?? 0
    
        Task { @MainActor in
            self.tokens = tokens.map { token in
                var token = token
                if token.symbol == "NEAR" {
                    token.setAmount(amount)
                }
                
                return token
            }
        }

    }
    
    @Sendable
    public func updateCourse() async {
        let (today, _) = await remoteAPI.getExchangeCourse(coinType: .NEAR)
        todayPrice = today
    }
}

extension UserSession: Equatable {
    public static func ==(lhs: UserSession, rhs: UserSession) -> Bool {
        lhs.userProfile == rhs.userProfile
    }
}
