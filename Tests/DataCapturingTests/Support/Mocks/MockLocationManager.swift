/*
 * Copyright 2024-2026 Cyface GmbH
 *
 * This file is part of the Cyface SDK for iOS.
 *
 * The Cyface SDK for iOS is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Cyface SDK for iOS is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Cyface SDK for iOS. If not, see <http://www.gnu.org/licenses/>.
 */
import DataCapturing
import CoreLocation

/**
 An implementation of ``LocationManager`` used for mocking an actual `CLLocationManager` during testing.

 This class allows to execute code requiring locations without having the actual hardware.
 New locations are simulated via a timer, that is called once every second with the same location each time.

 - Author: Klemens Muthmann
 */
class MockLocationManager: LocationManager {
    // MARK: - Properties
    /// Called on each new location.
    var locationDelegate: (any CLLocationManagerDelegate)?

    /// This is required to submit to the delegate on calls to `CLLocationManagerDelegate.locationManager`.
    let locationManager = CLLocationManager()

    /// The authorization status reported by this mock. Tests may change it to simulate the user's decision.
    var simulatedAuthorizationStatus: CLAuthorizationStatus = CLAuthorizationStatus.notDetermined
    /// How often the authorization status was read. On a real device each read may block the calling thread.
    private(set) var authorizationStatusReadCount = 0
    /// How often the authorization was requested.
    private(set) var authorizationRequestCount = 0

    var authorizationStatus: CLAuthorizationStatus {
        authorizationStatusReadCount += 1
        return simulatedAuthorizationStatus
    }

    /// The timer used to simulate regular location updates.
    var locationValueSimulator: DispatchSourceTimer?

    // MARK: - Methods
    func startUpdatingLocation() {
        locationValueSimulator = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInitiated))
        locationValueSimulator?.setEventHandler { [weak self] in
            if let self = self {
                let location = CLLocation(latitude: 48.1331, longitude: 11.5763)
                self.locationDelegate?.locationManager!(
                    self.locationManager,
                    didUpdateLocations: [location]
                )
            }

        }
        locationValueSimulator?.schedule(deadline: .now(), repeating: .seconds(1))
        locationValueSimulator?.resume()
    }
    
    func stopUpdatingLocation() {
        locationValueSimulator?.cancel()
        locationValueSimulator = nil
    }
    
    func requestAlwaysAuthorization() {
        authorizationRequestCount += 1
        simulatedAuthorizationStatus = CLAuthorizationStatus.authorizedAlways
    }
}
