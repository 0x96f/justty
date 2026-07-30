//
//  TabBarView.swift
//  justty
//

import SwiftUI

struct TabBarView: View {
    @ObservedObject var tabs: TabManager
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.openSettings) private var openSettings

    /// Latest scroll geometry for arrow page jumps (not @Published — avoids per-frame redraws).
    @State private var metrics = TabStripMetrics()
    @State private var overflows = false
    @State private var canScrollLeft = false
    @State private var canScrollRight = false
    @State private var contentWidth: CGFloat = 0
    @State private var scrollPosition = ScrollPosition()

    var body: some View {
        HStack(spacing: 0) {
            Color.clear
                .frame(width: JusttyConstants.trafficLightsLeadingInset)

            if overflows {
                tabScrollButton(
                    systemName: "chevron.left",
                    help: "Scroll Tabs Left",
                    enabled: canScrollLeft
                ) {
                    scrollTabs(by: -1)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(tabs.sessions) { session in
                        TabItemView(
                            session: session,
                            isSelected: session.id == tabs.selectedID,
                            onSelect: { tabs.select(session.id) },
                            onClose: { tabs.close(session) }
                        )
                        .id(session.id)
                    }
                }
                // Animate adjacent swaps from ⌘⇧← / ⌘⇧→ reorder.
                .animation(.easeInOut(duration: 0.15), value: tabs.sessions.map(\.id))
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .scrollTargetLayout()
            }
            .scrollPosition($scrollPosition)
            .clipped()
            // Hug content when it fits so Spacer receives leftover drag area;
            // expand and scroll when tabs overflow the space left of + / Settings.
            .frame(
                minWidth: 0,
                maxWidth: overflows ? .infinity : (contentWidth > 0 ? contentWidth : .infinity),
                alignment: .leading
            )
            .onScrollGeometryChange(for: TabScrollFlags.self) { geometry in
                let offset = geometry.contentOffset.x
                let content = geometry.contentSize.width
                let viewport = geometry.containerSize.width
                metrics.offset = offset
                metrics.contentWidth = content
                metrics.viewportWidth = viewport
                let overflows = content > viewport + 0.5
                return TabScrollFlags(
                    overflows: overflows,
                    canScrollLeft: overflows && offset > 0.5,
                    canScrollRight: overflows && offset < content - viewport - 0.5,
                    contentWidth: content
                )
            } action: { _, new in
                overflows = new.overflows
                canScrollLeft = new.canScrollLeft
                canScrollRight = new.canScrollRight
                if abs(contentWidth - new.contentWidth) > 0.5 {
                    contentWidth = new.contentWidth
                }
            }

            if overflows {
                tabScrollButton(
                    systemName: "chevron.right",
                    help: "Scroll Tabs Right",
                    enabled: canScrollRight
                ) {
                    scrollTabs(by: 1)
                }
            }

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
                // Tie refresh to settings.theme; color comes from Theme selection.
                Theme.backgroundColor
                    .id(settings.theme)
                WindowDragRegion()
            }
        }
        .onChange(of: tabs.selectedID) { _, newID in
            guard let newID else { return }
            withAnimation(.easeInOut(duration: 0.15)) {
                scrollPosition.scrollTo(id: newID, anchor: .center)
            }
        }
        .onChange(of: tabs.sessions.count) { _, _ in
            guard let id = tabs.selectedID else { return }
            withAnimation(.easeInOut(duration: 0.15)) {
                scrollPosition.scrollTo(id: id, anchor: .trailing)
            }
        }
    }

    private func scrollTabs(by direction: CGFloat) {
        let page = max(metrics.viewportWidth * 0.75, 80)
        let maxOffset = max(0, metrics.contentWidth - metrics.viewportWidth)
        let target = min(max(0, metrics.offset + direction * page), maxOffset)
        withAnimation(.easeInOut(duration: 0.15)) {
            scrollPosition.scrollTo(x: target)
        }
    }

    private func tabScrollButton(
        systemName: String,
        help: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 28, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 0.85 : 0.35)
        .help(help)
    }
}

/// Mutable scroll metrics read by arrow actions without publishing every frame.
private final class TabStripMetrics {
    var offset: CGFloat = 0
    var contentWidth: CGFloat = 0
    var viewportWidth: CGFloat = 0
}

private struct TabScrollFlags: Equatable {
    var overflows: Bool
    var canScrollLeft: Bool
    var canScrollRight: Bool
    var contentWidth: CGFloat
}

private struct TabItemView: View {
    @ObservedObject var session: TerminalSession
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(session.title)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: 160, alignment: .leading)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .semibold))
                    .frame(width: 14, height: 14)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(isSelected ? 0.7 : 0.45)
            .help("Close Tab")
        }
        .font(.system(size: 12))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isSelected ? Color.primary.opacity(0.12) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .contextMenu {
            Button("Close Tab", action: onClose)
        }
    }
}
