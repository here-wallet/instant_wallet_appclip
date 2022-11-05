
import Foundation
import Combine
import NearSwift

extension Account: Hashable {
    public static func == (lhs: Account, rhs: Account) -> Bool {
        lhs.accountId == rhs.accountId
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(accountId)
    }
}
// MARK: NearAccount

public final actor NearAccount: Hashable {
    
    // MARK: Public property
    
    public let account: Account
    
    public nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(address)
    }
    
    public nonisolated var address: String {
        account.accountId
    }
    
    var accountState: AccountState? {
        get async {
            await state?.value
        }
    }
    public nonisolated var lastState: AccountState? {
        stateSubject.value
    }

    public nonisolated var reservedAmount: UInt128? {
        guard let state = lastState else { return nil }
        let storageUsage = Decimal(state.storageUsage)
        let storagePay: Decimal = storageUsage / 100000.0
        let reserved: UInt128 = nearConverter.toChainFormat(storagePay + 0.05)
        return reserved
    }
    
    public nonisolated var accountAmount: UInt128? {
        getAvailableAmount()
    }
    
    public nonisolated var nearAmount: UInt128? {
        guard let lastState = lastState else { return nil }
        return nearConverter.toChainFormat(lastState.nearAmount)
    }

    public nonisolated var safeNearAmount: UInt128? {
        guard let nearAmount = nearAmount else { return nil }
        guard let reservedAmount = reservedAmount else { return nil }
        guard nearAmount > reservedAmount else { return 0 }
        return nearAmount - reservedAmount
    }
    
    public nonisolated var hNearAmount: UInt128? {
        guard let lastState = lastState else { return nil }
        return nearConverter.toChainFormat(lastState.wNearAmount)
    }
    
    public func getBlockId() async -> String? {
        let provider = account.connection.provider
        let block = try? await provider.block(blockQuery: .finality(.final))
        return block?.header.hash
    }
    
    public nonisolated var accruedAmount: UInt128? {
        lastState?.accrued
    }

    public nonisolated var statePublisher: AnyPublisher<AccountState?, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    public nonisolated var accountAmountPublisher: AnyPublisher<UInt128, Never> {
        stateSubject
            .compactMap { $0 }
            .map { [weak self] _ -> UInt128 in
                self?.getAvailableAmount() ?? 0
            }
            .eraseToAnyPublisher()
    }
    
    public nonisolated var safeYoctoNearPublisher: AnyPublisher<UInt128, Never> {
        stateSubject
            .compactMap { $0 }
            .compactMap { [weak self] _ in
                self?.safeNearAmount
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: Private property
    
    private let stateSubject: CurrentValueSubject<AccountState?, Never> = .init(nil)
    private let nearConverter = HereCryptoConverter(coin: .NEAR)
    
    public var state: Task<AccountState?, Never>? = nil
    
    // MARK: Public methods
    
    init(address: String, connection: Connection) async {
        account = .init(connection: connection, accountId: address)
        reloadAllStates()
    }
    
    public func viewFunction<T: Decodable>(contractId: String, methodName: String, args: [String: Any] = [:]) async throws -> T {
        try await account.viewFunction(contractId: contractId, methodName: methodName, args: args)
    }
    
    public func functionCall(
        contractId: String,
        methodName: ChangeMethod,
        args: [String: Any] = [:],
        gas: UInt64?,
        amount: UInt128
    ) async throws -> FinalExecutionOutcome {
        let result = try await account.functionCall(contractId: contractId, methodName: methodName, args: args, gas: gas, amount: amount)
        reloadAllStates()
        _ = await state?.value
        return result
    }
    
    @discardableResult
    public func sendMoney(receiverId: String, amount: UInt128) async throws -> FinalExecutionOutcome {
        let result = try await account.sendMoney(receiverId: receiverId, amount: amount)
        reloadAllStates()
        return result
    }
    
    @discardableResult
    public func fetchState() async -> AccountState? {
        reloadAllStates()
        return await state?.value
    }
    
    public func addKey(pub: String, contract: String?, methodName: [String]?, amount: String?) async throws -> String {
        let key = try PublicKey.fromString(encodedKey: pub)
        var yokto: UInt128?
        
        if let amount = amount {
            yokto = UInt128.init(stringLiteral: amount)
        }
        
        let result = try await account.addKey(
            publicKey: key,
            contractId: contract,
            methodNames: methodName,
            amount: yokto
        )
        
        return result.transactionOutcome.id
    }
    
    @discardableResult
    public func withdrawFromContract(amount: UInt128) async throws -> FinalExecutionOutcome {
        var amountWithGas = UInt128(30000000000000) + amount + UInt128(stringLiteral: pow(10, 23).description)
        if amountWithGas > (hNearAmount ?? 0) {
            amountWithGas = hNearAmount ?? 0
        }

        return try await functionCall(
            contractId: AppInfo.shared.hereContract,
            methodName: "storage_withdraw",
            args: ["amount": amountWithGas.toString()],
            gas: nil,
            amount: 1
        )
    }
    
    public func decodeTransaction(message: Data) throws -> CodableTransaction {
        return try account.decodeTransaction(message: message)
    }
    
    public func signTransactions(trxs: [CodableTransaction]) async throws -> [String] {
        let amount = trxs.reduce(into: UInt128(0), { (acc, trx) in
            trx.actions.forEach { action in
                switch action {
                case .functionCall(let act):
                    acc += UInt128(act.gas)
                    acc += act.deposit
                    break
                
                case .transfer(let act):
                    acc += act.deposit
                    break
                    
                default:
                    break
                }
            }
        })
        
        var hashes: [String] = []
        if (safeNearAmount ?? 0) < amount {
            let withdrawResult = try await withdrawFromContract(amount: amount)
            hashes.append(withdrawResult.transactionOutcome.id)
        }
        
        for trx in trxs {
            let result = try await self.account.signAndSendTransaction(
                receiverId: trx.receiverId,
                actions: trx.actions
            )

            hashes.append(result.transactionOutcome.id)
        }
        
        return hashes
    }
    
    // MARK: Private method
    
    func fetchAccrued(hNear: UInt128) async -> UInt128 {
        let contractAccount: ContractAccount? = try? await account.viewFunction(
            contractId: AppInfo.shared.hereContract,
            methodName: "get_user",
            args: ["account_id": address]
        )

        return contractAccount?.totalAccrued(hNearAmount: hNear) ?? 0
    }
    
    private func fetchContractBalance() async throws -> String {
        return try await account.viewFunction(
            contractId: AppInfo.shared.hereContract,
            methodName: "ft_balance_of",
            args: ["account_id": address ]
        )
    }
    
    private func reloadContractState() {
        state = Task {
            var last = lastState
            if let contractBalance = try? await fetchContractBalance() {
                last?.wNearAmount = contractBalance
            } else {
                last?.wNearAmount = "0"
            }
            stateSubject.send(last)
            return last
        }
    }
    
    private func reloadNearState() async throws {
        state = Task {
            guard let state = try? await account.state() else { return nil }
            let hereState = AccountState(
                nearAccountState: state,
                wNearAmount: lastState?.wNearAmount ?? "0",
                accrued: lastState?.accrued ?? 0
            )
            stateSubject.send(hereState)
            return hereState
        }
    }
    
    private func reloadAllStates() {
        state = Task {
            async let asyncContractBalance = fetchContractBalance()
            async let asyncState = account.state()
            let state = (try? await asyncState) ?? .initial
            let contractBalance = (try? await asyncContractBalance) ?? "0"
            let accrued = await fetchAccrued(hNear: nearConverter.toChainFormat(contractBalance))
            let hereState = AccountState(
                nearAccountState: state,
                wNearAmount: contractBalance,
                accrued: accrued
            )
            stateSubject.send(hereState)
            return hereState
        }
    }
    
    private nonisolated func getAvailableAmount() -> UInt128? {
        guard
            let state = lastState
        else {
            return nil
        }
        let rawWNearAmount = state.wNearAmount
        let nearAmount: UInt128 = safeNearAmount ?? 0
        let wNearAmount: UInt128 = nearConverter.toChainFormat(rawWNearAmount)
        return nearAmount + wNearAmount
    }
    
    // MARK: Equatable
    public nonisolated static func == (lhs: NearAccount, rhs: NearAccount) -> Bool {
        lhs.address == rhs.address
    }
}
