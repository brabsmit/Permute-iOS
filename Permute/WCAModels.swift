//
//  WCAModels.swift
//  Permute
//
//  Created by Jules for WCA Integration.
//

import Foundation

// MARK: - API Response Models

struct PersonResponse: Codable {
    let person: PersonData
    let personalRecords: [String: EventRecords]?

    enum CodingKeys: String, CodingKey {
        case person
        case personalRecords = "personal_records"
    }
}

struct PersonData: Codable {
    let name: String
    let wcaID: String
    let countryISO2: String
    let avatar: Avatar?

    enum CodingKeys: String, CodingKey {
        case name
        case wcaID = "wca_id"
        case countryISO2 = "country_iso2"
        case avatar
    }
}

struct Avatar: Codable {
    let url: String
    let thumbURL: String

    enum CodingKeys: String, CodingKey {
        case url
        case thumbURL = "thumb_url"
    }
}

struct EventRecords: Codable {
    let single: RecordDetail?
    let average: RecordDetail?
}

struct RecordDetail: Codable {
    let best: Int // in centiseconds
    let worldRank: Int?
    let continentRank: Int?
    let countryRank: Int?

    enum CodingKeys: String, CodingKey {
        case best
        case worldRank = "world_rank"
        case continentRank = "continent_rank"
        case countryRank = "country_rank"
    }
}
