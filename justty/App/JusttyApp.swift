//
//  JusttyApp.swift
//  justty
//

import SwiftUI

@main
struct JusttyApp: App {
    init() {
        // Load prefs early; do not touch NSApp here - it is still nil.
        _ = AppSettings.shared
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            WindowRootView()
                .onAppear {
                    AppSettings.shared.applyAppAppearance()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(WindowGeometry.contentSize())
        .commands {
            JusttyCommands()
        }

        Settings {
            SettingsView()
        }
    }
}

private struct WindowRootView: View {
    @StateObject private var tabs = TabManager()

    var body: some View {
        ContentView(tabs: tabs)
            .focusedSceneObject(tabs)
    }
}

private struct JusttyCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    @FocusedObject private var tabs: TabManager?

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New Window") {
                openWindow(id: "main")
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("New Tab") {
                tabs?.newTab()
            }
            .keyboardShortcut("t", modifiers: .command)
            .disabled(tabs == nil)
        }

        CommandGroup(after: .newItem) {
            Button("Close Tab") {
                tabs?.closeSelected()
            }
            .keyboardShortcut("w", modifiers: .command)
            .disabled(tabs == nil)

            Divider()

            Button("Show Next Tab") {
                tabs?.selectNext()
            }
            .keyboardShortcut("]", modifiers: [.command, .shift])
            .disabled(tabs == nil)

            Button("Show Previous Tab") {
                tabs?.selectPrevious()
            }
            .keyboardShortcut("[", modifiers: [.command, .shift])
            .disabled(tabs == nil)

            Divider()

            Button("Reload Configuration") {
                AppSettings.shared.reloadFromDisk()
            }
        }

        CommandGroup(after: .pasteboard) {
            Button("Find…") {
                tabs?.showFind()
            }
            .keyboardShortcut("f", modifiers: .command)
            .disabled(tabs == nil)
        }

        CommandMenu("View") {
            Button("Larger") {
                tabs?.increaseFontSize()
            }
            .keyboardShortcut("=", modifiers: .command)
            .disabled(tabs == nil)

            Button("Smaller") {
                tabs?.decreaseFontSize()
            }
            .keyboardShortcut("-", modifiers: .command)
            .disabled(tabs == nil)

            Button("Actual Size") {
                tabs?.resetFontSize()
            }
            .keyboardShortcut("0", modifiers: .command)
            .disabled(tabs == nil)
        }
    }
}
