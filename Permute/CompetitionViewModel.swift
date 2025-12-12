//
//  CompetitionViewModel.swift
//  Permute
//
//  Created for WCA Integration.
//

import SwiftUI
import CoreLocation

@MainActor
class CompetitionViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var competitions: [Competition] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Location
    private let locationManager = CLLocationManager()
    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    // MARK: - Location Manager Delegate

    func requestLocation() {
        // NOTE: Info.plist must contain NSLocationWhenInUseUsageDescription key.
        // We have added Permute/Info.plist but integration into the project file
        // depends on the Xcode project settings.
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            if self.authorizationStatus == .authorizedWhenInUse || self.authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            Task { @MainActor in
                self.userLocation = location
                // Auto-fetch competitions if we have a location and haven't fetched yet
                if self.competitions.isEmpty {
                    await self.fetchCompetitionsBasedOnLocation()
                }
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error.localizedDescription)")
    }

    // MARK: - Fetching

    func fetchCompetitionsBasedOnLocation() async {
        guard let location = userLocation else {
            // Default fetch if no location? Or just wait?
            // Let's try to fetch US by default or show error.
            // Actually, we can just return if no location, UI will handle empty state.
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Reverse Geocode to get country code
            let geocoder = CLGeocoder()
            let placemarks = try await geocoder.reverseGeocodeLocation(location)

            guard let countryCode = placemarks.first?.isoCountryCode else {
                throw NSError(domain: "CompetitionViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not determine country from location."])
            }

            // Fetch
            let fetchedComps = try await WCANetworkManager.shared.fetchCompetitions(countryIso2: countryCode, startDate: Date())

            // Filter & Sort
            // Distance calculation
            let sortedComps = fetchedComps.sorted { comp1, comp2 in
                let loc1 = CLLocation(latitude: comp1.latitude_degrees, longitude: comp1.longitude_degrees)
                let loc2 = CLLocation(latitude: comp2.latitude_degrees, longitude: comp2.longitude_degrees)

                let dist1 = loc1.distance(from: location)
                let dist2 = loc2.distance(from: location)

                return dist1 < dist2
            }

            self.competitions = sortedComps

        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func distanceTo(_ competition: Competition) -> String {
        guard let userLoc = userLocation else { return "--" }
        let compLoc = CLLocation(latitude: competition.latitude_degrees, longitude: competition.longitude_degrees)
        let distanceMeters = compLoc.distance(from: userLoc)

        // Convert to miles (or km depending on locale, but let's stick to miles as per prompt example)
        // Prompt example: "12 miles away"
        let miles = distanceMeters / 1609.34
        return String(format: "%.1f miles away", miles)
    }
}
