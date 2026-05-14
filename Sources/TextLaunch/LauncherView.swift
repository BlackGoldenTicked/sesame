import AppKit
import SwiftUI

struct LauncherView: View {
    @ObservedObject var model: LauncherModel
    @ObservedObject var settings: AppSettings
    let close: () -> Void
    let openSettings: () -> Void
    let openCustomGroupEditor: (CustomGroup?) -> Void

    @FocusState private var searchFieldFocused: Bool

    private let tileColumns = [
        GridItem(.adaptive(minimum: 96, maximum: 120), spacing: 18, alignment: .top)
    ]

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
            background

            VStack(spacing: 18) {
                toolbar

                if model.filteredApplications.isEmpty {
                    emptyState
                } else {
                    applicationGrid
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .onAppear { searchFieldFocused = true }
        .onChange(of: model.focusRequest) { _ in searchFieldFocused = true }
    }

    private var background: some View {
        ZStack {
            VisualEffectBackground(material: .underWindowBackground, blendingMode: .behindWindow)
            Color.black.opacity(0.55)
        }
        .ignoresSafeArea()
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 10) {
            Spacer(minLength: 0)

            searchField

            if !settings.customGroups.isEmpty {
                modeToggle
            }

            Button {
                openSettings()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 30, height: 30)
                    .background(
                        Circle().fill(Color.white.opacity(0.08))
                    )
                    .overlay(
                        Circle().strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
                    )
            }
            .buttonStyle(.plain)
            .help("Settings")

            Spacer(minLength: 0)
        }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))

            TextField("", text: $model.searchText, prompt: Text("Search").foregroundColor(.white.opacity(0.5)))
                .textFieldStyle(.plain)
                .focused($searchFieldFocused)
                .onExitCommand { close() }
                .foregroundStyle(.white)
                .tint(.white)
                .font(.system(size: 14))

            if !model.searchText.isEmpty {
                Button {
                    model.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Color.white.opacity(0.16), lineWidth: 0.5)
        )
        .frame(width: 280)
    }

    private var modeToggle: some View {
        Button {
            settings.sortMode = settings.sortMode == .alphabetical ? .customGroups : .alphabetical
        } label: {
            Image(systemName: settings.sortMode == .alphabetical ? "textformat.abc" : "rectangle.stack")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .frame(width: 30, height: 30)
                .background(
                    Circle().fill(Color.white.opacity(0.08))
                )
                .overlay(
                    Circle().strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .help(settings.sortMode == .alphabetical ? "Switch to Groups" : "Switch to Alphabetical")
    }

    // MARK: - Grid

    private var applicationGrid: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 26) {
                ForEach(model.displayGroups) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        if shouldShowHeader(for: group) {
                            sectionHeader(for: group)
                        }

                        LazyVGrid(columns: tileColumns, alignment: .leading, spacing: 18) {
                            ForEach(group.applications) { app in
                                LaunchpadTile(application: app, font: tileFont) {
                                    close()
                                    model.open(app)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .scrollContentBackground(.hidden)
    }

    private func shouldShowHeader(for group: DisplayGroup) -> Bool {
        if group.isLetterIndex {
            // Only show letter headers when not searching, to reduce noise.
            return model.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }

    private var tileFont: Font {
        settings.appFont(weight: .medium)
    }

    private func sectionHeader(for group: DisplayGroup) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(group.title.uppercased())
                .font(.system(.caption, design: group.isLetterIndex ? .monospaced : .default).weight(.semibold))
                .foregroundStyle(.white.opacity(0.55))
                .tracking(0.8)

            if !group.isLetterIndex, let custom = customGroup(for: group) {
                Button {
                    openCustomGroupEditor(custom)
                } label: {
                    Image(systemName: "pencil")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
                .help("Edit Group")
            }

            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private func customGroup(for group: DisplayGroup) -> CustomGroup? {
        guard !group.isLetterIndex else { return nil }
        return settings.customGroups.first { "custom-\($0.id.uuidString)" == group.id }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.white.opacity(0.5))
            Text("No Matches")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.85))
            Text("Try a shorter application name.")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.55))
            Spacer()
        }
    }
}

struct LaunchpadTile: View {
    let application: MacApplication
    let font: Font
    let action: () -> Void

    @State private var hovering = false
    @State private var pressing = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(nsImage: AppIconCache.shared.icon(for: application.url))
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 56)
                    .scaleEffect(pressing ? 0.92 : (hovering ? 1.04 : 1.0))
                    .shadow(color: .black.opacity(hovering ? 0.35 : 0.0), radius: 8, y: 4)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: hovering)
                    .animation(.spring(response: 0.18, dampingFraction: 0.6), value: pressing)

                Text(application.name)
                    .font(font)
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.center)
                    .frame(width: 96)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressing = true }
                .onEnded { _ in pressing = false }
        )
    }
}
