//
//  MeView.swift
//  Permute
//
//  Created by Jules for WCA Profile Integration.
//

import SwiftUI

struct MeView: View {
    @State private var user: WCAUser?
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
                    self.isLoading = false
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

#Preview {
    MeView()
}
