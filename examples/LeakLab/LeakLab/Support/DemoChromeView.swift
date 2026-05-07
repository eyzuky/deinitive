import UIKit

// Shared layout used by every UIKit demo VC. Builds: title, blurb, fix toggle,
// Trigger button, live-count label. Demos read/write `fixSwitch.isOn`,
// add an action to `triggerButton`, and update `liveCountLabel.text`.
final class DemoChromeView: UIView {
    let titleLabel = UILabel()
    let blurbLabel = UILabel()
    let fixSwitch = UISwitch()
    let fixDescriptionLabel = UILabel()
    let triggerButton = UIButton(configuration: .filled())
    let liveCountLabel = UILabel()

    init(title: String, blurb: String, fixDescription: String) {
        super.init(frame: .zero)
        backgroundColor = .systemBackground

        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        titleLabel.numberOfLines = 0

        blurbLabel.text = blurb
        blurbLabel.font = .systemFont(ofSize: 14)
        blurbLabel.textColor = .secondaryLabel
        blurbLabel.numberOfLines = 0

        fixDescriptionLabel.text = fixDescription
        fixDescriptionLabel.font = .systemFont(ofSize: 14)
        fixDescriptionLabel.numberOfLines = 0

        let fixRow = UIStackView(arrangedSubviews: [fixSwitch, fixDescriptionLabel])
        fixRow.axis = .horizontal
        fixRow.spacing = 12
        fixRow.alignment = .center

        var triggerConfig = UIButton.Configuration.filled()
        triggerConfig.title = "Trigger"
        triggerConfig.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)
        triggerButton.configuration = triggerConfig

        liveCountLabel.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        liveCountLabel.textColor = .secondaryLabel
        liveCountLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            blurbLabel,
            fixRow,
            triggerButton,
            liveCountLabel
        ])
        stack.axis = .vertical
        stack.spacing = 18
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not used") }
}
