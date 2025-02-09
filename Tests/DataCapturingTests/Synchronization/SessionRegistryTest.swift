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

import XCTest
import CoreData
@testable import DataCapturing

/**
 Tests that ``SessionRegistry`` implementations work as expected.

 This test runs against an actual database.

 - Author: Klemens Muthmann
 */
class SessionRegistryTest: XCTestCase {
    /// Data storage used for testing.
    private var coreDataStack: CoreDataStack!

    /// Setup data storage before testing.
    open override func setUp() async throws{
        try await super.setUp()

        coreDataStack = try CoreDataStack()
        try await coreDataStack.setup()
    }

    /// Empty data storage after testing.
    override func tearDown() async throws {
        try coreDataStack.wrapInContext { context in
            let measurementFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Measurement")
            let measurementBatchDelete = NSBatchDeleteRequest(fetchRequest: measurementFetchRequest)
            try context.execute(measurementBatchDelete)

            let uploadSessionsFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "UploadSession")
            let uploadSessionsBatchDelete = NSBatchDeleteRequest(fetchRequest: uploadSessionsFetchRequest)
            try context.execute(uploadSessionsBatchDelete)
        }
        coreDataStack = nil

        try await super.tearDown()
    }

    /// Test that the data schema is working correctly.
    func testSessionRegistrySerialization() async throws {
        try coreDataStack.wrapInContext { context in
            let session = UploadSession(context: context)
            let measurement = MeasurementMO(context: context)
            measurement.time = Date()
            session.time = Date()
            session.measurement = measurement

            try context.save()
        }
    }

    /// Test that storing and loading a session works as expected.
    func testPersistentRegistryHappyPath() async throws {
        // Arrange
        let uploadFactory = MockUploadFactory()
        let oocut = PersistentSessionRegistry(dataStoreStack: coreDataStack, uploadFactory: uploadFactory)
        let mockMeasurement = FinishedMeasurement(identifier: 0)
        try coreDataStack.wrapInContext { context in
            let measurement = MeasurementMO(context: context)
            measurement.time = Date()
            measurement.identifier = Int64(mockMeasurement.identifier)

            try context.save()
        }
        let mockUpload = MockUpload(measurement: mockMeasurement)

        // Act
        try oocut.register(upload: mockUpload)

        // Assert
        XCTAssertEqual(mockUpload, try oocut.get(measurement: mockUpload.measurement) as? MockUpload)
    }

    /// Test that adding protocol records to a session works as expected.
    func testUpdateExistingSession() async throws {
        // Arrange
        let uploadFactory = MockUploadFactory()
        let oocut = PersistentSessionRegistry(dataStoreStack: coreDataStack, uploadFactory: uploadFactory)
        let mockMeasurement = FinishedMeasurement(identifier: 0)
        try coreDataStack.wrapInContext { context in
            let storedMeasurement = MeasurementMO(context: context)
            storedMeasurement.identifier = Int64(mockMeasurement.identifier)
            storedMeasurement.time = mockMeasurement.time

            try context.save()
        }
        let mockUpload = MockUploadFactory().upload(for: mockMeasurement)

        // Act
        try oocut.register(upload: mockUpload)
        try oocut.record(
            upload: mockUpload,
            RequestType.prerequest,
            httpStatusCode: 200,
            message: "OK",
            time: Date.now
        )

        // Assert
        let storedUpload = try oocut.get(measurement: mockMeasurement)
        let protocolCount = try coreDataStack.wrapInContextReturn { context in
            let request = UploadSession.fetchRequest()
            request.predicate = NSPredicate(
                format: "measurement.identifier=%d",
                mockMeasurement.identifier
            )
            request.fetchLimit = 1
            guard let session = try request.execute().first else {
                throw PersistenceError.sessionNotRegistered(mockMeasurement)
            }
            return session.uploadProtocol?.count
        }

        XCTAssertEqual(protocolCount, 1)
        XCTAssertEqual(storedUpload as? MockUpload, mockUpload as? MockUpload)
    }
}
