import Combine
import Foundation
import CryptoKit
import NearSwift
import HDWallet

extension Array: Error where Element: Error { }

public protocol SignInResponder {
    func signedIn(to: UserSession)
}

final public class NicknameViewModel: ObservableObject {
    public var isNicknameValid: AnyPublisher<Bool, Never> {
        nickname
            .map {
                switch $0 {
                case .failure: return false
                case .success: return true
                }
            }
            .eraseToAnyPublisher()
    }
    @Published public private(set) var suggestionText: String = ""
    @Published public private(set) var isContinueActive: Bool = false
    @Published public private(set) var showLoader: Bool = false
    
    public var errorPublisher: AnyPublisher<ErrorMessage, Never> {
        errorSubject
            .eraseToAnyPublisher()
    }
    
    public var rawTextfield: String? {
        didSet { rawTextfieldSubject.send(rawTextfield) }
    }
    
    // MARK: - Private Properties
    
    private let nickname: PassthroughSubject<Result<NamedNearAddress, [NamedNearAddress.ParseError]>, Never> = .init()
    private let rawTextfieldSubject: PassthroughSubject<String?, Never> = .init()
    private let keychain = HereKeychain(keychainId: "identity")
    
    private let remoteService: NicknameRemoteRepository = RealNicknameRemoteRepository()
    private let userSessionRepository: UserSessionRepository
    private let signInResponder: SignInResponder
    
    private let errorSubject: PassthroughSubject<ErrorMessage, Never> = .init()
    private let actionSubject: PassthroughSubject<NicknameAction, Never> = .init()
    
    private let seed: BIP39
    private let subscriptions: CancelBag = .init()
    
    private var uniqueID: String {
        get async {
            if let id = try? await keychain.get(for: "id") {
                return id
            } else {
                let id = UUID().uuidString
                try? await keychain.set(id, for: "id")
                return id
            }
        }
    }
    
    public init(
        seed: BIP39,
        userSessionRepository: UserSessionRepository,
        signInResponder: SignInResponder
    ) {
        self.seed = seed
        self.userSessionRepository = userSessionRepository
        self.signInResponder = signInResponder
        bind()
    }
    
    public func continuePressed() {
        let actions = continueActions()
        actions.forEach { actionSubject.send($0) }
    }
    
    public func skipPressed() {
        let actions = skipActions()
        actions.forEach { actionSubject.send($0) }
    }
    
    private func bind() {
        rawTextfieldSubject
            .replaceNil(with: "")
            .map { NearAddress.named(address: $0) }
            .subscribe(nickname)
            .store(in: subscriptions)
        
        let publisher = collectActions()
        
        
        publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.perform($0)
            }
            .store(in: subscriptions)
    }
    
    private func collectActions() -> AnyPublisher<NicknameAction, Never> {
        let textfieldActions = bindToTextfield()
        let imperativeActions = actionSubject.eraseToAnyPublisher()
        return Publishers.Merge(textfieldActions, imperativeActions).eraseToAnyPublisher()
    }
    
    private func bindToTextfield() -> AnyPublisher<NicknameAction, Never> {
        
        let reset: AnyPublisher<NicknameAction, Never> = rawTextfieldSubject
            .map { _ in NicknameAction.changeContinue(false) }
            .eraseToAnyPublisher()
        
        let isCorrect: AnyPublisher<NicknameAction, Never> = nickname
            .dropFirst()
            .map {
                switch $0 {
                case .success: return .changeSuggestion(.empty)
                case .failure: return .changeSuggestion(.wrongNickname)
                }
            }
            .eraseToAnyPublisher()
        
        let onSuccess: (Bool) -> [NicknameAction] = { available in
            if available {
                return [.changeContinue(true)]
            } else {
                return [
                    .changeSuggestion(.allocatedNickname),
                    .changeContinue(false)
                ]
            }
        }
        
        let isAvailable: AnyPublisher<NicknameAction, Never> = nickname
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .compactMap({ result in
                switch result {
                case .failure: return nil
                case let .success(namedAddress): return namedAddress
                }
            })
            .map { NicknameAction.checkAccountIdExist($0, onSuccess: onSuccess) }
            .eraseToAnyPublisher()
        
        return Publishers.MergeMany([reset, isAvailable, isCorrect]).eraseToAnyPublisher()
    }
    
    private func skipActions() -> [NicknameAction] {
        return [.signUp(seed)]
    }
    
    private func continueActions() -> [NicknameAction] {
        let nicknameParseResult = NearAddress.named(address: rawTextfield ?? "")
        switch nicknameParseResult {
        case let .success(named):
            return [
                .showLoader(true),
                .allocateNickname(
                    named,
                    onSuccess: [.showLoader(false), .signUp(seed, checkNickname: true)]
                )
            ]
        case .failure:
            return [.changeSuggestion(.empty), .changeContinue(false)]
        }
    }
    
    private func perform(_ action: NicknameAction) {
            switch action {
            case let .changeContinue(isActive):
                updateContinueButtonState(isActive: isActive)
            case let .changeSuggestion(text):
                updateSuggestionText(new: text.description)
            case let .showError(error):
                handleError(error)
            case let .checkAccountIdExist(nickname, onSuccess, onFailure):
                Task {
                    switch await checkAccountIdExist(nickname: nickname) {
                    case let .success(isExist): perform(onSuccess(!isExist))
                    case let .failure(error): perform(onFailure(error))
                    }
                }
            case let .allocateNickname(nickname, onSuccess, onFailure):
                Task {
                    switch await allocateNickname(nick: nickname) {
                    case .success: perform(onSuccess)
                    case let .failure(error): perform(onFailure(error))
                    }
                }
            case let .signUp(seed, checkNickname, onFailure):
                Task {
                    switch await signUp(seed: seed, checkNickname: checkNickname) {
                    case .success: break
                    case let .failure(error): perform(onFailure(error))
                    }
                }
            case let .showLoader(show): showLoader = show
            }
    }
    
    private func perform(_ actions: [NicknameAction]) {
        actions.forEach(perform)
    }
    
    private func updateContinueButtonState(isActive: Bool) {
        isContinueActive = isActive
    }
    
    private func updateSuggestionText(new text: String) {
        suggestionText = text
    }
    
    private func handleError(_ error: Error) {
        switch error {
        case let customStringConvertible as CustomStringConvertible:
            errorSubject.send(ErrorMessage(
                title: "Something went wrong",
                message: "\(customStringConvertible)"
            ))
        default:
            errorSubject.send(ErrorMessage(
                title: "Something went wrong",
                message: error.localizedDescription
            ))
        }
    }
    
    private func checkAccountIdExist(nickname: NamedNearAddress) async -> Result<Bool, Error> {
        return await remoteService.checkAccountIdExistance(nickname: nickname)
    }
    
    private func signUp(seed: BIP39, checkNickname: Bool) async -> Result<(), Error> {
        do {
            let session = try await userSessionRepository.signUp(mnemonic: seed.phrase, isNew: !checkNickname)
            signInResponder.signedIn(to: session)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    private func allocateNickname(nick: NamedNearAddress) async -> Result<(), Error> {
        do {
            let deviceId = await uniqueID
            let publicKey = try createKeyPair().getPublicKey()
            let signForRequest = generateSignForRequest(
                publicKey: publicKey,
                namedNearAddress: nick,
                deviceId: deviceId
            )
            return await remoteService.allocateNickname(
                nickname: nick,
                publicKey: publicKey.toString(),
                sign: signForRequest.compactMap { String(format: "%02x", $0) }.joined(),
                deviceId: deviceId
            )
        } catch {
            return .failure(error)
        }
    }
    
    private func createKeyPair() throws -> KeyPair {
        let bip32 = try BIP32(seed: seed.seed.data, coinType: .near)
        let extendedPrivateKey = bip32.derived(paths: DerivationNode.nearPath)
        return try KeyPairEd25519.fromSeed(seed: extendedPrivateKey.privateKey)
    }
    
    fileprivate var nearPrivateKey: String {
        switch AppInfo.shared.nearNetwork {
        case "default", "mainnet": return "..."
        case "testnet": return "..."
        default: return ""
        }
    }
    
    private func generateSignForRequest(
        publicKey: PublicKey,
        namedNearAddress: NamedNearAddress,
        deviceId: String
    ) -> SHA256.Digest {
        let publicKey = publicKey.toString()
        let nickname = namedNearAddress.address
        let data = Data((nearPrivateKey + publicKey + nickname + deviceId).utf8)
        return SHA256.hash(data: data)
    }
}
