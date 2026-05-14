import AppKit
import SwiftUI

private struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

private struct FlyingToken: Identifiable {
    let id = UUID()
    let name: String
    let appPath: String
    let start: CGPoint
    let end: CGPoint
}

struct CustomGroupEditorView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var model: LauncherModel

    let initialGroup: CustomGroup?
    let onSave: (CustomGroup) -> Void
    let onCancel: () -> Void

    @State private var groupName: String = ""
    @State private var selectedPaths: [String] = []
    @State private var framesByKey: [String: CGRect] = [:]
    @State private var flying: [FlyingToken] = []
    @State private var minerBob: Bool = false

    private static let coordinateSpace = "groupEditor"
    private static let boxKey = "__collectionBox__"

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(nsColor: .windowBackgroundColor).ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Divider()

                appsScroll

                Divider()

                collectionDock
            }

            ForEach(flying) { token in
                FlyingView(token: token) {
                    flying.removeAll { $0.id == token.id }
                    if !selectedPaths.contains(token.appPath) {
                        selectedPaths.append(token.appPath)
                    }
                    triggerMinerBob()
                }
            }
        }
        .coordinateSpace(name: Self.coordinateSpace)
        .onPreferenceChange(FramePreferenceKey.self) { value in
            framesByKey = value
        }
        .onAppear(perform: loadInitial)
        .frame(minWidth: 880, minHeight: 600)
    }

    private func loadInitial() {
        if let group = initialGroup {
            groupName = group.name
            selectedPaths = group.appPaths
        } else {
            groupName = ""
            selectedPaths = []
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            TextField("Group name", text: $groupName)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 260)

            Spacer()

            Text("\(selectedPaths.count) selected")
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(.secondary)

            Button("Cancel", role: .cancel, action: onCancel)
                .keyboardShortcut(.escape, modifiers: [])

            Button {
                let trimmed = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
                let resolvedName = trimmed.isEmpty ? "Untitled" : trimmed
                let id = initialGroup?.id ?? UUID()
                onSave(CustomGroup(id: id, name: resolvedName, appPaths: selectedPaths))
            } label: {
                Text("Save")
            }
            .keyboardShortcut(.defaultAction)
            .buttonStyle(.borderedProminent)
            .disabled(selectedPaths.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.bar)
    }

    private var appsScroll: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                ForEach(letterGroups) { group in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(group.title.uppercased())
                            .font(.system(.caption, design: .monospaced).weight(.semibold))
                            .foregroundStyle(.secondary)
                            .tracking(0.6)
                            .padding(.horizontal, 2)

                        FlowLayout(spacing: 6, lineSpacing: 6) {
                            ForEach(group.applications) { app in
                                let selected = selectedPaths.contains(app.url.path)
                                EditorAppTile(
                                    title: app.name,
                                    font: settings.appFont(weight: .medium),
                                    selected: selected
                                ) {
                                    handleTap(app: app, selected: selected)
                                }
                                .background(
                                    GeometryReader { proxy in
                                        Color.clear.preference(
                                            key: FramePreferenceKey.self,
                                            value: [app.url.path: proxy.frame(in: .named(Self.coordinateSpace))]
                                        )
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .scrollContentBackground(.hidden)
    }

    private var letterGroups: [DisplayGroup] {
        let apps = model.visibleApplications
        let grouped = Dictionary(grouping: apps) { app -> String in
            guard let first = app.name.unicodeScalars.first else { return "#" }
            let title = String(Character(first)).uppercased()
            return CharacterSet.letters.contains(first) ? title : "#"
        }
        return grouped.map { title, applications in
            let sorted = applications.sorted {
                $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
            return DisplayGroup(
                id: "letter-\(title)",
                title: title,
                applications: sorted,
                isLetterIndex: true
            )
        }
        .sorted { left, right in
            if left.title == "#" { return false }
            if right.title == "#" { return true }
            return left.title.localizedStandardCompare(right.title) == .orderedAscending
        }
    }

    private var collectionDock: some View {
        HStack(alignment: .center, spacing: 12) {
            minerCharacter

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    if selectedPaths.isEmpty {
                        Text("Tap an app above to collect it")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                    } else {
                        ForEach(Array(selectedPaths.enumerated()), id: \.offset) { index, path in
                            if let app = model.applications.first(where: { $0.url.path == path }) {
                                DockedAppChip(
                                    title: app.name,
                                    font: settings.appFont(weight: .medium),
                                    canMoveLeft: index > 0,
                                    canMoveRight: index < selectedPaths.count - 1,
                                    onMoveLeft: { move(from: index, to: index - 1) },
                                    onMoveRight: { move(from: index, to: index + 1) },
                                    onRemove: { remove(at: index) }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minHeight: 76)
        .background(.bar)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: FramePreferenceKey.self,
                    value: [Self.boxKey: proxy.frame(in: .named(Self.coordinateSpace))]
                )
            }
        )
    }

    private var minerCharacter: some View {
        VStack(spacing: 0) {
            Text("⛏️")
                .font(.system(size: 22))
                .rotationEffect(.degrees(minerBob ? -25 : 0), anchor: .bottomTrailing)
                .animation(.spring(response: 0.4, dampingFraction: 0.5), value: minerBob)
            Text("👷")
                .font(.system(size: 26))
                .offset(y: minerBob ? -2 : 0)
                .animation(.spring(response: 0.45, dampingFraction: 0.55), value: minerBob)
        }
        .frame(width: 52, height: 56)
    }

    private func handleTap(app: MacApplication, selected: Bool) {
        if selected {
            selectedPaths.removeAll { $0 == app.url.path }
            return
        }
        guard
            let startRect = framesByKey[app.url.path],
            let endRect = framesByKey[Self.boxKey]
        else {
            if !selectedPaths.contains(app.url.path) {
                selectedPaths.append(app.url.path)
            }
            triggerMinerBob()
            return
        }
        let start = CGPoint(x: startRect.midX, y: startRect.midY)
        let end = CGPoint(x: endRect.midX, y: endRect.midY - 6)
        flying.append(
            FlyingToken(
                name: app.name,
                appPath: app.url.path,
                start: start,
                end: end
            )
        )
    }

    private func triggerMinerBob() {
        minerBob = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            minerBob = false
        }
    }

    private func move(from source: Int, to destination: Int) {
        guard source >= 0, source < selectedPaths.count else { return }
        guard destination >= 0, destination < selectedPaths.count else { return }
        let item = selectedPaths.remove(at: source)
        selectedPaths.insert(item, at: destination)
    }

    private func remove(at index: Int) {
        guard index >= 0, index < selectedPaths.count else { return }
        selectedPaths.remove(at: index)
    }
}

private struct EditorAppTile: View {
    let title: String
    let font: Font
    let selected: Bool
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                }
                Text(title)
                    .font(font)
                    .foregroundStyle(selected ? Color.accentColor : .primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .fixedSize(horizontal: true, vertical: false)
            .frame(minHeight: 26)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }

    private var fill: Color {
        if selected { return Color.accentColor.opacity(0.14) }
        if hovering { return Color(nsColor: .controlAccentColor).opacity(0.1) }
        return Color(nsColor: .controlBackgroundColor).opacity(0.6)
    }

    private var borderColor: Color {
        if selected { return Color.accentColor.opacity(0.5) }
        return Color(nsColor: .separatorColor).opacity(0.4)
    }
}

private struct DockedAppChip: View {
    let title: String
    let font: Font
    let canMoveLeft: Bool
    let canMoveRight: Bool
    let onMoveLeft: () -> Void
    let onMoveRight: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Button(action: onMoveLeft) {
                Image(systemName: "chevron.left")
                    .font(.caption2.weight(.semibold))
            }
            .buttonStyle(.borderless)
            .disabled(!canMoveLeft)

            Text(title)
                .font(font)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

            Button(action: onMoveRight) {
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
            }
            .buttonStyle(.borderless)
            .disabled(!canMoveRight)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            Capsule().strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }
}

private struct FlyingView: View {
    let token: FlyingToken
    let onComplete: () -> Void

    @State private var atEnd = false

    var body: some View {
        Text(token.name)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.accentColor.opacity(0.6), lineWidth: 1)
            )
            .scaleEffect(atEnd ? 0.35 : 1.0)
            .opacity(atEnd ? 0.0 : 1.0)
            .position(atEnd ? token.end : token.start)
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.easeIn(duration: 0.5)) {
                    atEnd = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    onComplete()
                }
            }
    }
}
