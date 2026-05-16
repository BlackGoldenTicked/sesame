import AppKit
import SwiftUI

struct HotkeyRecorder: View {
    @Binding var hotkey: Hotkey
    let placeholder: String
    let recordingLabel: String

    @State private var recording = false
    @State private var monitor: Any?

    var body: some View {
        Button {
            if recording {
                stop()
            } else {
                start()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "keyboard")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(recording ? Color.accentColor : Color.secondary)

                Text(recording ? recordingLabel : hotkey.displayString)
                    .font(.system(size: 13, weight: .semibold, design: .default))
                    .foregroundStyle(recording ? Color.accentColor : Color.primary)
                    .lineLimit(1)

                Button {
                    hotkey = .default
                    stop()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.secondary.opacity(0.85))
                }
                .buttonStyle(.plain)
                .help(placeholder)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(minWidth: 110)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(
                        recording ? Color.accentColor.opacity(0.6) : Color.primary.opacity(0.12),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onDisappear { stop() }
    }

    private func start() {
        guard monitor == nil else { return }
        recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            if event.type == .flagsChanged { return event }
            if event.keyCode == 53 {
                stop()
                return nil
            }
            let relevant: NSEvent.ModifierFlags = [.command, .option, .control, .shift]
            let mods = event.modifierFlags.intersection(relevant).rawValue
            guard mods != 0 else { return event }
            hotkey = Hotkey(modifiers: mods, keyCode: event.keyCode)
            stop()
            return nil
        }
    }

    private func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        recording = false
    }
}
