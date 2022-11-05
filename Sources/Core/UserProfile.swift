import Foundation
import NearSwift
import BigInt

public struct UserProfile {
    
    // MARK: Public property
    
    public private(set) var account: NearAccount
    public var APY: Decimal {
        get async {
            _ = await account.state?.value
            let contractAccount: ContractAccount? = try? await account.viewFunction(
                contractId: AppInfo.shared.hereContract,
                methodName: "get_user",
                args: ["account_id": account.address]
            )
        
            guard let contractAccount = contractAccount else { return 0.1 }
            return .init(contractAccount.apyValue) / 10_000.0
        }
    }
    
    // MARK: Private property
    
    private let nearConverter = HereCryptoConverter(coin: .NEAR)
    private let remoteApi = HereWebAPI()
    
    // MARK: Public methods
    
    public init(config: NearConfigProtocol, address: String) async throws {
        let near = try Near(config: config)
        let account = await NearAccount(address: address, connection: near.connection)
        self.account = account
    }
    
    public func allocateAmount(amount: UInt128) async throws {
        await account.fetchState()

        let nearAmount = account.nearAmount ?? 0
        let reservedAmount = account.reservedAmount ?? 0

        if (reservedAmount + amount) > nearAmount {
            let near = (reservedAmount + amount) - nearAmount
            print("[allocateAmount] try", near)
            try await account.withdrawFromContract(amount: near)
        }
    }
    
    public func fetchStates(for accountsToUpdate: [NearAccount]) async {
        await withTaskGroup(of: NearAccount.self) { group in
            for account in accountsToUpdate {
                group.addTask {
                    _ = await account.fetchState()
                    return account
                }
            }
            await group.waitForAll()
        }
    }
    
    // MARK: Private methods
    
    private func fetchAccountState(for account: Account) async throws -> NearSwift.AccountState {
        let state = try await account.state()
        return state
    }
}

// MARK: Equatable

extension UserProfile: Equatable {
    public static func ==(_ lhs: UserProfile, rhs: UserProfile) -> Bool {
        lhs.account == rhs.account
    }
}


struct ContractAccount: Codable {
    let apyValue: UInt64
    let lastAccuralTs: Decimal
    let accrued: String
    
    var accruedUInt128: UInt128 {
        .init(stringLiteral: accrued)
    }
    var date: Date {
        let time = lastAccuralTs / pow(10,9)
        let dTime = Double(exactly: NSDecimalNumber(decimal: time)) ?? 0.0
        return .init(timeIntervalSince1970: dTime)
    }
    
    func totalAccrued(hNearAmount: UInt128) -> UInt128 {
        let hNear = BigUInt(stringLiteral: hNearAmount.description)
        let inYearBigUInt = (hNear * BigUInt(integerLiteral: apyValue))
        let inYear = Decimal(string: inYearBigUInt.description) ?? 0.0
        let inSec = inYear / 31557600
        let delta = Decimal(-date.timeIntervalSinceNow)
        let totalApy = ((delta * inSec) / 10_000).rounded(scale: 0, roundingMode: .down)
        return .init(stringLiteral: totalApy.description) + .init(stringLiteral: accrued)
    }
    
    enum CodingKeys: String, CodingKey {
        case apyValue = "apy_value"
        case lastAccuralTs = "last_accrual_ts"
        case accrued = "accrued"
    }
}
