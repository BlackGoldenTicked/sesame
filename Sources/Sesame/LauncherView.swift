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

            // Ambient color glows — subtle radial tints in three corners
            let ambient = settings.colorTheme.ambientColors
            RadialGradient(
                colors: [
                    (ambient.first ?? .blue).opacity(0.18),
                    Color.clear
                ],
                center: UnitPoint(x: 0.12, y: 0.18),
                startRadius: 0,
                endRadius: 700
            )
            RadialGradient(
                colors: [
                    (ambient.count > 1 ? ambient[1] : .pink).opacity(0.13),
                    Color.clear
                ],
                center: UnitPoint(x: 0.88, y: 0.82),
                startRadius: 0,
                endRadius: 700
            )
            RadialGradient(
                colors: [
                    (ambient.count > 2 ? ambient[2] : .purple).opacity(0.10),
                    Color.clear
                ],
                center: UnitPoint(x: 0.78, y: 0.12),
                startRadius: 0,
                endRadius: 600
            )

            GridLinesOverlay(
                cellSize: CGFloat(settings.gridCellSize),
                color: Color.white.opacity(0.045),
                lineWidth: 0.5
            )
            RadialGradient(
                colors: [Color.clear, Color.black.opacity(0.30)],
                center: .center,
                startRadius: 260,
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

            modeToggle

            gradientPillButton(
                icon: "gearshape.fill",
                help: "Settings"
            ) {
                openSettings()
            }

            Spacer(minLength: 0)
        }
    }

    private var searchField: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(white: 0.35))

            TextField("", text: $model.searchText, prompt: Text("Search").foregroundColor(Color(white: 0.5)))
                .textFieldStyle(.plain)
                .focused($searchFieldFocused)
                .onExitCommand { close() }
                .foregroundStyle(Color(white: 0.12))
                .tint(Color(white: 0.2))
                .font(.system(size: 14, weight: .medium))
                .disabled(model.hintMode)

            if !model.searchText.isEmpty {
                Button {
                    model.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(white: 0.45))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(FrostedPillBackground(blobColors: settings.colorTheme.pillBlobColors))
        .frame(width: 320)
        .opacity(model.hintMode ? 0.55 : 1)
        .animation(.easeInOut(duration: 0.18), value: model.hintMode)
    }

    private var modeToggle: some View {
        gradientPillButton(
            icon: settings.sortMode == .alphabetical ? "textformat" : "square.grid.2x2.fill",
            help: settings.sortMode == .alphabetical ? "Switch to Groups" : "Switch to Alphabetical"
        ) {
            settings.sortMode = settings.sortMode == .alphabetical ? .customGroups : .alphabetical
        }
    }

    private func gradientPillButton(
        icon: String,
        help: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.25), radius: 1, y: 0.5)
                .frame(width: 38, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(settings.colorTheme.toolbarGradient)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.35), lineWidth: 0.6)
                )
                .shadow(color: .black.opacity(0.30), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .help(help)
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

// MARK: - Frosted Pill Background

private struct FrostedPillBackground: View {
    let blobColors: [Color]

    var body: some View {
        Capsule(style: .continuous)
            .fill(.white)
            .overlay(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.95),
                                Color(white: 0.86).opacity(0.95)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(colorBlobs.clipShape(Capsule(style: .continuous)))
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.95),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.35), radius: 14, y: 8)
            .shadow(color: .black.opacity(0.18), radius: 3, y: 1)
    }

    private var colorBlobs: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Circle()
                    .fill(blobColors[safe: 0] ?? Color.blue)
                    .frame(width: w * 0.55, height: w * 0.55)
                    .position(x: w * 0.78, y: -h * 0.05)
                    .blur(radius: 26)
                    .opacity(0.85)

                Circle()
                    .fill(blobColors[safe: 1] ?? Color.pink)
                    .frame(width: w * 0.45, height: w * 0.45)
                    .position(x: w * 0.55, y: h * 1.15)
                    .blur(radius: 30)
                    .opacity(0.75)

                Circle()
                    .fill(blobColors[safe: 2] ?? Color.purple)
                    .frame(width: w * 0.30, height: w * 0.30)
                    .position(x: w * 0.30, y: h * 0.85)
                    .blur(radius: 28)
                    .opacity(0.55)
            }
        }
        .allowsHitTesting(false)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
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
