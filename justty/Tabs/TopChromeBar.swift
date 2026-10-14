//
//  TopChromeBar.swift
//  justty
//

import SwiftUI

/// Top strip for the content column in vertical-tabs mode: sidebar toggle, window drag, + / Settings.
/// When the sidebar is visible, traffic lights sit over it; when collapsed, this bar insets for them.
struct TopChromeBar: View {
    @ObservedObject var tabs: TabManager
    @Binding var isSidebarVisible: Bool
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        HStack(spacing: 0) {
            if !isSidebarVisible {
                Color.clear
                    .frame(width: JusttyConstants.trafficLightsLeadingInset)
            }

            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    tabs.toggleSidebar()
                }
            } label: {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 28, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(isSidebarVisible ? "Hide Sidebar" : "Show Sidebar")
            .padding(.leading, isSidebarVisible ? 6 : 0)

            // Leftover width is non-hit-testable so double-click / drag reach WindowDragRegion.
            Spacer(minLength: 8)

            Button {
                tabs.newTab()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 28, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("New Tab")

            Button {
                openSettings()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 28, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Settings")
            .padding(.trailing, 6)
        }
        .frame(height: JusttyConstants.tabBarHeight)
        .background {
            ZStack {
                Theme.backgroundColor
                    .id(settings.themeRefreshID)
                WindowDragRegion()
            }
        }
    }
}
