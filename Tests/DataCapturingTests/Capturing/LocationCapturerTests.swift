/*
 * Copyright 2024 Cyface GmbH
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
