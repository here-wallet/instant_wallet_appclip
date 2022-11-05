
import Foundation
import Combine

public final actor CancelBag {
    public fileprivate(set) var subscriptions = Set<AnyCancellable>()

    public func cancel() {
        subscriptions.removeAll()
    }
    
    func insert(_ subscription: AnyCancellable) {
        subscriptions.insert(subscription)
    }

    func collect(@Builder _ cancellables: () -> [AnyCancellable]) {
        subscriptions.formUnion(cancellables())
    }

    @resultBuilder
    struct Builder {
        static func buildBlock(_ cancellables: AnyCancellable...) -> [AnyCancellable] {
            return cancellables
        }
    }
    
    public init() { }
}

public extension AnyCancellable {

    func store(in cancelBag: CancelBag) {
        Task {
            await cancelBag.insert(self)
        }
    }
    
    func store(in cancelBag: CancelBag) async {
        await cancelBag.insert(self)
    }
}
