import Foundation

public struct LinkPhoneRequest: Codable {
    let code: String
    let phoneNumberId: Int
    let nearAccountId: String
}

public class PhoneTransferWebRepository: BaseWebRepository {
    public var session: HereHTTPClient = .shared
    private var hashes: [String: String] = [:]
    private let domain = "https://api.herewallet.app/api/v1"

    public struct PhoneContact: Codable {
        let name: String
        let phone: String
    }
    
    public init() {}
    
    public func linkPhone(_ params: LinkPhoneRequest) async throws {
        let url = URL(string: "\(domain)/phone/allocate_near_account_id")!
        
        let request: URLRequest = {
            let jsonEncoder: JSONEncoder = .init()
            jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
            var urlRequest: URLRequest = .init(url: url, httpMethod: .post)
            urlRequest.httpBody = try? jsonEncoder.encode(params)
            return urlRequest
        }()
        
        let _ = try await self.request(request: request)
    }
    
    public func partnerDrop(key: String) async throws {
        let url = URL(string: "\(domain)/dapp/airdrop")!
        
        struct Request: Codable {
            let airdropId: String
        }
        
        let request: URLRequest = {
            let jsonEncoder: JSONEncoder = .init()
            jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
            var urlRequest: URLRequest = .init(url: url, httpMethod: .post)
            urlRequest.httpBody = try? jsonEncoder.encode(Request(airdropId: key))
            print("partnerDrop", url, Request(airdropId: key))
            return urlRequest
        }()
        
        let _ = try await self.request(request: request)
    }
    
    func checkContactsList(phones: [PhoneContact]) async -> [String: Bool] {
        struct Phones: Codable {
            let phonesExists: [String: Bool]
        }
        
        guard let url = URL(string: "\(domain)/phone/check_contact_list")
        else { return [:] }
        
        var request = URLRequest(url: url, httpMethod: .post)
        request.httpBody = try? JSONEncoder().encode(["phones": phones])
        
        do {
            let result: Phones = try await self.request(request: request)
            return result.phonesExists
        } catch {
            print("checkContactsList", error)
            return [:]
        }
    }
    
    func putTransferComment(tx: String, comment: String) async throws {
        let domain = "https://api.herewallet.app/api/v1"
        guard let url = URL(string: "\(domain)/transactions/comment")
        else { throw "parse url error" }

        var request = URLRequest(url: url, httpMethod: .post)
        request.httpBody = try JSONEncoder().encode([
            "transaction_hash": tx,
            "comment": comment
        ])
        
        try await self.request(request: request)
    }
    
    func getPhoneHash(phone: String) async throws -> String {
        if let hash = hashes[phone] { return hash }
        
        struct Hash: Codable {
            let hash: String
        }
        
        guard let url = URL(string: "\(domain)/phone/calc_phone_hash?phone=\(phone)")
        else { throw "url parse error" }
        
        let request = URLRequest(url: url, httpMethod: .get)
        let result: Hash = try await self.request(request: request)
        hashes[phone] = result.hash
        return result.hash
    }
}
