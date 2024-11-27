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
import Foundation
import Testing
import Combine
@testable import DataCapturing

@Test(
    "Does a Measurement survive the App going to Background! After the App has been paused very long iOS will kill it. This deletes the paused state in memory. This test checks that recreating this state from the database is successful.",
    .tags(.capturing)
)
func measurementSurvivesBackground() async throws {
    let sensorCapturer = SmartphoneSensorCapturer(motionManager: MockSensorManager())
    let locationCapturer = SmartphoneLocationCapturer() {
        return MockLocationManager()
    }

    let measurementBeforePause = MeasurementImpl(sensorCapturer: sensorCapturer, locationCapturer: locationCapturer)
    let dataStoreStack = try CoreDataStack()
    try await dataStoreStack.setup()
    let dataStorage = CapturedCoreDataStorage(dataStoreStack, 1.0)
    _ = try dataStorage.subscribe(to: measurementBeforePause, "BICYCLE") { measurementIdentifier in
        print("Measurement \(measurementIdentifier) saved to Core Data")
    }
    try measurementBeforePause.start()
    try measurementBeforePause.pause()

    try await Task.sleep(nanoseconds: 2_000_000_000)

    let newDataStorage = CapturedCoreDataStorage(dataStoreStack, 1.0)
    let measurementAfterPause = try #require(try newDataStorage.pausedMeasurement(sensorCapturer: sensorCapturer, locationCapturer: locationCapturer) { measurementIdentifier in
        print("Measurement \(measurementIdentifier) saved to Core Data")
    })
    try measurementAfterPause.resume()
    try measurementAfterPause.stop()
}

@Test(
    "Tests whether using a reduced update interval for location update events, works as expected.",
    .tags(.capturing)
)
func withLowerUpdateInterval_HappyPath() async throws {
    let sensorCapturer = SmartphoneSensorCapturer(accelerometerInterval: 1.0, gyroInterval: 1.0, directionsInterval: 1.0, motionManager: MockSensorManager())
    var messageLog = [String]()
    var cancellable: AnyCancellable?

    cancellable = sensorCapturer.start().sink { message in
            switch message {
            case .capturedAcceleration(_):
                messageLog.append("acceleration")
            case .capturedDirection(_):
                messageLog.append("direction")
            case .capturedRotation(_):
                messageLog.append("rotation")
            default:
                Issue.record("Unexpected message \(message.description)")
            }
        }

    try await Task.sleep(nanoseconds: 5_000_000_000)
    sensorCapturer.stop()
    cancellable?.cancel()

    #expect(messageLog.count > 10)
    #expect(messageLog.count < 20)
}
