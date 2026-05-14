import AppKit
import SwiftUI

struct LauncherView: View {
    @ObservedObject var model: LauncherModel
    @ObservedObject var settings: AppSettings
    let close: () -> Void
    let openSettings: () -> Void
    let openCustomGroupEditor: (CustomGroup?) -> Void

    init(
        model: LauncherModel,
        close: @escaping () -> Void,
        openSettings: @escaping () -> Void,
        openCustomGroupEditor: @escaping (CustomGroup?) -> Void
    ) {
        self.model = model
        self.settings = model.settings
        self.close = close
        self.openSettings = openSettings
        self.openCustomGroupEditor = openCustomGroupEditor
    }

    var body: some View {
        ZStack {
            AppTheme.canvas.ignoresSafeArea()

            VStack(spacing: 12) {
                header

                if model.filteredApplications.isEmpty {
                    emptyState
                } else {
                    applicationList
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 16)
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Applications")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(AppTheme.body)

                    Text("Text-only launcher")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.mutedStrong)
                }

                MetricPill(value: model.filteredApplications.count, label: "apps")

                modePicker

                Spacer(minLength: 12)

                SearchField(text: $model.searchText, focusRequest: model.focusRequest, onEscape: close)

                Button("Settings", action: openSettings)
                    .buttonStyle(SecondaryButtonStyle())

                Button("Close", action: close)
                    .buttonStyle(SecondaryButtonStyle())
                    .keyboardShortcut(.escape, modifiers: [])
            }

            Rectangle()
                .fill(AppTheme.elevated)
                .frame(height: 1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppTheme.elevated, lineWidth: 1)
        }
    }

    private var modePicker: some View {
        HStack(spacing: 4) {
            ForEach(SortMode.allCases) { mode in
                Button {
                    settings.sortMode = mode
                } label: {
                    Text(mode.title)
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .foregroundStyle(settings.sortMode == mode ? AppTheme.onPrimary : AppTheme.body)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(settings.sortMode == mode ? AppTheme.primary : AppTheme.surface)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .stroke(AppTheme.elevated, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }

            if settings.sortMode == .customGroups {
                Button {
                    openCustomGroupEditor(nil)
                } label: {
                    Text("+ Group")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .foregroundStyle(AppTheme.accent)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(AppTheme.surface)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .stroke(AppTheme.accent.opacity(0.5), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var applicationList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(model.displayGroups) { group in
                    GroupSectionView(
                        group: group,
                        settings: settings,
                        onSelect: { app in
                            close()
                            model.open(app)
                        },
                        onEditGroup: { editable in
                            openCustomGroupEditor(editable)
                        }
                    )
                }
            }
            .padding(8)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(AppTheme.elevated, lineWidth: 1)
            }
            .padding(.bottom, 12)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()

            Text("No Matches")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(AppTheme.body)

            Text("Try a shorter application name.")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(AppTheme.mutedStrong)

            Spacer()
        }
    }
}

private struct GroupSectionView: View {
    let group: DisplayGroup
    @ObservedObject var settings: AppSettings
    let onSelect: (MacApplication) -> Void
    let onEditGroup: (CustomGroup?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(group.title)
                    .font(.system(size: 11, weight: group.isLetterIndex ? .heavy : .bold, design: group.isLetterIndex ? .monospaced : .default))
                    .foregroundStyle(group.isLetterIndex ? AppTheme.primary : AppTheme.body)

                Text("\(group.applications.count)")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(AppTheme.mutedStrong)

                if !group.isLetterIndex, let custom = customGroup(for: group) {
                    Button {
                        onEditGroup(custom)
                    } label: {
                        Text("edit")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppTheme.mutedStrong)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(.horizontal, 4)

            FlowLayout(spacing: 4, lineSpacing: 4) {
                ForEach(group.applications) { app in
                    AppTextTile(
                        title: app.name,
                        font: settings.appFont(weight: .semibold)
                    ) {
                        onSelect(app)
                    }
                }
            }
        }
    }

    private func customGroup(for group: DisplayGroup) -> CustomGroup? {
        guard !group.isLetterIndex else { return nil }
        return settings.customGroups.first { "custom-\($0.id.uuidString)" == group.id }
    }
}

struct AppTextTile: View {
    let title: String
    let font: Font
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(font)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(AppTheme.body)
                .fixedSize(horizontal: true, vertical: false)
                .frame(minHeight: 26)
                .padding(.horizontal, 8)
                .contentShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
        .buttonStyle(CompactAppButtonStyle())
    }
}

private struct MetricPill: View {
    let value: Int
    let label: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 7) {
            Text("\(value)")
                .font(.system(size: 17, weight: .semibold, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(AppTheme.primary)

            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.mutedStrong)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(AppTheme.elevated, lineWidth: 1)
        }
    }
}

private struct SearchField: View {
    @Binding var text: String
    let focusRequest: Int
    let onEscape: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("Search")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.mutedStrong)

            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text("Type an app name")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(AppTheme.muted)
                        .allowsHitTesting(false)
                }

                NativeSearchInput(text: $text, focusRequest: focusRequest, onEscape: onEscape)
                    .frame(height: 22)
            }
        }
        .padding(.horizontal, 10)
        .frame(width: 300, height: 34)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(AppTheme.elevated, lineWidth: 1)
        }
    }
}

struct CompactAppButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(configuration.isPressed ? AppTheme.onPrimary : AppTheme.body)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(configuration.isPressed ? AppTheme.primary : AppTheme.panel)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(configuration.isPressed ? AppTheme.primaryActive : AppTheme.elevated, lineWidth: 1)
            }
            .transaction { transaction in
                transaction.animation = nil
            }
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(configuration.isPressed ? AppTheme.body.opacity(0.68) : AppTheme.body)
            .frame(height: 34)
            .padding(.horizontal, 13)
            .background(configuration.isPressed ? AppTheme.elevated : AppTheme.surface, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(AppTheme.elevated, lineWidth: 1)
            }
    }
}

private struct NativeSearchInput: NSViewRepresentable {
    @Binding var text: String
    let focusRequest: Int
    let onEscape: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onEscape: onEscape)
    }

    func makeNSView(context: Context) -> SearchTextView {
        let view = SearchTextView()
        view.delegate = context.coordinator
        view.onEscape = onEscape
        view.string = text
        view.drawsBackground = false
        view.isRichText = false
        view.importsGraphics = false
        view.isAutomaticQuoteSubstitutionEnabled = false
        view.isAutomaticDashSubstitutionEnabled = false
        view.isAutomaticSpellingCorrectionEnabled = false
        view.isContinuousSpellCheckingEnabled = false
        view.allowsUndo = true
        view.textColor = NSColor(hex: 0x273036)
        view.insertionPointColor = NSColor(hex: 0x4F5F68)
        view.selectedTextAttributes = [
            .backgroundColor: NSColor(hex: 0xD9DED8),
            .foregroundColor: NSColor(hex: 0x273036)
        ]
        view.font = NSFont.systemFont(ofSize: 14, weight: .regular)
        view.textContainerInset = NSSize(width: 0, height: 3)
        view.textContainer?.lineFragmentPadding = 0
        view.textContainer?.maximumNumberOfLines = 1
        view.textContainer?.lineBreakMode = .byTruncatingTail
        view.isHorizontallyResizable = false
        view.isVerticallyResizable = false
        view.autoresizingMask = [.width]
        context.coordinator.lastFocusRequest = focusRequest

        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }

        return view
    }

    func updateNSView(_ view: SearchTextView, context: Context) {
        if view.string != text {
            view.string = text
        }

        view.onEscape = onEscape

        if context.coordinator.lastFocusRequest != focusRequest {
            context.coordinator.lastFocusRequest = focusRequest
            DispatchQueue.main.async {
                view.window?.makeFirstResponder(view)
                view.setSelectedRange(NSRange(location: view.string.utf16.count, length: 0))
            }
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        @Binding var text: String
        var lastFocusRequest = 0
        let onEscape: () -> Void

        init(text: Binding<String>, onEscape: @escaping () -> Void) {
            _text = text
            self.onEscape = onEscape
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else {
                return
            }

            text = textView.string.replacingOccurrences(of: "\n", with: "")
        }
    }
}

private final class SearchTextView: NSTextView {
    var onEscape: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let key = event.charactersIgnoringModifiers?.lowercased()

        if event.keyCode == 53 {
            onEscape?()
            return
        }

        if key == "a", flags.contains(.control) || flags.contains(.command) {
            selectAll(nil)
            return
        }

        if event.keyCode == 36 || event.keyCode == 76 {
            return
        }

        super.keyDown(with: event)
    }

    override func paste(_ sender: Any?) {
        super.paste(sender)
        string = string.replacingOccurrences(of: "\n", with: " ")
    }
}
