import Foundation
import NearSwift
import CryptoKit
import UIKit
import HDWallet

public class WalletUserSessionRepository: UserSessionRepository {
    public var session: HereHTTPClient = .shared
    private let remoteAPI: BackendAPI = HereWebAPI()
    private let keyStore = HereKeychain()

    public init() { }
    
    public func readUserSession() async throws -> UserSession? {
        let networkId = AppInfo.shared.nearNetwork
        let accounts = try? await keyStore.getAccounts(networkId: networkId)
        guard let accountId = (accounts ?? [])?.first
        else { return nil }
    
        let config = NearConfig(
          networkId: AppInfo.shared.nearNetwork,
          nodeUrl: AppInfo.shared.nearRpc,
          masterAccount: nil,
          keyPath: nil,
          helperUrl: nil,
          initialBalance: nil,
          providerType: .jsonRPC(AppInfo.shared.nearRpc),
          signerType: .inMemory(keyStore),
          keyStore: keyStore,
          contractName: nil,
          walletUrl: AppInfo.shared.nearWallet
        )

        let profile = try await UserProfile(config: config, address: accountId)
        let accessToken = try await getAccessToken(networkId: networkId, account: accountId)
        HereHTTPClient.shared.setAuthToken(token: accessToken)
        return UserSession(userProfile: profile)
    }

    private func getAccessToken(networkId: String, account: String) async throws -> String {
        if let token = try? await keyStore.getAccessToken(networkId: networkId, accountId: account) {
            return token
        }
        
        let deviceId = await keyStore.getDeviceID()
        guard let keyPair = try await keyStore.getKey(networkId: networkId, accountId: account)
        else { throw "KeyPair is not defined" }
        
        let publicKey = keyPair.getPublicKey().toString()
        let message = [UInt8]((account + deviceId).utf8)
        let accountSign = try keyPair.sign(message: message)
        let token = try await remoteAPI.generateAccessToken(generate: .init(
            nearAccountId: account,
            publicKey: publicKey,
            accountSign: accountSign.signature.baseEncoded,
            deviceName: UIDevice.modelIdentifier,
            deviceId: deviceId
        ))
        
        try await keyStore.setKey(networkId: networkId, accountId: account, token: token)
        return token
    }

    public func signUp(mnemonic: [String], isNew: Bool = false) async throws -> UserSession {
        let mnemonic = mnemonic.map { $0.lowercased() }
        let bip39 = try BIP39(phrase: mnemonic)
        let bip32 = try BIP32(seed: bip39.seed.data, coinType: .near)
        let extendedPrivateKey = bip32.derived(paths: DerivationNode.nearPath)
        let keypair = try KeyPairEd25519.fromSeed(seed: extendedPrivateKey.privateKey)
        let defaultAddress = keypair.getPublicKey().data.data.hexString
        let accountId = isNew
        ? defaultAddress
        : await loadNearName(publicKey: keypair.getPublicKey()) ?? defaultAddress
        let entropy = try BIP39.toEntropy(mnemonic).data
    
        try keyStore.keychain.set(entropy, key: "entropy")
        
        try await keyStore.setKey(
            networkId: AppInfo.shared.nearNetwork,
            accountId: accountId,
            keyPair: keypair
        )
        
        let networkId = AppInfo.shared.nearNetwork
        let config = NearConfig(
          networkId: networkId,
          nodeUrl: AppInfo.shared.nearRpc,
          masterAccount: nil,
          keyPath: nil,
          helperUrl: nil,
          initialBalance: nil,
          providerType: .jsonRPC(AppInfo.shared.nearRpc),
          signerType: .inMemory(keyStore),
          keyStore: keyStore,
          contractName: nil,
          walletUrl: AppInfo.shared.nearWallet
        )
                
        let profile = try await UserProfile(config: config,address: accountId)
        let accessToken = try await getAccessToken(networkId: networkId, account: accountId)
        HereHTTPClient.shared.setAuthToken(token: accessToken)
        return UserSession(userProfile: profile)
    }
    
    public func signOut() async throws {
        // TODO: clear deeplink storage
        try await AnalyticsTracker.shared.flush()
        try await remoteAPI.logout()
        try keyStore.keychain.removeAll()
    }
    
    private func loadNearName(publicKey: PublicKey) async -> String? {
        struct LoadNearName: Codable {
            let users: [String]
        }
        
        let defaultAddress = publicKey.data.data.hexString
        let route = "api/v1/user/by_public_key?public_key=\(publicKey.toString())"
        let url = URL(string: "https://\(AppInfo.shared.hereHost)/\(route)")!
        let request = URLRequest(url: url, httpMethod: .get)
        
        let array: LoadNearName? = try? await self.remoteAPI.request(request: request)
        let address = array?.users.first(where: { $0.contains(AppInfo.shared.nearDomain) })
        
        return address ?? defaultAddress
    }
}


