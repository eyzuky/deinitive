import UIKit

final class ClosureCycleViewController: UIViewController {
    private let chrome = DemoChromeView(
        title: "Closure cycle",
        blurb: "Each Trigger creates a ChildVM and stores a closure on it. Without [weak self], that closure retains this VC, and this VC retains the ChildVM via its array. Pop this screen and neither side can deinit.",
        fixDescription: "Use [weak self] when the closure captures self"
    )

    private var childModels: [ChildVM] = []
    private var triggerCount = 0

    init() {
        super.init(nibName: nil, bundle: nil)
        title = "Closure cycle"
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
        let child = ChildVM()
        if chrome.fixSwitch.isOn {
            child.handler = { [weak self] in
                self?.handle()
            }
        } else {
            // Default capture is strong: closure retains self.
            // Combined with self.childModels retaining child, this is a cycle.
            child.handler = {
                self.handle()
            }
        }
        childModels.append(child)
        triggerCount += 1
        updateCount()
    }

    private func handle() {}

    private func updateCount() {
        chrome.liveCountLabel.text = """
            this session: \(triggerCount) trigger(s)
            live ChildVM globally: \(LiveCounter.shared.count("ChildVM"))
            """
    }

    deinit {
        print("ClosureCycleViewController deinit")
    }
}

final class ChildVM {
    var handler: (() -> Void)?

    init() {
        LiveCounter.shared.increment("ChildVM")
    }

    deinit {
        LiveCounter.shared.decrement("ChildVM")
        print("ChildVM deinit")
    }
}
