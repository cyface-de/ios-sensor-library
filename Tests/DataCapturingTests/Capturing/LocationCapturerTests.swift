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
import Testing
@testable import DataCapturing
import Foundation
import Combine

@Test("Test that location capturer triggers the correct messages.", .tags(.capturing))
func locationCapturerHappyPath() async throws {
    // Arrange
    let oocut = SmartphoneLocationCapturer(lifecycleQueue: DispatchQueue(label: "locationCapturer")) {
        return MockLocationManager()
    }
    var messageLog = [String]()
    var cancellable: AnyCancellable?

    // Act
    await confirmation(expectedCount: 5) { confirmed in
        var counter = 0
        await withUnsafeContinuation { continuation in
            cancellable = oocut.start().sink { message in
                switch message {
                case .capturedLocation(let location):
                    messageLog.append("\(location)")
                    confirmed()
                    counter += 1
                    if counter == 5 {
                        continuation.resume()
                    }
                default:
                    break
                }
            }
        }
    }

    // Assert
    cancellable?.cancel()
    oocut.stop()
    #expect(messageLog.count == 5)
    #expect(messageLog[0].starts(with: "GeoLocation (latitude: 48.1331, longitude: 11.5763, accuracy: 0.0, speed: -1.0"))
    #expect(messageLog[1].starts(with: "GeoLocation (latitude: 48.1331, longitude: 11.5763, accuracy: 0.0, speed: -1.0"))
    #expect(messageLog[2].starts(with: "GeoLocation (latitude: 48.1331, longitude: 11.5763, accuracy: 0.0, speed: -1.0"))
    #expect(messageLog[3].starts(with: "GeoLocation (latitude: 48.1331, longitude: 11.5763, accuracy: 0.0, speed: -1.0"))
    #expect(messageLog[4].starts(with: "GeoLocation (latitude: 48.1331, longitude: 11.5763, accuracy: 0.0, speed: -1.0"))
}

@Test("Creating a location capturer does not read the authorization status, since that may block the main thread.", .tags(.capturing))
func locationCapturerInitDoesNotReadAuthorizationStatus() {
    let locationManager = MockLocationManager()

    _ = SmartphoneLocationCapturer(lifecycleQueue: DispatchQueue(label: "locationCapturer")) {
        return locationManager
    }

    #expect(locationManager.authorizationStatusReadCount == 0)
    #expect(locationManager.authorizationRequestCount == 0)
}

@Test("Starting a location capturer asks for the authorization without reading the authorization status.", .tags(.capturing))
func locationCapturerStartRequestsAuthorization() {
    let locationManager = MockLocationManager()
    let oocut = SmartphoneLocationCapturer(lifecycleQueue: DispatchQueue(label: "locationCapturer")) {
        return locationManager
    }

    _ = oocut.start()

    #expect(locationManager.authorizationStatusReadCount == 0)
    #expect(locationManager.authorizationRequestCount == 1)
    #expect(locationManager.locationValueSimulator != nil)
    oocut.stop()
}

@Test("Location updates stop if the user withdraws the authorization and start again if it is given again.", .tags(.capturing))
func locationCapturerFollowsAuthorizationChanges() {
    let locationManager = MockLocationManager()
    let oocut = SmartphoneLocationCapturer(lifecycleQueue: DispatchQueue(label: "locationCapturer")) {
        return locationManager
    }
    _ = oocut.start()

    locationManager.simulatedAuthorizationStatus = .denied
    oocut.locationManagerDidChangeAuthorization(locationManager.locationManager)
    #expect(locationManager.locationValueSimulator == nil)

    locationManager.simulatedAuthorizationStatus = .authorizedWhenInUse
    oocut.locationManagerDidChangeAuthorization(locationManager.locationManager)
    #expect(locationManager.locationValueSimulator != nil)

    oocut.stop()
}

@Test("A stopped location capturer ignores changes of the authorization.", .tags(.capturing))
func stoppedLocationCapturerIgnoresAuthorizationChanges() {
    let locationManager = MockLocationManager()
    let oocut = SmartphoneLocationCapturer(lifecycleQueue: DispatchQueue(label: "locationCapturer")) {
        return locationManager
    }
    _ = oocut.start()
    oocut.stop()

    locationManager.simulatedAuthorizationStatus = .authorizedAlways
    oocut.locationManagerDidChangeAuthorization(locationManager.locationManager)

    #expect(locationManager.locationValueSimulator == nil)
}
