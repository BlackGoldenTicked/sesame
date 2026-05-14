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
            AppTheme.canvas.ignoresSafeArea()

            VStack(spacing: 12) {
                header

                appsScroll

                collectionDock
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)

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
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(initialGroup == nil ? "New Group" : "Edit Group")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(AppTheme.body)
                Text("Tap apps to collect them into the dock")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.mutedStrong)
            }

            Spacer()

            TextField("Group name", text: $groupName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 240)

            Button("Cancel", action: onCancel)
                .buttonStyle(SecondaryButtonStyle())
                .keyboardShortcut(.escape, modifiers: [])

            Button {
                let trimmed = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
                let resolvedName = trimmed.isEmpty ? "Untitled" : trimmed
                let id = initialGroup?.id ?? UUID()
                onSave(CustomGroup(id: id, name: resolvedName, appPaths: selectedPaths))
            } label: {
                Text("Save Group")
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .foregroundStyle(AppTheme.onPrimary)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(AppTheme.primary)
                    )
            }
            .buttonStyle(.plain)
            .disabled(selectedPaths.isEmpty)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppTheme.elevated, lineWidth: 1)
        }
    }

    private var appsScroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(letterGroups) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(group.title)
                                .font(settings.sectionFont())
                                .foregroundStyle(AppTheme.primary)
                            Text("\(group.applications.count)")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundStyle(AppTheme.mutedStrong)
                            Spacer()
                        }

                        FlowLayout(spacing: 6, lineSpacing: 6) {
                            ForEach(group.applications) { app in
                                let selected = selectedPaths.contains(app.url.path)
                                EditorAppTile(
                                    title: app.name,
                                    font: settings.appFont(weight: .semibold),
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
            .padding(12)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(AppTheme.elevated, lineWidth: 1)
            }
        }
        .frame(maxHeight: .infinity)
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
        HStack(alignment: .center, spacing: 10) {
            minerCharacter

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    if selectedPaths.isEmpty {
                        Text("Tap an app above to collect it")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.mutedStrong)
                            .padding(.horizontal, 6)
                    } else {
                        ForEach(Array(selectedPaths.enumerated()), id: \.offset) { index, path in
                            if let app = model.applications.first(where: { $0.url.path == path }) {
                                DockedAppChip(
                                    title: app.name,
                                    font: settings.appFont(weight: .semibold),
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
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .frame(minHeight: 80)
        .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppTheme.accent.opacity(0.4), lineWidth: 1)
        }
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
        VStack(spacing: 2) {
            Text("⛏️")
                .font(.system(size: 24))
                .rotationEffect(.degrees(minerBob ? -25 : 0), anchor: .bottomTrailing)
                .animation(.spring(response: 0.4, dampingFraction: 0.5), value: minerBob)
            Text("👷")
                .font(.system(size: 30))
                .offset(y: minerBob ? -3 : 0)
                .animation(.spring(response: 0.45, dampingFraction: 0.55), value: minerBob)
        }
        .frame(width: 60, height: 70)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppTheme.surface)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.accent.opacity(0.6), lineWidth: 1)
        }
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
        let end = CGPoint(x: endRect.midX, y: endRect.midY - 8)
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

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                }
                Text(title)
                    .font(font)
                    .foregroundStyle(selected ? AppTheme.accent : AppTheme.body)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .fixedSize(horizontal: true, vertical: false)
            .frame(minHeight: 30)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(selected ? AppTheme.accent.opacity(0.12) : AppTheme.panel)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(selected ? AppTheme.accent.opacity(0.6) : AppTheme.elevated, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
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
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(canMoveLeft ? AppTheme.body : AppTheme.muted)
            }
            .buttonStyle(.plain)
            .disabled(!canMoveLeft)

            Text(title)
                .font(font)
                .foregroundStyle(AppTheme.body)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

            Button(action: onMoveRight) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(canMoveRight ? AppTheme.body : AppTheme.muted)
            }
            .buttonStyle(.plain)
            .disabled(!canMoveRight)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.mutedStrong)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(AppTheme.surface)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(AppTheme.accent.opacity(0.45), lineWidth: 1)
        }
    }
}

private struct FlyingView: View {
    let token: FlyingToken
    let onComplete: () -> Void

    @State private var atEnd = false

    var body: some View {
        Text(token.name)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(AppTheme.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(AppTheme.surface)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(AppTheme.accent, lineWidth: 1.4)
            }
            .shadow(color: AppTheme.accent.opacity(0.45), radius: atEnd ? 1 : 8)
            .scaleEffect(atEnd ? 0.35 : 1.0)
            .opacity(atEnd ? 0.0 : 1.0)
            .position(atEnd ? token.end : token.start)
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.easeIn(duration: 0.55)) {
                    atEnd = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete()
                }
            }
    }
}
