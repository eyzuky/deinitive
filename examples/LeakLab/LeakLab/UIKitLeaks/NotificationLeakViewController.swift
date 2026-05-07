import UIKit

final class NotificationLeakViewController: UIViewController {
    private let chrome = DemoChromeView(
        title: "Notification observer",
        blurb: "Block-based addObserver(forName:object:queue:using:) returns an opaque token; the closure captures self. NotificationCenter holds it forever unless you removeObserver(token). Forget that, and self outlives the back button.",
        fixDescription: "Use selector-based observer + removeObserver(self) in deinit"
    )

    private var blockTokens: [NSObjectProtocol] = []
    private var workloads: [Workload] = []
    private var triggerCount = 0
    private static let notificationName = Notification.Name("LeakLab.demo2.tick")

    init() {
        super.init(nibName: nil, bundle: nil)
        title = "Notification observer"
    }

    @available(*, unavailable) required init?(coder: NSCoder) { fatalError("not used") }

    override func loadView() { view = chrome }

    override func viewDidLoad() {
        super.viewDidLoad()
        chrome.triggerButton.addTarget(self, action: #selector(trigger), for: .touchUpInside)
        updateCount()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateCount()
    }

    @objc private func trigger() {
        let work = Workload()
        if chrome.fixSwitch.isOn {
            // Selector-based observer: no closure, no capture.
            // removeObserver(self) in deinit removes all selector-based observers added with self.
            workloads.append(work)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleNotification),
                name: Self.notificationName,
                object: nil
            )
        } else {
            // Block-based observer: the closure captures self AND the workload strongly.
            // Token never released, so the closure (and self, and workload) live forever.
            let token = NotificationCenter.default.addObserver(
                forName: Self.notificationName,
                object: nil,
                queue: nil
            ) { [work] _ in
                _ = work        // explicit strong capture so the workload is pinned
                self.handle()   // implicit strong capture of self
            }
            blockTokens.append(token)
        }
        triggerCount += 1
        updateCount()
    }

    @objc private func handleNotification() { handle() }
    private func handle() {}

    private func updateCount() {
        chrome.liveCountLabel.text = """
            this session: \(triggerCount) trigger(s)
            live Workload globally: \(LiveCounter.shared.count("Workload"))
            """
    }

    deinit {
        // Selector-based observers added with self are removed by this single call.
        // In the broken path this never runs because the closure pinned us.
        NotificationCenter.default.removeObserver(self)
        print("NotificationLeakViewController deinit")
    }
}

final class Workload {
    init() { LiveCounter.shared.increment("Workload") }
    deinit {
        LiveCounter.shared.decrement("Workload")
        print("Workload deinit")
    }
}
