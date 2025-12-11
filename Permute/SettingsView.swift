//
//  SettingsView.swift
//  Permute
//
//  Created by Jules on 12/12/25.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: TimerViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Timer")) {
                    Toggle("Inspection Time", isOn: $viewModel.isInspectionEnabled)
                }

                Section(header: Text("Puzzle")) {
                    Picker("Cube Type", selection: $viewModel.cubeType) {
                        Text("2x2").tag("2x2")
                        Text("3x3").tag("3x3")
                        Text("4x4").tag("4x4")
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
