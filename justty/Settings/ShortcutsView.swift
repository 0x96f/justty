//
//  ShortcutsView.swift
//  justty
//

import SwiftUI

struct ShortcutsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Form {
                ForEach(ShortcutsCatalog.sections) { section in
                    Section(section.title) {
                        ForEach(section.items) { item in
                            LabeledContent(item.title) {
                                Text(item.keys)
                                    .font(.body.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .frame(width: 420, height: 340)
    }
}
