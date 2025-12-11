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
    @State private var showingNewSessionAlert = false
    @State private var newSessionName = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Current Session")) {
                    Picker("Session", selection: Binding(
                        get: { viewModel.currentSessionId },
                        set: { viewModel.switchSession(to: $0) }
                    )) {
                        ForEach(viewModel.sessions) { session in
                            Text(session.name).tag(session.id)
                        }
                    }

                    Button("Create New Session") {
                        showingNewSessionAlert = true
                    }
                }

                Section(header: Text("Timer")) {
                    Toggle("Inspection Time", isOn: $viewModel.isInspectionEnabled)
                    Toggle("Focus Mode", isOn: $viewModel.isFocusModeEnabled)
                }

                Section(header: Text("Puzzle")) {
                    Picker("Cube Type", selection: $viewModel.cubeType) {
                        Text("2x2").tag("2x2")
                        Text("3x3").tag("3x3")
                        Text("4x4").tag("4x4")
                    }
                }

                Section(header: Text("Manage Sessions")) {
                    List {
                        ForEach(viewModel.sessions) { session in
                            HStack {
                                Text(session.name)
                                Spacer()
                                if session.id == viewModel.currentSessionId {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            let idsToDelete = indexSet.map { viewModel.sessions[$0].id }
                            for id in idsToDelete {
                                viewModel.deleteSession(id: id)
                            }
                        }
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
            .alert("New Session", isPresented: $showingNewSessionAlert) {
                TextField("Session Name", text: $newSessionName)
                Button("Cancel", role: .cancel) {
                    newSessionName = ""
                }
                Button("Create") {
                    viewModel.createSession(name: newSessionName.isEmpty ? "New Session" : newSessionName, cubeType: "3x3")
                    newSessionName = ""
                }
            }
        }
    }
}

#Preview {
    SettingsView(viewModel: TimerViewModel())
}
