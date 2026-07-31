//
//  SettingsView.swift
//  justty
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var showingShortcuts = false

    var body: some View {
        Form {
            Section("Theme") {
                Picker("Theme", selection: $settings.theme) {
                    Section("Light") {
                        ForEach(Theme.lightThemeNames, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    Section("Dark") {
                        ForEach(Theme.darkThemeNames, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                }
            }

            Section("Font") {
                Picker("Family", selection: $settings.fontFamily) {
                    Text("System").tag("")
                    ForEach(TerminalFont.selectableFamilies(), id: \.self) { family in
                        Text(family).tag(family)
                    }
                }

                LabeledContent("Size") {
                    HStack(spacing: 4) {
                        TextField(
                            "",
                            value: $settings.fontSize,
                            format: .number
                        )
                        .frame(width: 48)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                        Text("px")
                            .foregroundStyle(.secondary)
                    }
                }

                LabeledContent("Line height") {
                    HStack(spacing: 4) {
                        Text(
                            settings.lineHeight,
                            format: .number.precision(.fractionLength(2))
                        )
                        .monospacedDigit()
                        .frame(width: 36, alignment: .trailing)
                        Text("×")
                            .foregroundStyle(.secondary)
                        Stepper(
                            "",
                            value: $settings.lineHeight,
                            in: AppSettings.Limits.lineHeight,
                            step: 0.05
                        )
                        .labelsHidden()
                    }
                }

                Picker("Weight", selection: $settings.fontWeight) {
                    ForEach(FontWeightSetting.allCases) { weight in
                        Text(weight.fontStyle).tag(weight)
                    }
                }
            }

            Section("Window") {
                Toggle(
                    "Confirm before closing tabs with a running command",
                    isOn: $settings.confirmCloseRunningCommand
                )

                Toggle(
                    "Show directory in tab titles",
                    isOn: $settings.showCwdInTabTitle
                )

                LabeledContent("Padding") {
                    HStack(spacing: 4) {
                        TextField(
                            "",
                            value: $settings.terminalPadding,
                            format: .number
                        )
                        .frame(width: 48)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                        Text("px")
                            .foregroundStyle(.secondary)
                    }
                }

                LabeledContent("Position") {
                    HStack(spacing: 8) {
                        TextField(
                            "",
                            value: $settings.windowOriginX,
                            format: .number
                        )
                        .frame(width: 48)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                        Text("×")
                            .foregroundStyle(.secondary)
                        TextField(
                            "",
                            value: $settings.windowOriginY,
                            format: .number
                        )
                        .frame(width: 48)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                    }
                }
                Text("Position from the top-left of the visible desktop")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                LabeledContent("Size") {
                    HStack(spacing: 8) {
                        TextField(
                            "",
                            value: $settings.windowColumns,
                            format: .number
                        )
                        .frame(width: 48)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                        Text("×")
                            .foregroundStyle(.secondary)
                        TextField(
                            "",
                            value: $settings.windowRows,
                            format: .number
                        )
                        .frame(width: 48)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                    }
                }
                Text("Size of new windows (e.g. 80 × 24)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section("Keyboard Shortcuts") {
                Button("View Keyboard Shortcuts…") {
                    showingShortcuts = true
                }
            }

            Section("Configuration") {
                Button("Open Configuration…") {
                    settings.openConfigFile()
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 580)
        .padding(8)
        .sheet(isPresented: $showingShortcuts) {
            ShortcutsView()
        }
    }
}
