//
//  ContentView.swift
//  Permute
//
//  Created by Bryan Smith on 12/11/25.
//

import SwiftUI

struct ContentView: View {
    // Shared ViewModel
    @StateObject private var timerViewModel = TimerViewModel()
    
    var body: some View {
        TabView {
            TimerView(viewModel: timerViewModel)
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }

            MeView(timerViewModel: timerViewModel)
                .tabItem {
                    Label("Me", systemImage: "person.circle")
                }
        }
        .accentColor(.yellow) // Match the app theme
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
