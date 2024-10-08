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

import XCTest
import CoreMotion
import Combine
@testable import DataCapturing

/**
 This test is intended to test capturing some data in isolation.

 - Author: Klemens Muthmann
 - Version: 2.4.1
 - Since: 1.0.0
 */
class MeasurementTests: XCTestCase {

    /**
     Checks correct workings of a simple start/stop lifecycle.

     - Throws:
        - `DataCapturingError.isPaused` if the service was paused and thus starting or stopping it makes no sense. If you need to continue call `resume(((DataCapturingEvent) -> Void))`.
     */
    func testStartStop_HappyPath() async throws {
        let sensorCapturer = MocSensorCapturer()
        let locationCapturer = MocLocationCapturer()
        let measurement = MeasurementImpl(sensorCapturer: sensorCapturer, locationCapturer: locationCapturer)
        XCTAssertEqual(measurement.isPaused, false)
        XCTAssertEqual(measurement.isRunning, false)

        try measurement.start()
        XCTAssertEqual(measurement.isPaused, false)
        XCTAssertEqual(measurement.isRunning, true)

        try measurement.stop()
        XCTAssertEqual(measurement.isPaused, false)
        XCTAssertEqual(measurement.isRunning, false)
    }

    /**
     Checks the correct execution of a typical lifecylce with a pause in between.

     - Throws:
        - `DataCapturingError.isPaused` if the service was paused and thus starting, pausing it again or stopping it makes no sense. If you need to continue call `resume(((DataCapturingEvent) -> Void))`.
        - `DataCapturingError.notRunning` if the service was not running and thus pausing it makes no sense.
        - `DataCapturingError.notPaused`: If the service was not paused and thus resuming it makes no sense.
        - `DataCapturingError.isRunning`: If the service was running and thus resuming it makes no sense.
        - `DataCapturingError.noCurrentMeasurement`: If no current measurement is available while resuming data capturing.
     */
    /*func testStartPauseResumeStop_HappyPath() throws {
    }*/

    func testStartPauseResumeStopResumeStop() throws {
    }

    func testStartPauseStop_HappyPath() throws {
    }

    /**
     Checks that calling `start` twice causes no errors and is gracefully ignored.

     - Throws:
        - `DataCapturingError.isPaused` if the service was paused and thus starting or stopping it makes no sense. If you need to continue call `resume(((DataCapturingEvent) -> Void))`.
     */
    func testDoubleStart() throws {
    }

    /**
     Checks that calling resume on a stopped service twice causes the appropriate `DataCapturingError` and leaves the `DataCapturingService` in a state where stopping is still possible.

     - Throws:
        - `DataCapturingError.isPaused` if the service was paused and thus starting, pausing it again or stopping it makes no sense. If you need to continue call `resume(((DataCapturingEvent) -> Void))`.
        - `DataCapturingError.notRunning` if the service was not running and thus pausing it makes no sense.
        - `DataCapturingError.notPaused`: If the service was not paused and thus resuming it makes no sense.
        - `DataCapturingError.isRunning`: If the service was running and thus resuming it makes no sense.
        - `DataCapturingError.noCurrentMeasurement`: If no current measurement is available while resuming data capturing.
     */
    func testDoubleResume() throws {
    }

    /**
     Checks that pausing the service multiple times causes the appropriate `DataCapturingError` and leave the service in a state, where it can still be resumed.

     - Throws:
        - `DataCapturingError.isPaused` if the service was paused and thus starting, pausing it again or stopping it makes no sense. If you need to continue call `resume(((DataCapturingEvent) -> Void))`.
        - `DataCapturingError.notRunning` if the service was not running and thus pausing it makes no sense.
        - `DataCapturingError.notPaused`: If the service was not paused and thus resuming it makes no sense.
        - `DataCapturingError.isRunning`: If the service was running and thus resuming it makes no sense.
        - `DataCapturingError.noCurrentMeasurement`: If no current measurement is available while resuming data capturing.
     */
    func testDoublePause() throws {
    }

    /**
     Checks that stopping a running service multiple times causes no errors and leaves the service in the expected stopped state.

     - Throws:
        - `DataCapturingError.isPaused` if the service was paused and thus starting it makes no sense. If you need to continue call `resume(((DataCapturingEvent) -> Void))`.
        - `DataCapturingError.isPaused` if the service was paused and thus stopping it makes no sense.
     */
    func testDoubleStop() throws {
    }

    /// Checks that pausing a not started service results in an exception and does not change the `DataCapturingService` state.
    func testPauseFromIdle() {
    }

    /// Checks that resuming a not started service results in an exception and does not change the `DataCapturingService` state.
    func testResumeFromIdle() {
    }

    /**
     Checks that stopping a stopped service causes no errors and leave the `DataCapturingService` in a stopped state

     - Throws:
        - `DataCapturingError.isPaused` if the service was paused and thus stopping it makes no sense.
    */
    func testStopFromIdle() throws {
    }

    /**
    Tests the performance of saving a batch of measurement data during data capturing.
    This time must never exceed the time it takes to capture that data.

     - Throws:
        - PersistenceError.measurementNotCreatable(timestamp) If CoreData was unable to create the new entity.
        - PersistenceError.noContext If there is no current context and no background context can be created. If this happens something is seriously wrong with CoreData.
        - Some unspecified errors from within CoreData.
     */
    func testLifecyclePerformance() throws {
    }

    /**
     Tests whether using a reduced update interval for location update events, works as expected.

     - Throws:
        - `PersistenceError` If the currently captured measurement was not found in the database.
        - Some unspecified errors from within *CoreData*.
     */
    func testWithLowerUpdateInterval_HappyPath() throws {
    }

    /// After the App has been paused very long iOS will kill it. This deletes the paused state in memory. This test checks that recreating this state from the database is successful.
    func testResumeAfterLongPause_ShouldNotThrowAnException() throws {
    }

    /// In case there already is a paused measurement after App restart, starting should still be successful and just output a warning.
    func testStartPausedService_FinishesPausedMeasurementAndThrowsNoException() throws {
    }

    /// Tests that starting a new measurement and changing the modality during runtime, creates two change events.
    func testChangeModality_EventLogContainsTwoModalities() throws {
    }

    /// Tests that changing to the same modality twice does not produce a new modality change event.
    func testChangeModalityToSameModalityTwice_EventLogStillContainsOnlyTwoModalities() throws {
    }

    /// Tests that changing modality during a pause works as expected.
    func testChangeModalityWhilePaused_EventLogStillContainsModalityChange() throws {
    }
}

struct MocSensorCapturer: SensorCapturer {
    let messageBus = PassthroughSubject<DataCapturing.Message, Never>()
    func start() -> AnyPublisher<DataCapturing.Message, Never> {
        messageBus.send(Message.started(timestamp: Date()))
        return messageBus.eraseToAnyPublisher()
    }
    
    func stop() {
        messageBus.send(Message.stopped(timestamp: Date()))
    }
}

struct MocLocationCapturer: LocationCapturer {
    let messageBus = PassthroughSubject<DataCapturing.Message, Never>()
    func start() -> AnyPublisher<DataCapturing.Message, Never> {
        messageBus.send(Message.started(timestamp: Date()))
        return messageBus.eraseToAnyPublisher()
    }
    
    func stop() {
        messageBus.send(Message.stopped(timestamp: Date()))
    }
    

}
