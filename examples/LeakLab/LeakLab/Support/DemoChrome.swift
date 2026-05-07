import SwiftUI

// SwiftUI mirror of DemoChromeView — same layout shape so demos read consistently
// across frameworks. Bind `fixApplied` to your demo's state; provide `liveCountText`
// and an `onTrigger` callback.
struct DemoChrome: View {
    let title: String
    let blurb: String
    let fixDescription: String
    @Binding var fixApplied: Bool
    let liveCountText: String
    let onTrigger: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(title).font(.title2.weight(.semibold))
            Text(blurb)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Toggle(isOn: $fixApplied) {
                Text(fixDescription).font(.subheadline)
            }
            Button(action: onTrigger) {
                Text("Trigger")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.accentColor)
                    .clipShape(.rect(cornerRadius: 8))
            }
            Text(liveCountText)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
