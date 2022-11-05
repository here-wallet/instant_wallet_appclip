import Foundation
import KeychainAccess
import NearSwift


public final actor HereKeychain: KeyStore, WalletStorage {
    
    let keychain: Keychain
    
    public init(keychainId: String = "Here Wallet") {
        let keychain = Keychain(service: keychainId)
        self.keychain = keychain.synchronizable(false)
    }
    
    private func storageKeyForSecretKey(networkId: String, accountId: String) -> String {
        return "\(accountId):\(networkId)"
    }
    
    private func storageKeyForAccessToken(networkId: String, accountId: String) -> String {
        return "\(accountId):\(networkId):token"
    }
    
    public func get(for key: String) async throws -> String? {
        try keychain.get(key)
    }
    
    public func set(_ value: String?, for key: String) async throws {
        if let value = value {
            try keychain.set(value, key: key)
        } else {
            try keychain.remove(key)
        }
    }
    
    // MARK: - KeyStore
    public func setKey(networkId: String, accountId: String, keyPair: KeyPair) async throws {
        let key = storageKeyForSecretKey(networkId: networkId, accountId: accountId)
        guard let privateKey = keyPair.toString().components(separatedBy: ":").last
        else { return }
        
        try await set(privateKey, for: key)
    }
    
    public func setKey(networkId: String, accountId: String, token: String) async throws {
        let key = storageKeyForAccessToken(networkId: networkId, accountId: accountId)
        try await set(token, for: key)
    }
    
    public func getKey(networkId: String, accountId: String) async throws -> KeyPair? {
        let key = storageKeyForSecretKey(networkId: networkId, accountId: accountId)
        guard let privateKey = try await get(for: key) else { return nil }
        
        return try KeyPairEd25519(secretKey: privateKey)
    }
    
    public func getAccessToken(networkId: String, accountId: String) async throws -> String? {
        let key = storageKeyForAccessToken(networkId: networkId, accountId: accountId)
        return try await get(for: key)
    }
    
    public func removeKey(networkId: String, accountId: String) async throws {
        let privateKey = storageKeyForSecretKey(networkId: networkId, accountId: accountId)
        try await set(nil, for: privateKey)
        
        let acessTokenKey = storageKeyForAccessToken(networkId: networkId, accountId: accountId)
        try await set(nil, for: acessTokenKey)
    }
    
    public func clear() async throws {
        try keychain.removeAll()
    }
    
    public func getNetworks() async throws -> [String] {
        var result = Set<String>()
        for key in keychain.allKeys() {
            if let networkId = key.components(separatedBy: ":").last {
                result.insert(networkId)
            }
        }
        return Array(result)
    }
    
    public func getAccounts(networkId: String) async throws -> [String] {
        var result = [String]()
        for key in keychain.allKeys() {
            let components = key.components(separatedBy: ":")
            if let keychainNetworkId = components.last,
               keychainNetworkId == networkId,
               let accountId = components.first {
                result.append(accountId)
            }
        }
        return result
    }
    
    public func getDeviceID() async -> String {
        let keychain = HereKeychain(keychainId: "app.here.wallet.device.identity")
        if let result = try? await keychain.get(for: "deviceId") {
            return result
        } else {
            let deviceID: String = random().data.hexString
            try? await keychain.set(deviceID, for: "deviceId")
            return deviceID
        }
    }
    
    private func random() -> [UInt8] {
        var bytes: [UInt8] = .init(repeating: 0, count: 32)
        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard result == errSecSuccess else { fatalError() }
        return bytes
    }
}
