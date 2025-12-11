//
//  MeView.swift
//  Permute
//
//  Created by Jules for WCA Profile Integration.
//

import SwiftUI

struct MeView: View {
    @ObservedObject var timerViewModel: TimerViewModel
    @State private var user: WCAUser?
    @State private var personData: PersonResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isLoggedIn = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)

                VStack(spacing: 30) {
                    if isLoggedIn {
                        if isLoading {
                            ProgressView("Loading Profile...")
                                .foregroundColor(.white)
                        } else if let user = user {
                            VStack(spacing: 40) {
                                PassportCardView(user: user)
                                    .padding(.horizontal)

                                if let personData = personData {
                                    ComparisonCardView(
                                        personData: personData,
                                        timerViewModel: timerViewModel
                                    )
                                    .padding(.horizontal)
                                }

                                Button(action: logout) {
                                    Text("Logout")
                                        .bold()
                                        .foregroundColor(.red)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(10)
                                }
                                .padding(.horizontal)
                            }
                        } else if let error = errorMessage {
                            VStack {
                                Text("Error loading profile")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding()

                                Button("Retry") {
                                    loadProfile()
                                }
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)

                            Text("Connect your WCA Account")
                                .font(.title3)
                                .bold()
                                .foregroundColor(.white)

                            Text("Login to see your WCA profile and passport.")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)

                            Button(action: login) {
                                HStack {
                                    Text("Login with WCA")
                                        .bold()
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .padding(.horizontal)

                            if let error = errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                        .padding()
                    }
                }
                .navigationTitle("Me")
                .navigationBarTitleDisplayMode(.inline)
            }
            .onAppear {
                checkLoginStatus()
            }
        }
    }

    private func checkLoginStatus() {
        // Simple check if we think we are logged in.
        // WCANetworkManager doesn't expose a simple "isLoggedIn" property that checks keychain,
        // but we can try to read from it via a helper, or just try to fetch profile.
        // For now, we'll try to fetch the profile. If it fails with 401, we are not logged in.
        // However, we want to avoid auto-fetching if we know we don't have a token.
        // Since we can't easily check the token existence without exposing internal methods,
        // we'll optimistically try to load if we don't know otherwise.

        // Actually, let's just try to load the profile.
        loadProfile()
    }

    private func loadProfile() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let profile = try await WCAProfileService.shared.fetchProfile()
                await MainActor.run {
                    self.user = profile
                    self.isLoggedIn = true
                }

                // If we have a WCA ID, fetch the full person data (records)
                if let wcaID = profile.wcaID {
                    let person = try await WCAProfileService.shared.fetchPerson(wcaID: wcaID)
                    await MainActor.run {
                        self.personData = person
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.isLoading = false
                    }
                }
            } catch let error as WCANetworkError {
                await MainActor.run {
                    if case .unauthorized = error {
                        self.isLoggedIn = false
                    } else {
                        self.isLoggedIn = true // Assume logged in but network error
                        self.errorMessage = error.localizedDescription
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    // If we get an error, it might be because we have no token.
                    // For now, let's treat generic errors as "maybe not logged in" if it's the first load?
                    // Or just show error.
                    // Let's assume if it fails, we show the error, unless it's clearly auth related.
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false

                    // If the error description contains something about missing token or auth...
                    // But WCANetworkManager throws specific errors.
                    // Let's rely on WCAProfileService throwing WCANetworkError.unauthorized if the token is invalid/missing.
                }
            }
        }
    }

    private func login() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                _ = try await WCANetworkManager.shared.login()
                await MainActor.run {
                    self.isLoggedIn = true
                    // After login, fetch profile
                    self.loadProfile()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Login failed: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    private func logout() {
        WCANetworkManager.shared.logout()
        user = nil
        isLoggedIn = false
    }
}

struct ComparisonCardView: View {
    let personData: PersonResponse
    @ObservedObject var timerViewModel: TimerViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Vital Statistics (3x3)")
                .font(.headline)
                .foregroundColor(.white)

            // Official vs App Single
            HStack {
                StatisticRow(
                    title: "Single",
                    official: personData.personalRecords?["333"]?.single?.best,
                    local: localBestSingle
                )
            }

            Divider().background(Color.gray)

            // Official vs App Average
            HStack {
                StatisticRow(
                    title: "Average",
                    official: personData.personalRecords?["333"]?.average?.best,
                    local: localBestAverage
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }

    private var localBestSingle: Int? {
        // Find best single across all sessions for 3x3
        // Time in timerViewModel is seconds, WCA is centiseconds
        let solves = timerViewModel.sessions
            .filter { $0.cubeType == "3x3" }
            .flatMap { $0.solves }
            .filter { $0.penalty != .dnf }

        guard let best = solves.min(by: { $0.effectiveTime < $1.effectiveTime }) else { return nil }
        return Int(best.effectiveTime * 100)
    }

    private var localBestAverage: Int? {
        // This is harder because averages are calculated on the fly usually.
        // We can just look at the current session's best Ao5 if it's 3x3?
        // Or we need to calculate best Ao5 ever?
        // Calculating best Ao5 ever across all history is expensive.
        // Let's stick to the "Current Session" best Ao5 if it is 3x3,
        // or iterate all solves in all 3x3 sessions.

        // Iterating all solves to find best Ao5 is O(N). N is smallish (< 100,000).
        // Let's try.

        var bestAo5: Double = Double.infinity

        for session in timerViewModel.sessions where session.cubeType == "3x3" {
            let solves = session.solves
            guard solves.count >= 5 else { continue }

            // Sliding window
            for i in 0...(solves.count - 5) {
                let window = Array(solves[i..<(i+5)])
                if let avg = calculateAo5(solves: window) {
                    if avg < bestAo5 {
                        bestAo5 = avg
                    }
                }
            }
        }

        return bestAo5 == Double.infinity ? nil : Int(bestAo5 * 100)
    }

    private func calculateAo5(solves: [Solve]) -> Double? {
        let times = solves.map { $0.penalty == .dnf ? Double.infinity : $0.effectiveTime }
        guard let minTime = times.min(), let maxTime = times.max() else { return nil }

        let dnfCount = solves.filter { $0.penalty == .dnf }.count
        if dnfCount > 1 { return nil } // DNF

        let sum = times.reduce(0) { $0 + ($1 == Double.infinity ? 0 : $1) }

        var adjustedSum = sum
        if maxTime != Double.infinity {
            adjustedSum -= maxTime
        }
        adjustedSum -= minTime

        return adjustedSum / 3.0
    }
}

struct StatisticRow: View {
    let title: String
    let official: Int? // Centiseconds
    let local: Int? // Centiseconds

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            HStack {
                VStack(alignment: .leading) {
                    Text("Official")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(formatTime(official))
                        .font(.system(.body, design: .monospaced))
                        .bold()
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(alignment: .leading) {
                    Text("App PB")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(formatTime(local))
                        .font(.system(.body, design: .monospaced))
                        .bold()
                        .foregroundColor(.yellow)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Delta")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    if let diff = calculateDiff() {
                        Text(diff)
                            .font(.system(.body, design: .monospaced))
                            .bold()
                            .foregroundColor(isImprovement ? .green : .red)
                    } else {
                        Text("--")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }

    private var isImprovement: Bool {
        guard let o = official, let l = local else { return false }
        return l < o
    }

    private func calculateDiff() -> String? {
        guard let o = official, let l = local else { return nil }
        let diff = Double(l - o) / 100.0
        let sign = diff < 0 ? "" : "+"
        return "\(sign)\(String(format: "%.2f", diff))"
    }

    private func formatTime(_ centiseconds: Int?) -> String {
        guard let cs = centiseconds else { return "--" }
        let seconds = Double(cs) / 100.0
        return seconds.formattedTime
    }
}

#Preview {
    MeView(timerViewModel: TimerViewModel())
}
