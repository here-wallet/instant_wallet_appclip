import Foundation

enum NetworkError: Error {
    case unexpected
    case responseError(response: URLResponse?)
}


public enum CoinType: String, Codable {
    case NULL
    case NEAR
    case BITCOIN
    
    var yoctoCoinExp: UInt {
        switch self {
        case .NEAR: return 24
        case .BITCOIN: return 12
        case .NULL: return 0
        }
    }
}

public protocol BackendAPI: BaseWebRepository {
    func generateAccessToken(generate: GenerateAcessToken) async throws -> String
    func getExchangeCourse(coinType: CoinType) async -> (Decimal, Decimal)
    func wsWalletLogin(requestID: String) async throws -> String
    func checkRegister(accountId: String) async -> Bool
    func getFungibleTokens(accountId: String) async -> [FtOverviewToken]
    func getABTests() async throws -> ABTests
    func logout() async throws
}

public struct HereWebAPI: BackendAPI {
    public var session: HereHTTPClient = .shared
    private let endpoint = "\(AppInfo.shared.hereHost)/api/v1"
    
    public func getExchangeCourse(coinType: CoinType) async -> (Decimal, Decimal) {
        let url = URL(string: "https://\(endpoint)/rate?currency=\(coinType.rawValue.uppercased())")!
        let request = URLRequest(url: url)

        guard let data: GetFiat = try? await self.request(request: request)
        else { return (0,0) }

        return (data.rate, data.yesterdayRate)
    }
    
    public func wsWalletLogin(requestID: String) async throws -> String {
        let url = URL(string: "wss://\(endpoint)/user/ws/wallet_login/\(requestID)")!
        let ws: WebSocketStream = .init(url: url.absoluteString)
        for try await value in ws {
            let dict: [String: Any]
            switch value {
            case let .data(data):
                let string = String(data: data, encoding: .utf8)
                dict = try string!.asJSONToDictionary()
            case let .string(string):
                dict = try string.asJSONToDictionary()
            @unknown default:
                fatalError()
            }
            return dict["account_id"] as! String
        }
        fatalError()
    }
    
    public func checkRegister(accountId: String) async -> Bool {
        let link = "https://\(endpoint)/user?near_account_id=\(accountId)"
        guard let url = URL(string: link) else { return false }
        let request = URLRequest(url: url)
        
        do {
            try await self.request(request: request)
            return true
        } catch {
            return false
        }
    }
    
    public func logout() async throws {
        let url = URL(string: "https://\(endpoint)/user/device/logout")!
        print("url", url)
        let request = URLRequest(url: url, httpMethod: .post)
        try await self.request(request: request)
    }
    
    public func getABTests() async throws -> ABTests {
        let url = URL(string: "https://\(endpoint)/user/abtest")!
        var request = URLRequest(url: url, httpMethod: .get)
        let data: ABTests = try await self.request(request: request)
        return data
    }
    
    public func getFungibleTokens(accountId: String) async -> [FtOverviewToken] {
        let url = URL(string: "https://\(endpoint)/user/fts?near_account_id=\(accountId)")!
    
        struct FtTokens: Codable {
            let fts: [FtOverviewToken]
        }
        
        let request = URLRequest(url: url, httpMethod: .get)
        let data: FtTokens? = try? await self.request(request: request)
        return data?.fts ?? []
    }
    
    public func generateAccessToken(generate: GenerateAcessToken) async throws -> String {
        struct AccessToken: Codable {
            let token: String
        }
        
        let url = URL(string: "https://\(endpoint)/user/auth")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(generate)
                
        let result: AccessToken = try await self.request(request: request)
        return result.token
    }
}

// MARK: - GetFiat
private struct GetFiat: Codable {
    let rate, yesterdayRate: Decimal
}

public struct GenerateAcessToken: Codable {
    let nearAccountId: String;
    let publicKey: String;
    let accountSign: String;
    let deviceName: String;
    let deviceId: String;
}

public struct ABTests: Codable {
    let tests: [ABTest]
    
    public init(tests: [ABTest] = []) {
        self.tests = tests
    }

    public func isActive(_ name: ABName) -> Bool {
        self.get(name)?.value == true
    }
    
    public func get(_ name: ABName) -> ABTest? {
        tests.first { $0.name == name.rawValue }
    }
    
    public struct ABTest: Codable {
        let name: String
        let value: Bool
    }
   
    public enum ABName: String, Codable {
        case phoneNumberTransfer = "phone_number_transfer"
        case newHome = "new_home"
        case nftAvatar = "nft_avatar"
    }
}

struct GetUser: Codable {
    let apyValue: Int
    let lastAccrualTs: Double
    let accrued: Int
    enum CodingKeys: String, CodingKey {
        case apyValue = "apy_value"
        case lastAccrualTs = "last_accrual_ts"
        case accrued
    }
}

