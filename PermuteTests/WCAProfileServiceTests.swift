//
//  WCAProfileServiceTests.swift
//  PermuteTests
//
//  Created by Jules for WCA Profile Integration.
//

import XCTest
@testable import Permute

class WCAProfileServiceTests: XCTestCase {

    func testWCAUserParsing() throws {
        let json = """
        {
            "me": {
                "id": 1234,
                "wca_id": "2025SMIT01",
                "name": "John Smith",
                "country_iso2": "US",
                "avatar": {
                    "url": "https://example.com/avatar.jpg"
                }
            }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(MeResponse.self, from: json)
        let user = response.me

        XCTAssertEqual(user.id, 1234)
        XCTAssertEqual(user.wcaID, "2025SMIT01")
        XCTAssertEqual(user.name, "John Smith")
        XCTAssertEqual(user.countryISO2, "US")
        XCTAssertEqual(user.avatarURL, "https://example.com/avatar.jpg")
    }

    func testWCAUserParsingNoWCAID() throws {
        let json = """
        {
            "me": {
                "id": 5678,
                "wca_id": null,
                "name": "New Cuber",
                "country_iso2": "CA",
                "avatar": {
                    "url": null
                }
            }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let response = try decoder.decode(MeResponse.self, from: json)
        let user = response.me

        XCTAssertEqual(user.id, 5678)
        XCTAssertNil(user.wcaID)
        XCTAssertEqual(user.name, "New Cuber")
        XCTAssertEqual(user.countryISO2, "CA")
        XCTAssertNil(user.avatarURL)
    }
}
