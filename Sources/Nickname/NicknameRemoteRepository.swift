import Foundation

protocol NicknameRemoteRepository: BaseWebRepository {
    func checkAccountIdExistance(nickname: NamedNearAddress) async -> Result<Bool, Error>
    func allocateNickname(
        nickname: NamedNearAddress,
        publicKey: String,
        sign: String,
        deviceId: String
    ) async -> Result<(), Error>
}

struct RealNicknameRemoteRepository: NicknameRemoteRepository {
    public var session: HereHTTPClient = .shared

    func checkAccountIdExistance(nickname: NamedNearAddress) async -> Result<Bool, Error> {
        do {
            let url = URL(string: "https://\(AppInfo.shared.hereHost)/api/v1/user/check_account_exist?near_account_id=\(nickname.address)")!
            let request = URLRequest(url: url)
            let accountIdExist: AccountIdExist = try await self.request(request: request)
            return .success(accountIdExist.exist)
        } catch {
            return .failure(error)
        }
    }
    
    func allocateNickname(nickname: NamedNearAddress, publicKey: String, sign: String, deviceId: String) async -> Result<(), Error> {
        do {
            let body: AllocateUsername = .init(nearAccountID: nickname.address, publicKey: publicKey, sign: sign, deviceId: deviceId)
            let url = URL(string: "https://\(AppInfo.shared.hereHost)/api/v1/user/create_near_username")!
            var request = URLRequest(url: url, httpMethod: .post)
            request.httpBody = body.data
            try await self.request(request: request)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}

fileprivate struct AllocateUsername: Codable {
    let nearAccountID, publicKey, sign, deviceId: String
    
    enum CodingKeys: String, CodingKey {
        case nearAccountID = "near_account_id"
        case publicKey = "public_key"
        case deviceId = "device_id"
        case sign
    }
    
    var data: Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(self)
    }
}

fileprivate struct AccountIdExist: Codable {
    let exist: Bool
}
