//
//  WCAProfileService.swift
//  Permute
//
//  Created by Jules for WCA Profile Integration.
//

import Foundation

// MARK: - Models

struct WCAUser: Codable, Identifiable {
    let id: Int
    let wcaID: String?
    let name: String
    let countryISO2: String
    let avatarURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case wcaID = "wca_id"
        case name
        case countryISO2 = "country_iso2"
        case avatar
    }

    enum AvatarKeys: String, CodingKey {
        case url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        wcaID = try container.decodeIfPresent(String.self, forKey: .wcaID)
        name = try container.decode(String.self, forKey: .name)
        countryISO2 = try container.decode(String.self, forKey: .countryISO2)

        let avatarContainer = try? container.nestedContainer(keyedBy: AvatarKeys.self, forKey: .avatar)
        avatarURL = try avatarContainer?.decodeIfPresent(String.self, forKey: .url)
    }

    // For manual initialization (mocks/previews)
    init(id: Int, wcaID: String?, name: String, countryISO2: String, avatarURL: String?) {
        self.id = id
        self.wcaID = wcaID
        self.name = name
        self.countryISO2 = countryISO2
        self.avatarURL = avatarURL
    }
}

struct MeResponse: Codable {
    let me: WCAUser
}

// MARK: - Service

class WCAProfileService {
    static let shared = WCAProfileService()

    private init() {}

    func fetchProfile() async throws -> WCAUser {
        let data = try await WCANetworkManager.shared.request(endpoint: "/me")
        let response = try JSONDecoder().decode(MeResponse.self, from: data)
        return response.me
    }
}
