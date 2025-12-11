//
//  CompetitionTests.swift
//  PermuteTests
//
//  Created for WCA Integration.
//

import XCTest
import CoreLocation
@testable import Permute

class CompetitionTests: XCTestCase {

    func testCompetitionDecoding() throws {
        let json = """
        [
            {
                "id": "TestComp2025",
                "name": "Test Comp 2025",
                "city": "New York",
                "country_iso2": "US",
                "start_date": "2025-05-20",
                "end_date": "2025-05-21",
                "latitude_degrees": 40.7128,
                "longitude_degrees": -74.0060
            }
        ]
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let competitions = try decoder.decode([Competition].self, from: json)

        XCTAssertEqual(competitions.count, 1)
        XCTAssertEqual(competitions[0].name, "Test Comp 2025")
        XCTAssertEqual(competitions[0].city, "New York")
        XCTAssertEqual(competitions[0].country_iso2, "US")
        XCTAssertEqual(competitions[0].latitude_degrees, 40.7128)
        XCTAssertEqual(competitions[0].longitude_degrees, -74.0060)
        XCTAssertEqual(competitions[0].coordinate.latitude, 40.7128)
    }

    func testDistanceCalculation() {
        // Approximate coordinates
        // NYC: 40.7128, -74.0060
        // Philly: 39.9526, -75.1652
        // Distance is approx 80-90 miles.

        let nyc = CLLocation(latitude: 40.7128, longitude: -74.0060)
        let philly = CLLocation(latitude: 39.9526, longitude: -75.1652)

        let distanceMeters = nyc.distance(from: philly)
        let miles = distanceMeters / 1609.34

        XCTAssertTrue(miles > 80 && miles < 100, "Distance should be around 90 miles, calculated: \(miles)")
    }

    func testSortingByDistance() {
        let userLocation = CLLocation(latitude: 40.7128, longitude: -74.0060) // NYC

        // Comps
        let compNear = Competition(id: "Near", name: "Near", city: "Newark", country_iso2: "US", start_date: "2025-01-01", end_date: "2025-01-01", latitude_degrees: 40.7357, longitude_degrees: -74.1724) // Newark, NJ

        let compFar = Competition(id: "Far", name: "Far", city: "Los Angeles", country_iso2: "US", start_date: "2025-01-01", end_date: "2025-01-01", latitude_degrees: 34.0522, longitude_degrees: -118.2437) // LA

        let comps = [compFar, compNear]

        let sorted = comps.sorted { c1, c2 in
            let loc1 = CLLocation(latitude: c1.latitude_degrees, longitude: c1.longitude_degrees)
            let loc2 = CLLocation(latitude: c2.latitude_degrees, longitude: c2.longitude_degrees)
            return loc1.distance(from: userLocation) < loc2.distance(from: userLocation)
        }

        XCTAssertEqual(sorted.first?.id, "Near")
        XCTAssertEqual(sorted.last?.id, "Far")
    }
}
