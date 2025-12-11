//
//  ManualEntryView.swift
//  Permute
//
//  Created by Jules on 12/12/25.
//

import SwiftUI

struct ManualEntryView: View {
    @ObservedObject var viewModel: TimerViewModel
    @Binding var isPresented: Bool

    @State private var timeString: String = ""
    @State private var showError: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Enter Time (seconds)")) {
                    TextField("12.34", text: $timeString)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Manual Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let time = Double(timeString) {
                            viewModel.addManualSolve(time: time)
                            isPresented = false
                        } else {
                            showError = true
                        }
                    }
                }
            }
            .alert("Invalid Time", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enter a valid number.")
            }
        }
    }
}
