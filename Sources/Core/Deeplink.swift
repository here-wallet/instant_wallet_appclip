import Foundation
import Combine
import UIKit

public enum DeeplinkSignWeb: Equatable {
    case signRequest(id: String)
    case sign(arguments: [URLQueryItem])
}

public struct LinkPhoneWeb: Equatable {
    public let phone: String
    public let code: String
    public let phoneId: Int
    
    public init?(query: [URLQueryItem]) {
        guard
            let phone = query.first(where: { $0.name == "phone" })?.value,
            let code = query.first(where: { $0.name == "code" })?.value,
            let id = query.first(where: { $0.name == "phone_id" })?.value,
            let phoneId = Int(id)
        else { return nil }
        
        self.phone = phone
        self.phoneId = phoneId
        self.code = code
    }
}

public enum DeeplinkSignedIn: Equatable {
    case signWeb(_ type: DeeplinkSignWeb)
    case linkPhone(_ data: LinkPhoneWeb)
    case moneyDrop(key: LinkDropType)
    case logout
    
    public var signWeb: DeeplinkSignWeb? {
        if case let .signWeb(type) = self { return type }
        return nil
    }
    
    public var linkPhone: LinkPhoneWeb? {
        if case let .linkPhone(type) = self { return type }
        return nil
    }
    
    public var moneyDrop: LinkDropType? {
        if case let .moneyDrop(key) = self { return key }
        return nil
    }
    
    public var logout: Bool {
        if case .logout = self { return true }
        return false
    }
}

public enum DeeplinkRoute: Equatable {
    case signedIn(_ route: DeeplinkSignedIn)
    case none
    
    public var signedIn: DeeplinkSignedIn? {
        if case let .signedIn(route) = self { return route }
        return nil
    }
}

public class DeeplinkService {
    @Published public private(set) var route: DeeplinkRoute = .none
    
    public var routePublisher: AnyPublisher<DeeplinkRoute, Never> {
        return self.$route.eraseToAnyPublisher()
    }
    
    public init() {}
    
    public func push(url: URL) {
        // TODO: remove legacy hereapp.com
        let domains = ["hereapp.com", "herewallet.app", "phone.herewallet.app", "web.herewallet.app"]
        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            domains.contains(components.host ?? "") == true
        else { return }
        
        
        if components.host == "web.herewallet.app",
            let item = components.queryItems?.first(where: { $0.name == "request_id" }),
            let request = item.value
        {
            route = .signedIn(.signWeb(.signRequest(id: request)))
            return
        }
        
        if components.host == "phone.herewallet.app", components.path.starts(with: "/p/") {
            let key = components.path.replacingOccurrences(of: "/p/", with: "")
            print("phone.herewallet.app/p/", key)
            route = .signedIn(.moneyDrop(key: .partner(key)))
            return
        }
        
        
        print("guck", components.path)

        switch components.path {
        case "/sign_request":
            route = .signedIn(.signWeb(.signRequest(id: components.query ?? "")))
            break
        
        case "/sign":
            route = .signedIn(.signWeb(.sign(arguments: components.queryItems ?? [])))
            break
            
        case "/secret_logout_234dsndjfk3":
            route = .signedIn(.logout)
            break
            
            
        case "/l", "/L":
            guard
                let items = components.queryItems,
                let key = items.first(where: { $0.name == "key" })?.value
            else {
                route = .none
                break
            }

            route = .signedIn(.moneyDrop(key: .link(key)))
            break
            
        case "/receive", "/link_phone":
            guard
                let items = components.queryItems,
                let data = LinkPhoneWeb(query: items)
            else {
                route = .none
                break
            }
            
            route = .signedIn(.linkPhone(data))
            break
            
            
        default:
            route = .none
            break
        }
    }
    
    public func clear() {
        route = .none
    }
}
