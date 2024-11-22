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
import Combine
@testable import DataCapturing

@Test("Tests that the SensorCapturer works as expected, at least for the happy path.")
func sensorCapturerHappyPath() async {
    // Arrange
    let oocut = SmartphoneSensorCapturer(motionManager: MockSensorManager())
    var messageLog = [String]()
    var cancellable: AnyCancellable?

    // Act
    await withUnsafeContinuation { continuation in
        var accelerationCounter = 0
        var gyroCounter = 0
        var directionCounter = 0
        let publisher = oocut.start()
        cancellable = publisher
            .sink { message in
                switch message {
                case .capturedAcceleration(let acceleration):
                    messageLog.append("Acceleration: \(acceleration)")
                    accelerationCounter += 1
                case .capturedDirection(let direction):
                    messageLog.append("Direction \(direction)")
                    directionCounter += 1
                case .capturedRotation(let rotation):
                    messageLog.append("Rotation \(rotation)")
                    gyroCounter += 1
                default : break
                }

                if accelerationCounter > 5, directionCounter > 5, gyroCounter > 5 {
                    continuation.resume()
                }
            }
    }
    cancellable?.cancel()
    oocut.stop()

    // Assert
    #expect(messageLog.count > 15)
}
