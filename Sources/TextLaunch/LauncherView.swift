import AppKit
import SwiftUI

struct LauncherView: View {
    @ObservedObject var model: LauncherModel
    @ObservedObject var settings: AppSettings
    let close: () -> Void
    let openSettings: () -> Void
    let openCustomGroupEditor: (CustomGroup?) -> Void

    @FocusState private var searchFieldFocused: Bool

    private var metrics: TileMetrics { settings.tileMetrics }

    private var tileColumns: [GridItem] {
        let m = metrics
        return [
            GridItem(.adaptive(minimum: m.tileWidth, maximum: m.tileWidth + 16), spacing: m.spacing, alignment: .top)
        ]
    }

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

            if model.hintMode {
                hintHud
                    .transition(.opacity)
            }
        }
        .onAppear {
            searchFieldFocused = true
        }
        .onChange(of: model.focusRequest) { _ in
            if !model.hintMode && !searchFieldFocused {
                searchFieldFocused = true
            }
        }
        .onChange(of: model.hintMode) { isOn in
            if isOn {
                searchFieldFocused = false
            } else {
                searchFieldFocused = true
            }
        }
    }

    private var background: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.085)
            GridLinesOverlay(
                cellSize: CGFloat(settings.gridCellSize),
                color: Color.white.opacity(0.045),
                lineWidth: 0.5
            )
            RadialGradient(
                colors: [Color.clear, Color.black.opacity(0.35)],
                center: .center,
                startRadius: 220,
                endRadius: 1200
            )
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
                .disabled(model.hintMode)

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
                .fill(Color.white.opacity(model.hintMode ? 0.04 : 0.08))
        )
        .overlay(
            FlowingBorder(active: !model.hintMode)
        )
        .frame(width: 280)
        .opacity(model.hintMode ? 0.55 : 1)
        .animation(.easeInOut(duration: 0.18), value: model.hintMode)
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
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 26) {
                ForEach(model.displayGroups) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        if shouldShowHeader(for: group) {
                            sectionHeader(for: group)
                        }

                        LazyVGrid(columns: tileColumns, alignment: .leading, spacing: metrics.rowSpacing) {
                            ForEach(group.applications) { app in
                                LaunchpadTile(
                                    application: app,
                                    font: tileFont,
                                    metrics: metrics,
                                    hintCode: model.hintMode ? model.hintCodes[app.url.path] : nil,
                                    hintMatchedPrefix: model.hintMode ? model.hintBuffer : ""
                                ) {
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

    private var hintHud: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "keyboard")
                    .font(.system(size: 11, weight: .semibold))
                Text(model.hintBuffer.isEmpty ? "Hint mode · \(settings.hintHotkey.displayString) · type letters · Esc to exit" : "Typed: \(model.hintBuffer.uppercased())")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
            }
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color.black.opacity(0.55))
            )
            .overlay(
                Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
            )
            .padding(.bottom, 18)
        }
    }

}

// MARK: - Tile

struct LaunchpadTile: View {
    let application: MacApplication
    let font: Font
    let metrics: TileMetrics
    var hintCode: String? = nil
    var hintMatchedPrefix: String = ""
    let action: () -> Void

    @State private var hovering = false
    @State private var pressing = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: metrics.textVerticalSpacing) {
                Image(nsImage: AppIconCache.shared.icon(for: application.url))
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: metrics.iconSize, height: metrics.iconSize)
                    .scaleEffect(pressing ? 0.92 : (hovering ? 1.04 : 1.0))
                    .shadow(color: .black.opacity(hovering ? 0.35 : 0.0), radius: 8, y: 4)
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: hovering)
                    .animation(.spring(response: 0.18, dampingFraction: 0.6), value: pressing)
                    .overlay(alignment: .topTrailing) {
                        if let code = hintCode {
                            HintBadge(code: code, matchedPrefix: hintMatchedPrefix)
                                .offset(x: 6, y: -6)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }

                Text(application.name)
                    .font(font)
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.center)
                    .frame(width: metrics.textWidth)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 6)
            .frame(width: metrics.tileWidth)
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

// MARK: - Hint Badge

private struct HintBadge: View {
    let code: String
    let matchedPrefix: String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(code.enumerated()), id: \.offset) { _, char in
                Text(String(char).uppercased())
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundStyle(isMatched(char) ? Color.black : Color.white)
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(backgroundFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.5), radius: 4, y: 1)
    }

    private var backgroundFill: LinearGradient {
        LinearGradient(
            colors: [Color(red: 1.0, green: 0.92, blue: 0.35), Color(red: 1.0, green: 0.75, blue: 0.2)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func isMatched(_ char: Character) -> Bool {
        guard !matchedPrefix.isEmpty else { return false }
        let codeLower = code.lowercased()
        let prefixLower = matchedPrefix.lowercased()
        guard codeLower.hasPrefix(prefixLower) else { return false }
        if let index = codeLower.firstIndex(of: Character(char.lowercased())) {
            return codeLower.distance(from: codeLower.startIndex, to: index) < prefixLower.count
        }
        return false
    }
}

// MARK: - Animated Border

private struct FlowingBorder: View {
    var active: Bool = true

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !active)) { context in
            let time = context.date.timeIntervalSinceReferenceDate
            let angle = Angle.degrees(time.truncatingRemainder(dividingBy: 3.0) / 3.0 * 360.0)

            Capsule(style: .continuous)
                .strokeBorder(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.30, green: 0.85, blue: 1.00),
                            Color(red: 0.60, green: 0.40, blue: 1.00),
                            Color(red: 1.00, green: 0.35, blue: 0.78),
                            Color(red: 0.25, green: 0.95, blue: 0.78),
                            Color(red: 0.30, green: 0.85, blue: 1.00)
                        ]),
                        center: .center,
                        angle: angle
                    ),
                    lineWidth: active ? 1.4 : 0.6
                )
                .opacity(active ? 1.0 : 0.35)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Grid Lines Background

private struct GridLinesOverlay: View {
    let cellSize: CGFloat
    let color: Color
    let lineWidth: CGFloat

    var body: some View {
        Canvas { context, size in
            let stroke = GraphicsContext.Shading.color(color)

            var x: CGFloat = 0
            while x <= size.width {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: stroke, lineWidth: lineWidth)
                x += cellSize
            }

            var y: CGFloat = 0
            while y <= size.height {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: stroke, lineWidth: lineWidth)
                y += cellSize
            }
        }
        .allowsHitTesting(false)
    }
}
