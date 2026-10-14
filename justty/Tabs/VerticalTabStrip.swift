//
//  VerticalTabStrip.swift
//  justty
//

import SwiftUI

struct VerticalTabStrip: View {
    @ObservedObject var tabs: TabManager
    var isVisible: Bool
    @ObservedObject private var settings = AppSettings.shared

    /// Latest scroll geometry for arrow page jumps (not @Published — avoids per-frame redraws).
    @State private var metrics = TabStripMetrics()
    @State private var overflows = false
    @State private var canScrollUp = false
    @State private var canScrollDown = false
    @State private var scrollPosition = ScrollPosition()
    /// Live width during drag — avoids publishing AppSettings (and rebuilding the terminal) every pixel.
    @State private var width = JusttyConstants.verticalTabBarWidth
    @State private var isResizing = false

    private var displayedWidth: CGFloat {
        isVisible ? max(width, JusttyConstants.verticalTabBarMinWidth) : 0
    }

    /// Slightly darker than terminal chrome so the rail reads as a sidebar.
    private var sidebarFill: some View {
        Theme.backgroundColor
            .overlay(Color.black.opacity(Theme.isDark ? 0.18 : 0.06))
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            VStack(spacing: 0) {
                // Clear the traffic lights; background still paints edge-to-edge under them.
                Color.clear
                    .frame(height: JusttyConstants.tabBarHeight)
                    .background(WindowDragRegion())

                // Chevrons overlay the scroll view so they never steal height and
                // push the ScrollView into a negative proposal (geometry warnings).
                ZStack {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 2) {
                            ForEach(tabs.sessions) { session in
                                TabItemView(
                                    session: session,
                                    isSelected: session.id == tabs.selectedID,
                                    fillsWidth: true,
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
                        .padding(.top, overflows ? 24 : 0)
                        .padding(.bottom, overflows ? 24 : 0)
                        .scrollTargetLayout()
                    }
                    .scrollPosition($scrollPosition)
                    .clipped()
                    .onScrollGeometryChange(for: TabStripScrollFlags.self) { geometry in
                        let offset = max(0, geometry.contentOffset.y)
                        let content = max(0, geometry.contentSize.height)
                        let viewport = max(0, geometry.containerSize.height)
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
                        canScrollUp = new.canScrollBackward
                        canScrollDown = new.canScrollForward
                    }

                    if overflows {
                        VStack(spacing: 0) {
                            TabStripScrollButton(
                                systemName: "chevron.up",
                                help: "Scroll Tabs Up",
                                enabled: canScrollUp,
                                expandsHorizontally: true
                            ) {
                                scrollTabs(by: -1)
                            }
                            .background { sidebarFill }

                            Spacer(minLength: 0)

                            TabStripScrollButton(
                                systemName: "chevron.down",
                                help: "Scroll Tabs Down",
                                enabled: canScrollDown,
                                expandsHorizontally: true
                            ) {
                                scrollTabs(by: 1)
                            }
                            .background { sidebarFill }
                        }
                        .allowsHitTesting(true)
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            }

            SidebarResizeHandle(
                width: $width,
                onDragBegan: { isResizing = true },
                onDragEnded: {
                    settings.verticalTabBarWidth = Int(width.rounded())
                    isResizing = false
                }
            )
            .frame(width: isVisible ? 6 : 0)
            .frame(maxHeight: .infinity)
            .allowsHitTesting(isVisible)
            .help("Resize Sidebar")
        }
        .background {
            sidebarFill
                .id(settings.themeRefreshID)
        }
        .frame(width: displayedWidth)
        .frame(minHeight: 0, maxHeight: .infinity)
        .clipped()
        .allowsHitTesting(isVisible)
        .animation(.easeInOut(duration: 0.22), value: isVisible)
        .onAppear {
            width = clampedWidth(CGFloat(settings.verticalTabBarWidth))
        }
        .onChange(of: settings.verticalTabBarWidth) { _, newValue in
            guard !isResizing else { return }
            width = clampedWidth(CGFloat(newValue))
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
                scrollPosition.scrollTo(id: id, anchor: .bottom)
            }
        }
    }

    private func clampedWidth(_ value: CGFloat) -> CGFloat {
        min(
            max(value, JusttyConstants.verticalTabBarMinWidth),
            JusttyConstants.verticalTabBarMaxWidth
        )
    }

    private func scrollTabs(by direction: CGFloat) {
        let target = TabStripScroll.pageTarget(direction: direction, metrics: metrics)
        withAnimation(.easeInOut(duration: 0.15)) {
            scrollPosition.scrollTo(y: target)
        }
    }
}
