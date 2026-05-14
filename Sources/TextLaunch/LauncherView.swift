import AppKit
import SwiftUI

struct LauncherView: View {
    @ObservedObject var model: LauncherModel
    @ObservedObject var settings: AppSettings
    let close: () -> Void
    let openSettings: () -> Void
    let openCustomGroupEditor: (CustomGroup?) -> Void

    @FocusState private var searchFieldFocused: Bool

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
            VisualEffectBackground(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                toolbar

                if model.filteredApplications.isEmpty {
                    emptyState
                } else {
                    applicationList
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 18)
            .padding(.bottom, 18)
        }
        .onAppear { searchFieldFocused = true }
        .onChange(of: model.focusRequest) { _ in searchFieldFocused = true }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            searchField

            Picker("", selection: $settings.sortMode) {
                ForEach(SortMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()

            if settings.sortMode == .customGroups {
                Button {
                    openCustomGroupEditor(nil)
                } label: {
                    Image(systemName: "rectangle.stack.badge.plus")
                }
                .buttonStyle(.borderless)
                .help("New Group")
            }

            Spacer()

            Text("\(model.filteredApplications.count)")
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(.secondary)

            Button {
                openSettings()
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
            .help("Settings")

            Button {
                close()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])
            .help("Close")
        }
        .font(.system(size: 16, weight: .regular))
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search", text: $model.searchText)
                .textFieldStyle(.plain)
                .focused($searchFieldFocused)
                .onExitCommand { close() }
                .font(.system(size: 14))

            if !model.searchText.isEmpty {
                Button {
                    model.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
        .frame(maxWidth: 360)
    }

    private var applicationList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
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
            .padding(.vertical, 4)
        }
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.secondary)
            Text("No Matches")
                .font(.title3)
                .foregroundStyle(.primary)
            Text("Try a shorter application name.")
                .font(.callout)
                .foregroundStyle(.secondary)
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
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(group.title.uppercased())
                    .font(.system(.caption, design: group.isLetterIndex ? .monospaced : .default).weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)

                Text("\(group.applications.count)")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.tertiary)

                if !group.isLetterIndex, let custom = customGroup(for: group) {
                    Spacer()
                    Button {
                        onEditGroup(custom)
                    } label: {
                        Image(systemName: "pencil")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .help("Edit Group")
                } else {
                    Spacer()
                }
            }
            .padding(.horizontal, 2)

            FlowLayout(spacing: 6, lineSpacing: 6) {
                ForEach(group.applications) { app in
                    AppTextTile(
                        title: app.name,
                        font: settings.appFont(weight: .medium)
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

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(font)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: true, vertical: false)
                .frame(minHeight: 26)
                .padding(.horizontal, 10)
                .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(AppTileButtonStyle(isHovering: isHovering))
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

private struct AppTileButtonStyle: ButtonStyle {
    let isHovering: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(fill(for: configuration))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color(nsColor: .separatorColor).opacity(configuration.isPressed ? 0 : 0.35), lineWidth: 0.5)
            )
            .foregroundStyle(configuration.isPressed ? Color.white : .primary)
            .animation(nil, value: configuration.isPressed)
    }

    private func fill(for configuration: Configuration) -> Color {
        if configuration.isPressed {
            return Color.accentColor
        }
        if isHovering {
            return Color(nsColor: .controlAccentColor).opacity(0.12)
        }
        return Color(nsColor: .controlBackgroundColor).opacity(0.6)
    }
}
