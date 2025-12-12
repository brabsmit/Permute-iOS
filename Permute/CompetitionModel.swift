//
//  CompetitionModel.swift
//  Permute
//
//  Created for WCA Integration.
//

import Foundation
import CoreLocation

struct Competition: Identifiable, Decodable {
    let id: String
    let name: String
    let city: String
    let country_iso2: String
    let start_date: String
    let end_date: String
    let latitude_degrees: Double
    let longitude_degrees: Double

    // Computed property for easy Location access
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude_degrees, longitude: longitude_degrees)
    }

    var startDate: Date? {
        Competition.dateFormatter.date(from: start_date)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
