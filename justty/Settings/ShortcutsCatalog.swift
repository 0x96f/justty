//
//  ShortcutsCatalog.swift
//  justty
//

import Foundation

/// Single source of truth for displayable shortcuts and Ghostty terminal keybinds.
enum ShortcutsCatalog {
    struct Item: Identifiable {
        let id: String
        let title: String
        /// macOS-style display string (e.g. "⌘T").
        let keys: String
        /// Ghostty `keybind` value when this is a terminal binding; nil for menu-only shortcuts.
        let ghosttyKeybind: String?
    }

    struct Section: Identifiable {
        let id: String
        let title: String
        let items: [Item]
    }

    static let sections: [Section] = [
        Section(
            id: "window-tabs",
            title: "Window & Tabs",
            items: [
                Item(id: "new-window", title: "New Window", keys: "⌘N", ghosttyKeybind: nil),
                Item(id: "new-tab", title: "New Tab", keys: "⌘T", ghosttyKeybind: nil),
                Item(id: "close-tab", title: "Close Tab", keys: "⌘W", ghosttyKeybind: nil),
                Item(id: "next-tab", title: "Show Next Tab", keys: "⌘⇧]", ghosttyKeybind: nil),
                Item(id: "prev-tab", title: "Show Previous Tab", keys: "⌘⇧[", ghosttyKeybind: nil),
                Item(id: "find", title: "Find", keys: "⌘F", ghosttyKeybind: nil),
                Item(id: "larger", title: "Larger", keys: "⌘+", ghosttyKeybind: nil),
                Item(id: "smaller", title: "Smaller", keys: "⌘−", ghosttyKeybind: nil),
                Item(id: "actual-size", title: "Actual Size", keys: "⌘0", ghosttyKeybind: nil),
                Item(
                    id: "reload-config",
                    title: "Reload Configuration",
                    keys: "⌘⇧,",
                    ghosttyKeybind: nil
                ),
            ]
        ),
        Section(
            id: "terminal",
            title: "Terminal",
            items: [
                Item(
                    id: "word-left",
                    title: "Move Word Left",
                    keys: "⌥←",
                    ghosttyKeybind: "alt+left=esc:b"
                ),
                Item(
                    id: "word-right",
                    title: "Move Word Right",
                    keys: "⌥→",
                    ghosttyKeybind: "alt+right=esc:f"
                ),
                Item(
                    id: "line-start",
                    title: "Move to Line Start",
                    keys: "⌘←",
                    ghosttyKeybind: "super+left=text:\\x01"
                ),
                Item(
                    id: "line-end",
                    title: "Move to Line End",
                    keys: "⌘→",
                    ghosttyKeybind: "super+right=text:\\x05"
                ),
                Item(
                    id: "kill-line",
                    title: "Delete to Line Start",
                    keys: "⌘⌫",
                    ghosttyKeybind: "super+backspace=text:\\x15"
                ),
                Item(
                    id: "copy",
                    title: "Copy",
                    keys: "⌘C",
                    ghosttyKeybind: "super+c=copy_to_clipboard"
                ),
                Item(
                    id: "paste",
                    title: "Paste",
                    keys: "⌘V",
                    ghosttyKeybind: "super+v=paste_from_clipboard"
                ),
                Item(
                    id: "scroll-top",
                    title: "Scroll to Top",
                    keys: "⌘↖",
                    ghosttyKeybind: "super+home=scroll_to_top"
                ),
                Item(
                    id: "scroll-bottom",
                    title: "Scroll to Bottom",
                    keys: "⌘↘",
                    ghosttyKeybind: "super+end=scroll_to_bottom"
                ),
                Item(
                    id: "scroll-page-up",
                    title: "Scroll Page Up",
                    keys: "⌘⇞",
                    ghosttyKeybind: "super+page_up=scroll_page_up"
                ),
                Item(
                    id: "scroll-page-down",
                    title: "Scroll Page Down",
                    keys: "⌘⇟",
                    ghosttyKeybind: "super+page_down=scroll_page_down"
                ),
            ]
        ),
    ]

    /// Ghostty keybind strings installed by the host after `keybind=clear`.
    static var hostKeybinds: [String] {
        sections.flatMap(\.items).compactMap(\.ghosttyKeybind)
    }
}
