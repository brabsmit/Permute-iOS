//
//  ContentView.swift
//  Permute
//
//  Created by Bryan Smith on 12/11/25.
//

import SwiftUI

struct ContentView: View {

    // We can control the selected tab if needed, but for now default is fine.
    
    var body: some View {
        TabView {
            TimerView()
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }

            MeView()
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
