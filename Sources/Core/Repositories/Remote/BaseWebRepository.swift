import Foundation
import Accessibility

public class HereHTTPClient {
    static let shared = HereHTTPClient()
    
    private var authToken = ""
    private var session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.allowsCellularAccess = true
        config.timeoutIntervalForRequest = 300
        config.waitsForConnectivity = true
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.httpAdditionalHeaders = HTTPHeader.default
            .map { ($0.name, $0.value) }
            .reduce(into: [:], { $0[$1.0] = $1.1 })
        
        return URLSession(configuration: config)
    }()
    
    public func setAuthToken(token: String) {
        self.authToken = token
    }
    
    public func dataTask(with _request: URLRequest, completionHandler: @escaping @Sendable (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        var request = _request
        request.addValue(authToken, forHTTPHeaderField: "Authorization")
        return session.dataTask(with: request, completionHandler: completionHandler)
    }
}

public extension URLRequest {
    init(url: URL, httpMethod: HTTPMethod, headers: [HTTPHeader] = []) {
        self.init(url: url)
        self.httpMethod = httpMethod.rawValue
        headers.forEach {
            if allHTTPHeaderFields?[$0.name] != nil {
                setValue($0.value, forHTTPHeaderField: $0.name)
            } else {
                addValue($0.value, forHTTPHeaderField: $0.name)
            }
        }
    }
}

public protocol BaseWebRepository {
    var session: HereHTTPClient { get }
}

extension BaseWebRepository {
    public var session: HereHTTPClient { .shared }
    var success: Range<Int> { 200 ..< 300 }
    
    @discardableResult
    func request(request: URLRequest) async throws -> Data {
        return try await withCheckedThrowingContinuation({ continuation in
            session.dataTask(with: request) { data, response, error in                      
                guard error == nil else {
                    continuation.resume(throwing: error!)
                    return
                }
        
                guard
                    let response = response as? HTTPURLResponse,
                    self.success.contains(response.statusCode)
                else {
                    if let response = response as? HTTPURLResponse {
                        continuation.resume(throwing: ServerError.code(response.statusCode, response: response))
                    } else {
                        continuation.resume(throwing: URLError(.badServerResponse))
                    }
                    return
                }

                
                guard let data = data else {
                    continuation.resume(throwing: ServerError.emptyData)
                    return
                }

                continuation.resume(returning: data)
            }.resume()
        })
    }

    @discardableResult
    func request<Value: Decodable>(request: URLRequest) async throws -> Value {
        let rawData = try await self.request(request: request)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return try decoder.decode(Value.self, from: rawData)
    }
}

enum ServerError: Error, CustomStringConvertible {
    case code(_ code: Int, response: HTTPURLResponse)
    case systemError(_ error: ErrorMessage)
    case emptyData

    var description: String {
        switch self {
        case let .code(code, _):
            return "Unexpected code(\(code)) from server"
        case .emptyData:
            return "Unexpected response from server"
        case let .systemError(error):
            return error.localizedDescription
        }
    }
}
