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
                TabStripScrollButton(
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
                            fillsWidth: false,
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
            .onScrollGeometryChange(for: TabStripScrollFlags.self) { geometry in
                let offset = geometry.contentOffset.x
                let content = geometry.contentSize.width
                let viewport = geometry.containerSize.width
                metrics.offset = offset
                metrics.contentLength = content
                metrics.viewportLength = viewport
                return TabStripScroll.flags(
                    offset: offset,
                    contentLength: content,
                    viewportLength: viewport
                )
            } action: { _, new in
                overflows = new.overflows
                canScrollLeft = new.canScrollBackward
                canScrollRight = new.canScrollForward
                if abs(contentWidth - new.contentLength) > 0.5 {
                    contentWidth = new.contentLength
                }
            }

            if overflows {
                TabStripScrollButton(
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
        let target = TabStripScroll.pageTarget(direction: direction, metrics: metrics)
        withAnimation(.easeInOut(duration: 0.15)) {
            scrollPosition.scrollTo(x: target)
        }
    }
}
