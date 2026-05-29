import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var model: LauncherModel
    let onClose: () -> Void
    let onEditGroup: (CustomGroup?) -> Void

    enum Tab: Hashable {
        case general
        case hidden
        case groups
        case about
    }

    @State private var selectedTab: Tab = .general

    private static let sidebarWidth: CGFloat = 240
    private static let detailWidth: CGFloat = 640

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: Self.sidebarWidth)
                .frame(maxHeight: .infinity)
                .background(SidebarBackground())

            Divider()

            detail
                .frame(width: Self.detailWidth, alignment: .top)
                .background(Color(nsColor: .windowBackgroundColor))
        }
        .frame(width: Self.sidebarWidth + Self.detailWidth + 1)
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            sidebarHeader
                .padding(.top, 60)
                .padding(.horizontal, 16)
                .padding(.bottom, 22)

            VStack(spacing: 2) {
                sidebarRow(.general, icon: "gearshape.fill", title: settings.t(.general))
                sidebarRow(.hidden, icon: "eye.slash.fill", title: settings.t(.hidden))
                sidebarRow(.groups, icon: "square.grid.2x2.fill", title: settings.t(.groupsTab))
                sidebarRow(.about, icon: "info.circle.fill", title: settings.t(.about))
            }
            .padding(.horizontal, 10)

            Spacer(minLength: 0)
        }
    }

    private var sidebarHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            appIcon(size: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text(settings.t(.appName))
                    .font(.system(size: 15, weight: .semibold))
                Text("\(settings.t(.version)) \(settings.t(.versionNumber))")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func sidebarRow(_ tab: Tab, icon: String, title: String) -> some View {
        let active = selectedTab == tab
        return Button {
            selectedTab = tab
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 18, alignment: .center)
                    .foregroundStyle(active ? Color.accentColor : Color.secondary)
                Text(title)
                    .font(.system(size: 13, weight: active ? .semibold : .medium))
                    .foregroundStyle(active ? Color.accentColor : Color.primary)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(active ? Color.accentColor.opacity(0.13) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Detail

    @ViewBuilder
    private var detail: some View {
        switch selectedTab {
        case .general:
            DetailContainer { GeneralPage(settings: settings) }
        case .hidden:
            DetailContainer { HiddenAppsPage(settings: settings, model: model) }
        case .groups:
            DetailContainer { GroupsPage(settings: settings, onEditGroup: onEditGroup) }
        case .about:
            DetailContainer { AboutPage(settings: settings) }
        }
    }

    private func appIcon(size: CGFloat) -> some View {
        Group {
            if
                let url = Bundle.appResources?.url(forResource: "logo", withExtension: "png"),
                let image = NSImage(contentsOf: url)
            {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "app.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.tint)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.225, style: .continuous))
        .shadow(color: .black.opacity(0.10), radius: 4, y: 2)
    }
}

// MARK: - Sidebar background (translucent)

private struct SidebarBackground: View {
    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.5)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Detail container

private struct DetailContainer<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, 36)
            .padding(.top, 56)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

// MARK: - Section card

private struct SectionGroup<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.primary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            )
        }
    }
}

// MARK: - Setting row

private struct SettingRow<Trailing: View>: View {
    let label: String
    var subtitle: String? = nil
    var trailingAlignment: VerticalAlignment = .center
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: trailingAlignment, spacing: 16) {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                trailing()
            }
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct RowDivider: View {
    var body: some View {
        Divider().opacity(0.6).padding(.leading, 16)
    }
}

// MARK: - General page

private struct GeneralPage: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            SectionGroup(title: settings.t(.startup)) {
                SettingRow(label: settings.t(.launchAtLogin)) {
                    Toggle("", isOn: $settings.launchAtLogin)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .labelsHidden()
                }
                RowDivider()
                SettingRow(label: settings.t(.language)) {
                    HStack(spacing: 6) {
                        languageButton(.english, label: "EN")
                        languageButton(.chinese, label: "中")
                    }
                }
            }

            SectionGroup(title: settings.t(.hotkeySection)) {
                SettingRow(
                    label: settings.t(.hotkey),
                    subtitle: settings.t(.hotkeyHint)
                ) {
                    HotkeyRecorder(
                        hotkey: $settings.hintHotkey,
                        placeholder: settings.t(.pressKey),
                        recordingLabel: settings.t(.recording)
                    )
                }
            }

            SectionGroup(title: settings.t(.appearance)) {
                SettingRow(label: settings.t(.theme), trailingAlignment: .center) {
                    HStack(spacing: 8) {
                        ForEach(ColorTheme.allCases) { theme in
                            themeSwatch(theme)
                        }
                    }
                }
                RowDivider()
                SettingRow(label: settings.t(.font)) {
                    Picker("", selection: $settings.fontName) {
                        Text(settings.t(.systemDefault)).tag(AppSettings.systemFontName)
                        Divider()
                        ForEach(InstalledFontCatalog.familyNames(), id: \.self) { family in
                            Text(family).tag(family)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 220)
                }
                RowDivider()
                SettingRow(label: settings.t(.textSize)) {
                    HStack(spacing: 6) {
                        textSizeButton(.small, label: settings.t(.small))
                        textSizeButton(.medium, label: settings.t(.medium))
                        textSizeButton(.large, label: settings.t(.large))
                    }
                }
                RowDivider()
                SettingRow(label: settings.t(.gridDensity), trailingAlignment: .center) {
                    VStack(spacing: 2) {
                        TickedSlider(
                            value: $settings.gridCellSize,
                            range: 60...240,
                            tickCount: 19
                        )
                        .frame(width: 280)

                        HStack {
                            Text(settings.t(.compact))
                            Spacer()
                            Text("\(Int(settings.gridCellSize)) px")
                                .monospacedDigit()
                            Spacer()
                            Text(settings.t(.loose))
                        }
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(width: 280)
                    }
                }
            }
        }
    }

    private func themeSwatch(_ theme: ColorTheme) -> some View {
        let active = settings.colorTheme == theme
        return Button {
            settings.colorTheme = theme
        } label: {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: theme.toolbarGradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 46, height: 30)
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(
                            active ? Color.accentColor : Color.primary.opacity(0.12),
                            lineWidth: active ? 2 : 1
                        )
                )
                .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
        }
        .buttonStyle(.plain)
        .help(theme.localizationKey.string(settings.language))
    }

    private func languageButton(_ language: AppLanguage, label: String) -> some View {
        let active = settings.language == language
        return Button {
            settings.language = language
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(active ? Color.accentColor : Color.primary)
                .frame(width: 42, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(active ? Color.accentColor.opacity(0.15) : Color(nsColor: .windowBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(active ? Color.accentColor.opacity(0.55) : Color.primary.opacity(0.12), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .help(language.nativeName)
    }

    private func textSizeButton(_ size: TextSize, label: String) -> some View {
        let active = settings.textSize == size
        return Button {
            settings.textSize = size
        } label: {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(active ? Color.accentColor : Color.primary)
                .frame(width: 42, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(active ? Color.accentColor.opacity(0.15) : Color(nsColor: .windowBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(active ? Color.accentColor.opacity(0.55) : Color.primary.opacity(0.12), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Hidden Apps page

private struct HiddenAppsPage: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var model: LauncherModel

    @State private var hiddenFilter: String = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(settings.t(.filter), text: $hiddenFilter)
                    .textFieldStyle(.plain)
                Spacer()
                Text("\(settings.hiddenAppPaths.count) \(settings.t(.hiddenCount))")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().opacity(0.5)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredApps, id: \.id) { app in
                        HStack(spacing: 12) {
                            Toggle("", isOn: hiddenBinding(for: app))
                                .toggleStyle(.switch)
                                .controlSize(.small)
                                .labelsHidden()
                            VStack(alignment: .leading, spacing: 1) {
                                Text(app.name)
                                    .font(.system(size: 13))
                                Text(app.url.path)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        Divider().opacity(0.4).padding(.leading, 16)
                    }
                }
            }
            .frame(height: 460)
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private var filteredApps: [MacApplication] {
        let trimmed = hiddenFilter.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = model.applications
        guard !trimmed.isEmpty else { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }

    private func hiddenBinding(for app: MacApplication) -> Binding<Bool> {
        Binding(
            get: { settings.hiddenAppPaths.contains(app.url.path) },
            set: { settings.setHidden($0, for: app) }
        )
    }
}

// MARK: - Groups page

private struct GroupsPage: View {
    @ObservedObject var settings: AppSettings
    let onEditGroup: (CustomGroup?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                if settings.customGroups.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 30, weight: .light))
                            .foregroundStyle(.secondary)
                        Text(settings.t(.noGroups))
                            .font(.system(size: 14, weight: .medium))
                        Text(settings.t(.createGroupHint))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(settings.customGroups.enumerated()), id: \.element.id) { index, group in
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(group.name)
                                        .font(.system(size: 13, weight: .medium))
                                    Text("\(group.appPaths.count) apps")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button(settings.t(.edit)) {
                                    onEditGroup(group)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)

                                Button {
                                    settings.removeGroup(id: group.id)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                                .controlSize(.small)
                                .help(settings.t(.delete))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            if index < settings.customGroups.count - 1 {
                                Divider().opacity(0.4).padding(.leading, 16)
                            }
                        }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            )

            HStack {
                Spacer()
                Button {
                    onEditGroup(nil)
                } label: {
                    Label(settings.t(.newGroup), systemImage: "plus")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
        }
    }
}

// MARK: - About page

private struct AboutPage: View {
    @ObservedObject var settings: AppSettings

    private let websiteURL = URL(string: "https://www.chaordex.com")!

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            VStack(spacing: 12) {
                aboutIcon

                Text(settings.t(.appName))
                    .font(.system(size: 26, weight: .bold))

                Text(settings.t(.tagline))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                Text("\(settings.t(.version)) \(settings.t(.versionNumber))")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)

                Button {
                    NSWorkspace.shared.open(websiteURL)
                } label: {
                    HStack(spacing: 4) {
                        Text(settings.t(.visitWebsite))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 32)

            Text(settings.t(.copyright))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var aboutIcon: some View {
        Group {
            if
                let url = Bundle.appResources?.url(forResource: "logo", withExtension: "png"),
                let image = NSImage(contentsOf: url)
            {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "app.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.tint)
            }
        }
        .frame(width: 110, height: 110)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.14), radius: 10, y: 4)
    }
}
