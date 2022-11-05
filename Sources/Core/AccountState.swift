

import Foundation
import NearSwift

public struct AccountState: Codable {
    public let accountId: String?
    public let staked: String?
    public let locked: String
    public let nearAmount: String
    public let codeHash: String
    public let storagePaidAt: Number
    public let storageUsage: Number
    public var wNearAmount: String
    public var accrued: UInt128
    
    init(nearAccountState: NearSwift.AccountState, wNearAmount: String, accrued: UInt128) {
        accountId = nearAccountState.accountId
        staked = nearAccountState.staked
        locked = nearAccountState.locked
        nearAmount = nearAccountState.amount
        codeHash = nearAccountState.codeHash
        storagePaidAt = nearAccountState.storagePaidAt
        storageUsage = nearAccountState.storageUsage
        self.wNearAmount = wNearAmount
        self.accrued = accrued
    }
}
