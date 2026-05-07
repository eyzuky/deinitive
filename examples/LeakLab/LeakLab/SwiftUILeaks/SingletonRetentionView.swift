import SwiftUI
import UIKit

struct SingletonRetentionView: View {
    @State private var fixApplied: Bool = false
    @State private var triggerCount: Int = 0
    @State private var subjects: [Subject] = []

    var body: some View {
        DemoChrome(
            title: "Singleton retention",
            blurb: "Each Trigger creates a Subject and registers it with LeakyManager.shared. Without explicit deregistration, the singleton's array keeps every Subject alive after this view goes away.",
            fixDescription: "Deregister from the singleton on view disappear",
            fixApplied: $fixApplied,
            liveCountText: """
                this session: \(triggerCount) subject(s)
                live Subject globally: \(LiveCounter.shared.count("Subject"))
                manager holds: \(LeakyManager.shared.registeredCount())
                """,
            onTrigger: {
                let s = Subject()
                LeakyManager.shared.register(s)
                subjects.append(s)
                triggerCount += 1
            }
        )
        .onDisappear {
            if fixApplied {
                for s in subjects { LeakyManager.shared.deregister(s) }
            }
            // Else: subjects remain in the singleton's array → leak.
        }
    }
}

extension SingletonRetentionView {
    static func host() -> UIViewController {
        let vc = UIHostingController(rootView: SingletonRetentionView())
        vc.title = "Singleton retention"
        return vc
    }
}

final class LeakyManager: @unchecked Sendable {
    static let shared = LeakyManager()
    private let lock = NSLock()
    private var registered: [Subject] = []

    private init() {}

    func register(_ subject: Subject) {
        lock.lock(); defer { lock.unlock() }
        registered.append(subject)
    }

    func deregister(_ subject: Subject) {
        lock.lock(); defer { lock.unlock() }
        registered.removeAll { $0 === subject }
    }

    func registeredCount() -> Int {
        lock.lock(); defer { lock.unlock() }
        return registered.count
    }
}

final class Subject {
    init() { LiveCounter.shared.increment("Subject") }
    deinit {
        LiveCounter.shared.decrement("Subject")
        print("Subject deinit")
    }
}
