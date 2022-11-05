import UIKit
import Combine
import SwiftUI
import NearIOSWalletUIKit

enum AppRoute {
    case loading
    case create
    case signed(session: UserSession)
    
    var userSession: UserSession? {
        switch self {
        case let .signed(session): return session
        default: return nil
        }
    }
}

class AppClipWallet: SignInResponder {
    @Published var route: AppRoute = .loading
    let userRepository = WalletUserSessionRepository()
    let deeplink = DeeplinkService()
    
    func load() async {
        route = .loading
        if let userSession = try? await userRepository.readUserSession() {
            route = .signed(session: userSession)
            return
        }
        
        route = .create
    }
    
    func logout() async {
        deeplink.clear()
        try? await userRepository.signOut()
        route = .create
    }
    
    func signedIn(to userSession: UserSession) {
        route = .signed(session: userSession)
    }
}

class AppViewController: NiblessNavigationController {
    let model: AppClipWallet
    let cancelBag = CancelBag()
    
    init(model: AppClipWallet) {
        self.model = model
        super.init()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = NearIOSWalletUIKitAsset.Color.elevation0.color
        Task { await model.load() }

        model.$route
            .receive(on: DispatchQueue.main)
            .sink { route in
                switch route {
                case .loading: self.presentLoading()
                case .create: self.presentCreateWallet()
                case .signed(let session): self.presentSigned(session: session)
                }
            }
            .store(in: cancelBag)
    }
    
    func subscribe(to publisher: AnyPublisher<DeeplinkSignedIn, Never>) {
        publisher
            .filter(\.logout)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in Task {
                await self?.model.logout()
            }}
            .store(in: cancelBag)
        
        publisher
            .compactMap(\.linkPhone)
            .receive(on: DispatchQueue.main)
            .delay(for: 0.5, scheduler: DispatchQueue.main)
            .sink { [weak self] link in
                self?.presentModalAfterDismiss {
                    self?.presentLinkPhone(link: link)
                }
            }
            .store(in: cancelBag)
        
        publisher
            .compactMap(\.moneyDrop)
            .receive(on: DispatchQueue.main)
            .delay(for: 0.5, scheduler: DispatchQueue.main)
            .sink { [weak self] key in
                self?.presentModalAfterDismiss {
                    self?.presentMoneyFromLink(key: key)
                }
            }
            .store(in: cancelBag)
    }
    
    private func presentModalAfterDismiss(present: @escaping () -> Void) {
        if let vc = presentedViewController {
            vc.dismiss(animated: true) { present() }
            return
        }
            
        present()
    }

    private func presentLinkPhone(link: LinkPhoneWeb) {
        guard let userSession = model.route.userSession else { return }
        let api = PhoneTransferWebRepository()
        let model = LinkPhoneModel(data: link, userSession: userSession, api: api)
        let vc = LinkPhoneViewController(viewModel: model, analytics: nil)
        self.topViewController?.present(vc, animated: true)
    }
    
    private func presentMoneyFromLink(key: LinkDropType) {
        guard let userSession = model.route.userSession else { return }
        let model = MoneyFromLinkModel(key: key, userSession: userSession)
        let vc = MoneyFromLinkViewController(viewModel: model, analytics: nil)
        self.topViewController?.present(vc, animated: true)
    }

    func presentSigned(session: UserSession) {
        let vc = UIHostingController(rootView: InstantWallet(userSession: session))
        vc.view.backgroundColor = NearIOSWalletUIKitAsset.Color.elevation0.color
        self.pushViewController(vc, animated: true)
        
        subscribe(to: model.deeplink.$route
            .compactMap(\.signedIn)
            .eraseToAnyPublisher()
        )
    }
    
    func presentLoading() {
        let vc = SpinnerViewController()
        vc.view.backgroundColor = NearIOSWalletUIKitAsset.Color.elevation0.color
        self.pushViewController(vc, animated: false)
        self.hideNavigationBar(animated: false)
    }
    
    func presentCreateWallet() {
        let model = NicknameViewModel(
            seed: .init(),
            userSessionRepository: model.userRepository,
            signInResponder: model
        )
        let vc = NicknameGiftViewController(viewModel: model, analytics: nil)
        self.pushViewController(vc, animated: true)
        self.hideNavigationBar(animated: false)
    }
}

class SpinnerViewController: UIViewController {
    var spinner = UIActivityIndicatorView(style: .large)

    override func loadView() {
        view = UIView()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.color = .black
        spinner.startAnimating()
        view.addSubview(spinner)

        spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
}
