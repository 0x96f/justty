//
//  ContentView.swift
//  justty
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var tabs: TabManager
    @ObservedObject private var settings = AppSettings.shared
    @State private var isSidebarVisible = true

    var body: some View {
        Group {
            if settings.verticalTabs {
                verticalLayout
            } else {
                horizontalLayout
            }
        }
        .background(Theme.backgroundColor.id(settings.theme))
        .ignoresSafeArea(.container, edges: .top)
        .background(WindowChromeConfigurator())
    }

    private var horizontalLayout: some View {
        VStack(spacing: 0) {
            TabBarView(tabs: tabs)
            terminalColumn
        }
    }

    private var verticalLayout: some View {
        HStack(spacing: 0) {
            VerticalTabStrip(tabs: tabs, isVisible: isSidebarVisible)
            VStack(spacing: 0) {
                TopChromeBar(tabs: tabs, isSidebarVisible: $isSidebarVisible)
                terminalColumn
            }
            // Allow the terminal column to shrink instead of proposing negative sizes
            // when the sidebar width approaches the window width.
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        }
    }

    private var terminalColumn: some View {
        VStack(spacing: 0) {
            if tabs.isFindPresented {
                FindBarView(tabs: tabs)
            }
            ZStack {
                if let session = tabs.selectedSession {
                    TerminalHostView(
                        session: session,
                        isFocused: !tabs.isFindPresented
                    )
                    .id(session.id)
                }
                TerminalParkingView(sessions: tabs.parkedSessions)
                    .frame(width: 0, height: 0)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        }
    }
}
