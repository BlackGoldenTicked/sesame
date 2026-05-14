import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var model: LauncherModel
    let onClose: () -> Void
    let onEditGroup: (CustomGroup?) -> Void

    private enum Tab: Hashable {
        case appearance
        case hidden
        case groups
    }

    @State private var selectedTab: Tab = .appearance

    var body: some View {
        TabView(selection: $selectedTab) {
            appearanceTab
                .tabItem {
                    Label("Appearance", systemImage: "textformat")
                }
                .tag(Tab.appearance)

            hiddenAppsTab
                .tabItem {
                    Label("Hidden Apps", systemImage: "eye.slash")
                }
                .tag(Tab.hidden)

            groupsTab
                .tabItem {
                    Label("Groups", systemImage: "square.grid.2x2")
                }
                .tag(Tab.groups)
        }
        .frame(width: 560, height: 460)
    }

    // MARK: - Appearance

    private var appearanceTab: some View {
        Form {
            Section {
                Picker("Font Family", selection: $settings.fontName) {
                    Text("System Default").tag(AppSettings.systemFontName)
                    Divider()
                    ForEach(InstalledFontCatalog.familyNames(), id: \.self) { family in
                        Text(family).tag(family)
                    }
                }

                HStack {
                    Text("Size")
                    Slider(value: $settings.fontSize, in: 10...22, step: 1)
                    Stepper(value: $settings.fontSize, in: 10...22, step: 1) {
                        Text("\(Int(settings.fontSize)) pt")
                            .monospacedDigit()
                            .frame(minWidth: 44, alignment: .trailing)
                    }
                    .labelsHidden()
                }
            } header: {
                Text("Application Font")
            } footer: {
                Text("Affects the app buttons in the launcher and group editor.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Preview") {
                HStack(spacing: 8) {
                    ForEach(previewNames, id: \.self) { name in
                        Text(name)
                            .font(settings.appFont(weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(nsColor: .controlBackgroundColor))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                            )
                    }
                    Spacer()
                }
            }
        }
        .formStyle(.grouped)
    }

    private var previewNames: [String] {
        let pool = model.visibleApplications.prefix(3).map(\.name)
        if pool.isEmpty {
            return ["Finder", "Notes", "Safari"]
        }
        return Array(pool)
    }

    // MARK: - Hidden Apps

    @State private var hiddenFilter: String = ""

    private var hiddenAppsTab: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Filter applications", text: $hiddenFilter)
                    .textFieldStyle(.plain)
                Spacer()
                Text("\(settings.hiddenAppPaths.count) hidden")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.bar)

            Divider()

            List {
                ForEach(filteredApps, id: \.id) { app in
                    Toggle(isOn: hiddenBinding(for: app)) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.name)
                            Text(app.url.path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
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

    // MARK: - Groups

    private var groupsTab: some View {
        VStack(spacing: 0) {
            if settings.customGroups.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(.secondary)
                    Text("No Custom Groups")
                        .font(.headline)
                    Text("Create a group to organize your apps.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("New Group…") {
                        onEditGroup(nil)
                    }
                    .controlSize(.regular)
                    .padding(.top, 6)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(settings.customGroups) { group in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(group.name)
                                    .font(.system(.body, design: .default).weight(.medium))
                                Text("\(group.appPaths.count) app\(group.appPaths.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Edit") {
                                onEditGroup(group)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                            Button(role: .destructive) {
                                settings.removeGroup(id: group.id)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .controlSize(.small)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }

            Divider()

            HStack {
                Button {
                    onEditGroup(nil)
                } label: {
                    Label("New Group", systemImage: "plus")
                }
                .buttonStyle(.bordered)
                Spacer()
            }
            .padding(10)
            .background(.bar)
        }
    }
}
