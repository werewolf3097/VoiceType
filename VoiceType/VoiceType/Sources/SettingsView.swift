import SwiftUI

enum DashboardSection: String, CaseIterable, Identifiable {
    case home = "Главная"
    case history = "История"
    case dictionary = "Словарь"
    case settings = "Настройки"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .home: return "house"
        case .history: return "clock"
        case .dictionary: return "text.book.closed"
        case .settings: return "gearshape"
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selection: DashboardSection? = .home

    var body: some View {
        NavigationSplitView {
            List(DashboardSection.allCases, selection: $selection) { section in
                Label(section.rawValue, systemImage: section.systemImage).tag(section)
            }
            .navigationTitle("VoiceType")
            .listStyle(.sidebar)
        } detail: {
            Group {
                switch selection {
                case .home, .none:
                    DashboardHomeView()
                case .history:
                    DashboardHistoryView()
                case .dictionary:
                    DashboardDictionaryView()
                case .settings:
                    DashboardSettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: 860, height: 600)
        .onAppear {
            PermissionsHelper.requestMicrophone { _ in }
            appState.restartHotkeyListener()
        }
    }
}
