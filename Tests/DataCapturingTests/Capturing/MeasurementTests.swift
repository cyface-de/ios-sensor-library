/*
 * Copyright 2017-2024 Cyface GmbH
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
import CoreMotion
import Combine
import OSLog
@testable import DataCapturing

/**
 This test is intended to test capturing some data in isolation.

 - Author: Klemens Muthmann
 */
@Suite(.tags(.capturing))
struct MeasurementTests {

    /// `MeasurementImpl` used for testing.
    let measurement = MeasurementImpl(sensorCapturer: MockSensorCapturer(), locationCapturer: MockLocationCapturer())

    @Test("Checks correct workings of a simple start/stop lifecycle.")
    func startStop_HappyPath() async throws {
        try #require(measurement.isPaused == false)
        try #require(measurement.isRunning == false)

        try measurement.start()
        try #require(measurement.isPaused == false)
        try #require(measurement.isRunning == true)

        try measurement.stop()
        try #require(measurement.isPaused == false)
        try #require(measurement.isRunning == false)
    }

    @Test("Check that the complete cycle of starting and stopping with a pause and resume in between works as expected.")
    func startPauseResumeStopResumeStop() throws {
        try #require(!measurement.isPaused)
        try #require(!measurement.isRunning)

        try measurement.start()
        try #require(!measurement.isPaused)
        try #require(measurement.isRunning)

        try measurement.pause()
        try #require(measurement.isPaused)
        try #require(!measurement.isRunning)

        try measurement.resume()
        try #require(!measurement.isPaused)
        try #require(measurement.isRunning)

        try measurement.stop()
        try #require(!measurement.isPaused)
        try #require(!measurement.isRunning)
    }

    @Test("Stopping directly from within a paused measurement should work.")
    func startPauseStop_HappyPath() throws {
        try #require(!measurement.isPaused)
        try #require(!measurement.isRunning)

        try measurement.start()
        try #require(!measurement.isPaused)
        try #require(measurement.isRunning)

        try measurement.pause()
        try #require(measurement.isPaused)
        try #require(!measurement.isRunning)

        try measurement.stop()
        try #require(!measurement.isPaused)
        try #require(!measurement.isRunning)
    }

    @Test("Checks that calling `start` twice causes no errors and is gracefully ignored.")
    func doubleStart() throws {
        try #require(!measurement.isPaused)
        try #require(!measurement.isRunning)

        try measurement.start()
        try #require(!measurement.isPaused)
        try #require(measurement.isRunning)
        
        try measurement.start()
        try #require(!measurement.isPaused)
        try #require(measurement.isRunning)
    }

    @Test("Check that resuming twice causes the expected error and leaves the Measurement in a state where stopping is possible.")
    func doubleResume() throws {
        try measurement.start()

        try measurement.pause()

        try measurement.resume()

        #expect(throws: MeasurementError.notPaused) {
            try measurement.resume()
        }

        try measurement.stop()
    }

    @Test("Checks that pausing the service multiple times causes the appropriate error and leave the service in a state, where it can still be resumed.")
    func doublePause() throws {
        try measurement.start()

        try measurement.pause()

        #expect(throws: MeasurementError.notRunning) {
            try measurement.pause()
        }

        try measurement.resume()
    }

    @Test("Checks that stopping a running service multiple times causes the appropriate error and leaves the service in the expected stopped state.")
    func doubleStop() throws {
        try measurement.start()
        try #require(!measurement.isPaused)
        try #require(measurement.isRunning)

        try measurement.stop()
        try #require(!measurement.isPaused)
        try #require(!measurement.isRunning)

        #expect(throws: MeasurementError.notRunning) {
            try measurement.stop()
        }
        try #require(!measurement.isPaused)
        try #require(!measurement.isRunning)
    }

    @Test("Checks that pausing a not started service results in an exception and does not change the `Measurement` state.")
    func pauseFromIdle() {
        #expect(!measurement.isPaused)
        #expect(!measurement.isRunning)

        #expect(throws: MeasurementError.notRunning) {
            try measurement.pause()
        }

        #expect(!measurement.isPaused)
        #expect(!measurement.isRunning)
    }

    @Test("Checks that resuming a not started service results in an exception and does not change the `Measurement` state.")
    func resumeFromIdle() {
        #expect(!measurement.isPaused)
        #expect(!measurement.isRunning)

        #expect(throws: MeasurementError.notPaused) {
            try measurement.resume()
        }

        #expect(!measurement.isPaused)
        #expect(!measurement.isRunning)
    }

    @Test("Checks that stopping a stopped measurement causes no errors and leave the `Measurement` in a stopped state")
    func stopFromIdle() throws {
        try measurement.start()

        try measurement.stop()
        #expect(!measurement.isPaused)
        #expect(!measurement.isRunning)

        #expect(throws: MeasurementError.notRunning) {
            try measurement.stop()
        }

        #expect(!measurement.isPaused)
        #expect(!measurement.isRunning)
    }

    @Test("Tests that starting a new measurement and changing the modality during runtime, creates two change events.")
    func changeModality_EventLogContainsTwoModalities() async throws {
        var messageLog = [String]()

        try await confirmation() { confirmation in
            let cancellable = measurement.events.sink(receiveCompletion: { _ in confirmation() } ) { message in
                switch message {
                case .started(timestamp: _):
                    messageLog.append("started")
                case .stopped(timestamp: _):
                    messageLog.append("stopped")
                case .modalityChanged(to: let modality):
                    messageLog.append("changed to \(modality)")
                default:
                    Issue.record("Unexpected message \(message).")
                }
            }

            measurement.changeModality(to: "BICYCLE")
            try measurement.start()
            measurement.changeModality(to: "CAR")
            try measurement.stop()

            cancellable.cancel()
        }

        try #require(messageLog.count == 4)
        #expect("changed to BICYCLE" == messageLog[0])
        #expect("started" == messageLog[1])
        #expect("changed to CAR" == messageLog[2])
        #expect("stopped" == messageLog[3])
    }

    @Test("Tests that changing modality during a pause works as expected.")
    func changeModalityWhilePaused_EventLogStillContainsModalityChange() async throws {
        var messageLog = [String]()

        try await confirmation { confirmation in
            let cancellable = measurement.events.sink(receiveCompletion: { _ in
                confirmation()
            }, receiveValue: { message in
                switch message {
                case .modalityChanged(to: let modality):
                    messageLog.append("\(modality)")
                case .paused(timestamp: _):
                    messageLog.append("paused")
                case .resumed(timestamp: _):
                    messageLog.append("resumed")
                case .started(timestamp: _):
                    messageLog.append("started")
                case .stopped(timestamp: _):
                    messageLog.append("stopped")
                default:
                    Issue.record("Encountered unexpected message: \(message)")
                }
            })

            measurement.changeModality(to: "BICYCLE")
            try measurement.start()
            try measurement.pause()
            measurement.changeModality(to: "CAR")
            try measurement.resume()
            try measurement.stop()
            cancellable.cancel()
        }

        #expect(messageLog.count == 6)
        #expect(messageLog[0] == "BICYCLE")
        #expect(messageLog[1] == "started")
        #expect(messageLog[2] == "paused")
        #expect(messageLog[3] == "CAR")
        #expect(messageLog[4] == "resumed")
        #expect(messageLog[5] == "stopped")
    }
}

/// A mocked version of a `SensorCapturer` that actually does nothing.
struct MockSensorCapturer: SensorCapturer {
    let messageBus = PassthroughSubject<DataCapturing.Message, Never>()
    func start() -> AnyPublisher<DataCapturing.Message, Never> {
        return messageBus.eraseToAnyPublisher()
    }
    
    func stop() { }
}

/// A mocked version of a `MockLocationCapturer` that actually does nothing.
struct MockLocationCapturer: LocationCapturer {
    let messageBus = PassthroughSubject<DataCapturing.Message, Never>()
    func start() -> AnyPublisher<DataCapturing.Message, Never> {
        return messageBus.eraseToAnyPublisher()
    }
    
    func stop() {
        os_log(.debug, log: .capturing, "MockLocationCapturer: Stopping!")
        messageBus.send(completion: .finished)
        os_log(.debug, log: .capturing, "MockLocationCapturer: Stopped Successfully!")
    }
}
