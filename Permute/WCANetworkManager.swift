//
//  WCANetworkManager.swift
//  Permute
//
//  Created for WCA Integration.
//

import Foundation
import AuthenticationServices
import Security
import UIKit

// MARK: - Configuration Constants
// These should be replaced with your actual WCA Application credentials.
private let WCA_BASE_URL = "https://www.worldcubeassociation.org/api/v0"
private let WCA_CLIENT_ID = ProcessInfo.processInfo.environment["WCA_APPLICATION_ID"] ?? "YOUR_CLIENT_ID_HERE"
private let WCA_CLIENT_SECRET = ProcessInfo.processInfo.environment["WCA_SECRET"] ?? "YOUR_CLIENT_SECRET_HERE"
private let WCA_REDIRECT_URI = "YOUR_REDIRECT_URI_HERE" // e.g., "com.permute.app://callback"
private let WCA_CALLBACK_SCHEME = "YOUR_CALLBACK_SCHEME_HERE" // e.g., "com.permute.app"

// MARK: - Errors
enum WCANetworkError: Error {
    case unauthorized // 401
    case tooManyRequests // 429
    case invalidURL
    case noData
    case decodingError
    case serverError(statusCode: Int)
    case unknown(Error)
    case loginCancelled
    case missingToken
    case tokenExchangeFailed
}

// MARK: - WCANetworkManager
@MainActor
class WCANetworkManager: NSObject, ObservableObject {

    static let shared = WCANetworkManager()

    // Keychain Keys
    private let kAccessToken = "wca_access_token"
    private let kRefreshToken = "wca_refresh_token"

    // Auth Session
    private var currentAuthSession: ASWebAuthenticationSession?

    private override init() {
        super.init()
    }

    // MARK: - Authentication (OAuth 2.0)

    /// Initiates the OAuth 2.0 login flow using ASWebAuthenticationSession.
    /// Returns the access_token upon success.
    func login() async throws -> String {
        // Step A: Open the auth URL
        var components = URLComponents(string: "https://www.worldcubeassociation.org/oauth/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: WCA_CLIENT_ID),
            URLQueryItem(name: "redirect_uri", value: WCA_REDIRECT_URI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "public")
        ]

        guard let authURL = components?.url else {
            throw WCANetworkError.invalidURL
        }

        // Step B: Capture the callback URL scheme
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: WCA_CALLBACK_SCHEME) { [weak self] callbackURL, error in
                // Clean up session reference
                self?.currentAuthSession = nil

                if let error = error {
                    if let asError = error as? ASWebAuthenticationSessionError, asError.code == .canceledLogin {
                        continuation.resume(throwing: WCANetworkError.loginCancelled)
                    } else {
                        continuation.resume(throwing: WCANetworkError.unknown(error))
                    }
                    return
                }

                guard let callbackURL = callbackURL,
                      let urlComponents = URLComponents(url: callbackURL, resolvingAgainstBaseURL: true),
                      let code = urlComponents.queryItems?.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: WCANetworkError.tokenExchangeFailed)
                    return
                }

                // Step C: Exchange the code for an access_token
                Task {
                    do {
                        let token = try await self?.exchangeCodeForToken(code: code) ?? ""
                        continuation.resume(returning: token)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }

            self.currentAuthSession = session
            session.presentationContextProvider = self
            session.start()
        }
    }

    private func exchangeCodeForToken(code: String) async throws -> String {
        guard let url = URL(string: "https://www.worldcubeassociation.org/oauth/token") else {
            throw WCANetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "grant_type": "authorization_code",
            "client_id": WCA_CLIENT_ID,
            "client_secret": WCA_CLIENT_SECRET,
            "redirect_uri": WCA_REDIRECT_URI,
            "code": code
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WCANetworkError.unknown(NSError(domain: "Invalid Response", code: 0))
        }

        // Handle Errors
        if httpResponse.statusCode == 401 { throw WCANetworkError.unauthorized }
        if httpResponse.statusCode == 429 { throw WCANetworkError.tooManyRequests }

        if httpResponse.statusCode == 200 {
            struct TokenResponse: Decodable {
                let access_token: String
                let refresh_token: String?
                let expires_in: Int?
            }

            do {
                let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                // Security: Store tokens in Keychain
                saveToKeychain(key: kAccessToken, value: tokenResponse.access_token)
                if let refresh = tokenResponse.refresh_token {
                    saveToKeychain(key: kRefreshToken, value: refresh)
                }
                return tokenResponse.access_token
            } catch {
                throw WCANetworkError.decodingError
            }
        } else {
            throw WCANetworkError.serverError(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - API Request

    func request(endpoint: String, method: String = "GET", body: Data? = nil) async throws -> Data {
        guard let url = URL(string: "\(WCA_BASE_URL)\(endpoint)") else {
            throw WCANetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = readFromKeychain(key: kAccessToken) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WCANetworkError.unknown(NSError(domain: "Invalid Response", code: 0))
        }

        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 401:
            throw WCANetworkError.unauthorized
        case 429:
            throw WCANetworkError.tooManyRequests
        default:
            throw WCANetworkError.serverError(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Keychain Helpers

    private func saveToKeychain(key: String, value: String) {
        let data = Data(value.utf8)

        // Query for deletion (matches account only)
        let deleteQuery = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ] as [String : Any]

        // Delete existing item first
        SecItemDelete(deleteQuery as CFDictionary)

        // Query for adding (includes data)
        let addQuery = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: data
        ] as [String : Any]

        // Add new item
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    private func readFromKeychain(key: String) -> String? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ] as [String : Any]

        var dataTypeRef: AnyObject? = nil
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    private func deleteFromKeychain(key: String) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ] as [String : Any]

        SecItemDelete(query as CFDictionary)
    }

    func logout() {
        deleteFromKeychain(key: kAccessToken)
        deleteFromKeychain(key: kRefreshToken)
    }

    // MARK: - Competitions

    func fetchCompetitions(countryIso2: String, startDate: Date) async throws -> [Competition] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let startString = formatter.string(from: startDate)

        // URL encode the parameters just in case
        let countryParam = countryIso2.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? countryIso2
        let startParam = startString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? startString

        let endpoint = "/competitions?country_iso2=\(countryParam)&start=\(startParam)"

        let data = try await request(endpoint: endpoint)

        do {
            let competitions = try JSONDecoder().decode([Competition].self, from: data)
            return competitions
        } catch {
            // Sometimes APIs return errors in a specific format or wrap the list.
            // For now assuming [Competition] based on standard usage.
            print("Decoding error: \(error)")
            throw WCANetworkError.decodingError
        }
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding
extension WCANetworkManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Attempt to return the key window's scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            return window
        }
        return ASPresentationAnchor()
    }
}
