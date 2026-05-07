import SwiftUI
import Combine
import UIKit

struct CombineSubscriptionView: View {
    @State private var fixApplied: Bool = false
    @State private var triggerCount: Int = 0
    @State private var subscribers: [Subscriber] = []

    var body: some View {
        DemoChrome(
            title: "Combine subscription",
            blurb: "Each Trigger creates a Subscriber whose .sink closure captures self. Without [weak self], the AnyCancellable held inside the Subscriber retains the closure which retains the Subscriber — a self-cycle.",
            fixDescription: "Use [weak self] in the .sink closure",
            fixApplied: $fixApplied,
            liveCountText: """
                this session: \(triggerCount) trigger(s)
                live Subscriber globally: \(LiveCounter.shared.count("Subscriber"))
                """,
            onTrigger: {
                let sub = Subscriber(useWeakSelf: fixApplied)
                subscribers.append(sub)
                triggerCount += 1
            }
        )
    }
}

extension CombineSubscriptionView {
    static func host() -> UIViewController {
        let vc = UIHostingController(rootView: CombineSubscriptionView())
        vc.title = "Combine subscription"
        return vc
    }
}

final class Subscriber {
    private var cancellables: Set<AnyCancellable> = []
    private static let publisherName = Notification.Name("LeakLab.demo4")

    init(useWeakSelf: Bool) {
        LiveCounter.shared.increment("Subscriber")
        let publisher = NotificationCenter.default.publisher(for: Self.publisherName)
        if useWeakSelf {
            publisher
                .sink { [weak self] _ in self?.handle() }
                .store(in: &cancellables)
        } else {
            // Strong capture of self; AnyCancellable lives on self.cancellables → cycle.
            publisher
                .sink { _ in self.handle() }
                .store(in: &cancellables)
        }
    }

    private func handle() {}

    deinit {
        LiveCounter.shared.decrement("Subscriber")
        print("Subscriber deinit")
    }
}
