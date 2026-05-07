import UIKit

final class TimerLeakViewController: UIViewController {
    private let chrome = DemoChromeView(
        title: "Timer retain cycle",
        blurb: "Timer.scheduledTimer(withTimeInterval:repeats:block:) keeps the timer scheduled on the run loop, and the block captures self. Without [weak self] AND timer.invalidate() somewhere, the timer pins this VC forever.",
        fixDescription: "Use [weak self] in the block and invalidate in deinit"
    )

    private var timers: [Timer] = []
    private var workers: [TimerWorker] = []
    private var triggerCount = 0

    init() {
        super.init(nibName: nil, bundle: nil)
        title = "Timer"
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
        let worker = TimerWorker()
        workers.append(worker)
        let timer: Timer
        if chrome.fixSwitch.isOn {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self, weak worker] _ in
                worker?.tick()
                self?.handle()
            }
        } else {
            // Strong capture: the block retains self and the worker.
            // The timer is on the run loop forever, so neither can deinit.
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [worker] _ in
                worker.tick()
                self.handle()
            }
        }
        timers.append(timer)
        triggerCount += 1
        updateCount()
    }

    private func handle() {}

    private func updateCount() {
        chrome.liveCountLabel.text = """
            this session: \(triggerCount) timer(s)
            live TimerWorker globally: \(LiveCounter.shared.count("TimerWorker"))
            """
    }

    deinit {
        for timer in timers { timer.invalidate() }
        print("TimerLeakViewController deinit")
    }
}

final class TimerWorker {
    init() { LiveCounter.shared.increment("TimerWorker") }
    func tick() {}
    deinit {
        LiveCounter.shared.decrement("TimerWorker")
        print("TimerWorker deinit")
    }
}
