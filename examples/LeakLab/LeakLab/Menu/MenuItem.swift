import UIKit

struct MenuItem {
    let title: String
    let subtitle: String
    let framework: String
    let make: () -> UIViewController
}

extension MenuItem {
    static let all: [MenuItem] = [
        MenuItem(
            title: "Closure cycle",
            subtitle: "ChildVM stores closure capturing the VC strongly",
            framework: "UIKit",
            make: { ClosureCycleViewController() }
        ),
        MenuItem(
            title: "Notification observer",
            subtitle: "addObserver(forName:...) block-API captures self",
            framework: "UIKit",
            make: { NotificationLeakViewController() }
        ),
        MenuItem(
            title: "Timer retain cycle",
            subtitle: "Timer.scheduledTimer pins self via the run loop",
            framework: "UIKit",
            make: { TimerLeakViewController() }
        ),
        MenuItem(
            title: "Combine subscription",
            subtitle: "ObservableObject .sink captures self",
            framework: "SwiftUI",
            make: { CombineSubscriptionView.host() }
        ),
        MenuItem(
            title: "Singleton retention",
            subtitle: "Model registered with shared manager, never deregisters",
            framework: "SwiftUI",
            make: { SingletonRetentionView.host() }
        )
    ]
}
