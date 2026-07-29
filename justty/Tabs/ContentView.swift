//
//  ContentView.swift
//  justty
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var tabs: TabManager
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        VStack(spacing: 0) {
            TabBarView(tabs: tabs)
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.backgroundColor.id(settings.theme))
        .ignoresSafeArea(.container, edges: .top)
        .background(WindowChromeConfigurator())
    }
}
