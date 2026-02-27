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
    let sensorValueFileFactory = try DefaultSensorValueFileFactory()

    let measurementBeforePause = MeasurementImpl(sensorCapturer: sensorCapturer, locationCapturer: locationCapturer)
    let dataStoreStack = try CoreDataStack()
    try await dataStoreStack.setup()
    let dataStorage = CapturedCoreDataStorage(dataStoreStack, 1.0, sensorValueFileFactory)
    _ = try dataStorage.subscribe(to: measurementBeforePause, "BICYCLE") { measurementIdentifier in
        print("Measurement \(measurementIdentifier) saved to Core Data")
    }
    try measurementBeforePause.start()
    try measurementBeforePause.pause()

    try await Task.sleep(nanoseconds: 2_000_000_000)


    let newDataStorage = CapturedCoreDataStorage(dataStoreStack, 1.0, sensorValueFileFactory)
    let (measurementAfterPause,identifier) = try #require(try newDataStorage.pausedMeasurement(sensorCapturer: sensorCapturer, locationCapturer: locationCapturer) { measurementIdentifier in
        print("Measurement \(measurementIdentifier) saved to Core Data")
    })
    try measurementAfterPause.resume()
    try measurementAfterPause.stop()
}

@Test(
    "Tests whether using a reduced update interval for location update events, works as expected.",
    .tags(.capturing)
)
func withLowerUpdateInterval_HappyPath() async {
    let sensorCapturer = SmartphoneSensorCapturer(accelerometerInterval: 1.0, gyroInterval: 1.0, directionsInterval: 1.0, motionManager: MockSensorManager())
    var messageLog = [String]()
    var cancellable: AnyCancellable?

    // Use withUnsafeContinuation so that continuation.resume() creates an explicit
    // happens-before between the sink's GCD writes to messageLog and the reads below.
    // A plain Task.sleep provides no such memory barrier, causing a data race where
    // messageLog may appear empty when read from the Swift concurrency executor.
    await withUnsafeContinuation { continuation in
        var accelerationCount = 0
        var directionCount = 0
        var rotationCount = 0
        var resumed = false

        cancellable = sensorCapturer.start().sink { message in
            switch message {
            case .capturedAcceleration(_):
                messageLog.append("acceleration")
                accelerationCount += 1
            case .capturedDirection(_):
                messageLog.append("direction")
                directionCount += 1
            case .capturedRotation(_):
                messageLog.append("rotation")
                rotationCount += 1
            default:
                Issue.record("Unexpected message \(message.description)")
            }

            if !resumed && accelerationCount >= 3 && directionCount >= 3 && rotationCount >= 3 {
                resumed = true
                continuation.resume()
            }
        }
    }

    cancellable?.cancel()
    sensorCapturer.stop()

    #expect(messageLog.count >= 9)
}
