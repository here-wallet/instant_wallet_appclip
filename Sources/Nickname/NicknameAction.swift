import Foundation
import HDWallet

indirect enum NicknameAction: CustomStringConvertible {
    enum Suggestion: String, CustomStringConvertible {
        case wrongNickname = "This nickname cannot be allocated."
        case allocatedNickname = "This nickname has already been taken"
        case empty = ""
        
        var description: String {
            return self.rawValue
        }
    }
    
    case checkAccountIdExist(
        _ nickname: NamedNearAddress,
        onSuccess: (Bool) -> [NicknameAction],
        onFailure: (Error) -> NicknameAction = { .showError($0) }
    )
    case allocateNickname(
        _ nickname: NamedNearAddress,
        onSuccess: [NicknameAction],
        onFailure: (Error) -> [NicknameAction] = { [.showLoader(false), .showError($0)] }
    )
    case showError(_ error: Error)
    case changeSuggestion(_ suggestion: Suggestion)
    case changeContinue(_ isAvailable: Bool)
    case showLoader(_ show: Bool)
    case signUp(_ seed: BIP39, checkNickname: Bool = false, onFailure: (Error) -> NicknameAction = { .showError($0) })
    
    var description: String {
        switch self {
        case .checkAccountIdExist: return "Nickname: checkAccountIdExist"
        case .allocateNickname: return "Nickname: allocateNickname"
        case let .showError(error): return "Nickname: showError \(error)"
        case .changeSuggestion: return "cNickname: hangeSuggestion"
        case .changeContinue: return "Nickname: changeContinue"
        case .showLoader: return "Nickname: showLoader"
        case .signUp: return "Nickname: signUp"
        }
    }
}
