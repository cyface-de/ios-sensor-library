/*
 * Copyright 2025 Cyface GmbH
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
import CoreData
import Testing
import Combine
import OSLog
@testable import DataCapturing

/**
 Tests that storing captured data works as expected.

 - Author: Klemens Muthmann
 */
struct CapturedCoreDataStorageTest {

    private let coreDataStack: CoreDataStack

    init() async throws {
        self.coreDataStack = try CoreDataStack(storeType: NSInMemoryStoreType)
        try await coreDataStack.setup()
    }

    @Test("Test that storing data without any sensor data causes no crashes and produces no unnecessary files.") func noOpTest() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        let oocut = CapturedCoreDataStorage(coreDataStack, TimeInterval(5), NoOpSensorValueFileFactory())
        let measurement = MeasurementImpl(sensorCapturer: NoOpSensorCapturer(), locationCapturer: MockLocationCapturer())

        let identifier = try oocut.subscribe(to: measurement, "BICYCLE") { identifier in
            // This is not called in time by the test because of the collect operator used internally.
            // Thus we add a new sink below, that gets called successfully.
        }

        try await confirmation() { confirmation in
            let cancellabel = measurement.events.sink(receiveCompletion: { _ in
                confirmation()
            }, receiveValue: { value in
                // Nothing to do here. We only need to react to the finished event.
            })

            try measurement.start()
            // Check that noe temporary files have been created.
            #expect(
                !FileManager.default.fileExists(
                    atPath: FileManager
                        .default
                        .temporaryDirectory
                        .appendingPathComponent("noop")
                        .absoluteString
                )
            )
            try measurement.stop()
            oocut.unsubscribe()
        }

        try #require(identifier == 1)
    }
}
