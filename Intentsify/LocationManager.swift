//
//  LocationManager.swift
//  Intentsify
//
//  Created by Bennett Yetra on 12/10/24.
//

import CoreLocation
import CloudKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()

    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var currentLocation: CLLocation?

    override init() {
        self.authorizationStatus = CLLocationManager().authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        } else {
            print("Location services are not enabled.")
        }
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            print("No locations available.")
            return
        }
        DispatchQueue.main.async {
            self.currentLocation = location
        }
        
        // Save location to CloudKit
        saveLocationToCloudKit(location)
    }

    private func saveLocationToCloudKit(_ location: CLLocation) {
        let recordID = CKRecord.ID(recordName: UUID().uuidString)
        let locationRecord = CKRecord(recordType: "location", recordID: recordID)
        locationRecord["location"] = location

        let publicDatabase = CKContainer.default().publicCloudDatabase
        publicDatabase.save(locationRecord) { record, error in
            if let error = error {
                print("Error saving location to CloudKit: \(error.localizedDescription)")
            } else {
                print("Location successfully saved to CloudKit.")
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to update location: \(error.localizedDescription)")
    }
}
