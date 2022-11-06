import Foundation
import NearIOSWalletUIKit
import PanModal
import Combine
import UIKit

public class MoneyFromLinkViewController: NiblessViewController {
    private let viewModel: MoneyFromLinkModel
    private let analytics: AnalyticsMoneyFromLink?
    private let subscriptions: CancelBag = .init()

    public init(viewModel: MoneyFromLinkModel, analytics: AnalyticsMoneyFromLink?) {
        self.analytics = analytics
        self.viewModel = viewModel
        super.init()
    }
    
    public override func loadView() {
        view = MoneyFromLinkView(state: .loading)
        analytics?.open()
        
        Task { await viewModel.receiveMoney() }
        viewModel.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.view = MoneyFromLinkView(state: state)
                switch state {
                case .failure: self?.analytics?.failure()
                case .success: self?.analytics?.success()
                case .loading: break
                }
            }
            .store(in: subscriptions)
    }
}
