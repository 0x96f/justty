//
//  FindBarView.swift
//  justty
//

import SwiftUI

/// Thin find chrome above the terminal; drives Ghostty search via TabManager.
struct FindBarView: View {
    @ObservedObject var tabs: TabManager
    @FocusState private var queryFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 12, weight: .medium))

            TextField("Find", text: Binding(
                get: { tabs.findQuery },
                set: { tabs.updateFindQuery($0) }
            ))
            .textFieldStyle(.plain)
            .focused($queryFocused)
            .onSubmit {
                tabs.findNext()
            }

            Button {
                tabs.findPrevious()
            } label: {
                Image(systemName: "chevron.up")
            }
            .buttonStyle(.borderless)
            .help("Find Previous")

            Button {
                tabs.findNext()
            } label: {
                Image(systemName: "chevron.down")
            }
            .buttonStyle(.borderless)
            .help("Find Next")

            Button {
                tabs.hideFind()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .help("Close")
            .keyboardShortcut(.cancelAction)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Theme.backgroundColor.opacity(0.92))
        .overlay(alignment: .bottom) {
            Divider()
        }
        .onAppear {
            queryFocused = true
        }
        .onChange(of: tabs.findFocusToken) { _, _ in
            queryFocused = true
        }
        .onExitCommand {
            tabs.hideFind()
        }
    }
}
