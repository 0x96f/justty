//
//  TabItemView.swift
//  justty
//

import SwiftUI

struct TabItemView: View {
    @ObservedObject var session: TerminalSession
    let isSelected: Bool
    let fillsWidth: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isCloseHovered = false

    var body: some View {
        HStack(spacing: 0) {
            Text(session.title)
                .lineLimit(1)
                .truncationMode(.tail)
                // minWidth 0 lets the label shrink under the chip max instead of resisting truncation.
                .frame(minWidth: 0, alignment: .leading)

            Spacer(minLength: 8)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .semibold))
                    .frame(width: 16, height: 16)
                    .background(
                        Circle()
                            .fill(Color.primary.opacity(isCloseHovered ? 0.12 : 0))
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .opacity(isCloseHovered ? 1.0 : (isSelected ? 0.7 : 0.45))
            .help("Close Tab")
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.12)) {
                    isCloseHovered = hovering
                }
            }
        }
        .font(.system(size: 12))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .frame(
            maxWidth: fillsWidth ? .infinity : JusttyConstants.maxTabWidth,
            alignment: .leading
        )
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isSelected ? Color.primary.opacity(0.12) : Color.clear)
        )
        .contentShape(Rectangle())
        .help(session.title)
        .onTapGesture(perform: onSelect)
        .contextMenu {
            Button("Close Tab", action: onClose)
        }
    }
}
