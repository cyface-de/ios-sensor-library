/*
 * Copyright 2018 - 2024 Cyface GmbH
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
import Foundation
@testable import DataCapturing

/// Test the serialization of batches of sensor values.
@Test(
    "Serialization of a few sensor values into binary format works as expected!",
    .tags(.persistence, .file)
)
func serializeSensorValues() throws {
    let sensorValueSerializer = SensorValueSerializer()

    // 1
    let firstBatch = try sensorValueSerializer.serialize(serializable: [SensorValue(timestamp: Date(timeIntervalSince1970: 10.000), x: 1.0, y: 1.0, z: 1.0), SensorValue(timestamp: Date(timeIntervalSince1970: 10.100), x: 1.1, y: 1.1, z: 1.1), SensorValue(timestamp: Date(timeIntervalSince1970: 10.200), x: -2.0, y: -2.0, z: -2.0)])

    // 2
    let secondBatch = try sensorValueSerializer.serialize(serializable: [SensorValue(timestamp: Date(timeIntervalSince1970: 10.300), x: 1.5, y: 1.5, z: 1.5), SensorValue(timestamp: Date(timeIntervalSince1970: 10.400), x: 1.2, y: 1.2, z: 1.2)])

    // 3
    var data = Data()
    data.append(contentsOf: firstBatch)
    data.append(contentsOf: secondBatch)


    // 4
    var measurementBytes = De_Cyface_Protos_Model_MeasurementBytes()
    measurementBytes.formatVersion = 2
    measurementBytes.accelerationsBinary = data

    let deserializedMeasurement = try De_Cyface_Protos_Model_Measurement(serializedBytes: measurementBytes.serializedData())

    #expect(deserializedMeasurement.accelerationsBinary.accelerations[0].z[0] == 1000)
    #expect(deserializedMeasurement.accelerationsBinary.accelerations[0].z[1] == 100)
    #expect(deserializedMeasurement.accelerationsBinary.accelerations[0].z[2] == -3100)
    #expect(deserializedMeasurement.accelerationsBinary.accelerations[0].timestamp[0] == 10_000)
    #expect(deserializedMeasurement.accelerationsBinary.accelerations[0].timestamp[1] == 100)
    #expect(deserializedMeasurement.accelerationsBinary.accelerations[0].timestamp[2] == 100)
}

@Test(
    "Serialization of a few accelerations works as expected.",
    .tags(.persistence, .file)
)
func serializeAccelerations() throws {
    let sensorValues = [
        SensorValue(timestamp: Date(timeIntervalSince1970: 1.0), x: 0.016448974609375, y: 0.00030517578125, z: -1.000518798828125),
        SensorValue(timestamp: Date(timeIntervalSince1970: 2.0), x: 0.016448974609375, y: 0.0006256103515625, z: -1.0010223388671875),
        SensorValue(timestamp: Date(timeIntervalSince1970: 3.0), x: 0.01702880859375, y: -9.1552734375e-05, z: -1.001861572265625),
        SensorValue(timestamp: Date(timeIntervalSince1970: 4.0), x: 0.016082763671875, y: -0.0001678466796875, z: -1.0012664794921875),
        SensorValue(timestamp: Date(timeIntervalSince1970: 5.0), x: 0.0164947509765625, y: -0.001373291015625, z: -1.0015716552734375)]

    let expectedResult = [
        SensorValue(timestamp: Date(timeIntervalSince1970: 1.0), x: 0.016, y: 0.000, z: -1.000),
        SensorValue(timestamp: Date(timeIntervalSince1970: 2.0), x: 0.016, y: 0.000, z: -1.001),
        SensorValue(timestamp: Date(timeIntervalSince1970: 3.0), x: 0.017, y: 0.000, z: -1.001),
        SensorValue(timestamp: Date(timeIntervalSince1970: 4.0), x: 0.016, y: -0.000, z: -1.001),
        SensorValue(timestamp: Date(timeIntervalSince1970: 5.0), x: 0.016, y: -0.001, z: -1.001)]

    let oocut = SensorValueSerializer()

    let serializedAccelerations = try oocut.serialize(serializable: sensorValues)

    let deserializedAccelerations = try oocut.deserialize(data: serializedAccelerations)

    #expect(sensorValues.count == deserializedAccelerations.count)
    for i in 0..<sensorValues.count {
        #expect(expectedResult[i] == deserializedAccelerations[i])
    }
}

/// Tests if serialization of a simple empty measurement into the Cyface binary format works as expected.
@Test(
    "Check that serialization of an empty measurement raises no errors.",
    .tags(.persistence, .file)
)
func serializeEmptyMeasurement() throws {
    let oocut = MeasurementSerializer()
    let measurement = FinishedMeasurement(identifier: 1)
    measurement.tracks = []
    let res = try oocut.serialize(serializable: measurement)

    let deserializedMeasurement = try De_Cyface_Protos_Model_Measurement(
        serializedBytes: res[2...]
    )

    #expect(deserializedMeasurement.locationRecords.timestamp.isEmpty)
    #expect(!deserializedMeasurement.hasAccelerationsBinary)
    #expect(!deserializedMeasurement.hasCapturingLog)
    #expect(!deserializedMeasurement.hasDirectionsBinary)
    #expect(!deserializedMeasurement.hasRotationsBinary)
}

/**
 Tests if serialization works for uncompressed data.
 */
@Test(
    "Check that serialization of uncompressed data works as expected.",
    .tags(.persistence, .file)
)
func uncompressedSerialization() throws {
    let oocut = MeasurementSerializer()
    let res = try oocut.serialize(serializable: fixture())

    let deserializedMeasurement = try De_Cyface_Protos_Model_Measurement(serializedBytes: res[2...])
    assert(deserializedMeasurement)

}

/**
 Tests if serialization works for compressed data.
 */
@Test(
    "Check that serialization of compressed data works as expected.",
    .tags(.persistence, .file)
)
func compressedSerialization() throws {
    let oocut = MeasurementSerializer()
    let res = try oocut.serializeCompressed(serializable: fixture())

    let uncompressedData = res.inflate()
    guard let uncompressedData = uncompressedData else {
        Issue.record("Error unpacking zipped measurement!")
        return
    }

    assert(try De_Cyface_Protos_Model_Measurement(serializedBytes: uncompressedData[2...]))
}

@Test(
    "Test that serializing a measurement provides some data and does not crash!",
    .tags(.persistence, .file)
)
func measurementSerialization() throws {
    let oocut = MeasurementSerializer()
    let measurement = FinishedMeasurement(identifier: 1)

    let serializedMeasurement = try oocut.serialize(serializable: measurement)
    try #require(serializedMeasurement.count > 0)
}

@Test(
    "Test that serializing a measurement provides some data and does not crash!",
    .tags(.persistence, .file)
)
func sensorValueSerialization() throws {
    let oocut = SensorValueSerializer()
    let values = [
        SensorValue(timestamp: Date(timeIntervalSince1970: 2000), x: 1.0, y: 1.0, z: 1.0),
        SensorValue(timestamp: Date(timeIntervalSince1970: 3000), x: 1.0, y: 1.0, z: 1.0),
        SensorValue(timestamp: Date(timeIntervalSince1970: 4000), x: 1.0, y: 1.0, z: 1.0),
        SensorValue(timestamp: Date(timeIntervalSince1970: 5000), x: 1.0, y: 1.0, z: 1.0),
        SensorValue(timestamp: Date(timeIntervalSince1970: 6000), x: 1.0, y: 1.0, z: 1.0)
    ]

    let data = try oocut.serialize(serializable: values)
    let deserializedData = try oocut.deserialize(data: data)

    try #require(values == deserializedData)
}

/// Store a test fixture to CoreData and provide the measurement identifier.
func fixture() throws -> FinishedMeasurement {
    let track = Track()
    track.locations = [
        TestFixture.location(accuracy: 2.0, timestamp: Date(timeIntervalSince1970: 10.0)),
        TestFixture.location(accuracy: 2.0, timestamp: Date(timeIntervalSince1970: 10.1)),
        TestFixture.location(accuracy: 2.0, timestamp: Date(timeIntervalSince1970: 10.2))
    ]

    let sensorValueSerializer = SensorValueSerializer()
    let serializedAccelerations = try sensorValueSerializer.serialize(serializable: [
        SensorValue(timestamp: Date(timeIntervalSince1970: 10.0), x: 1.0, y: 1.0, z: 1.0),
        SensorValue(timestamp: Date(timeIntervalSince1970: 10.1), x: 1.0, y: 1.0, z: 1.0),
        SensorValue(timestamp: Date(timeIntervalSince1970: 10.2), x: 1.0, y: 1.0, z: 1.0)
    ])

    let measurement = FinishedMeasurement(
        identifier: 0,
        synchronizable: false,
        synchronized: false,
        time: Date(),
        events: [Event(time: Date(), type: .modalityTypeChange, value: "BICYCLE")],
        tracks: [track],
        accelerationData: serializedAccelerations,
        rotationData: Data(),
        directionData: Data()
    )

    return measurement
}

/// Assert the deserialized test result.
///
/// - see: `SerializationTest.fixture()`
func assert(_ result:De_Cyface_Protos_Model_Measurement) {
    #expect(!result.hasRotationsBinary)
    #expect(!result.hasCapturingLog)
    #expect(!result.hasDirectionsBinary)
    #expect(result.hasLocationRecords)
    #expect(result.hasAccelerationsBinary)

    #expect(result.locationRecords.timestamp.count == 3)
    #expect(result.locationRecords.timestamp[0] == 10_000)
    #expect(result.locationRecords.timestamp[1] == 100)
    #expect(result.locationRecords.timestamp[2] == 100)
    #expect(result.locationRecords.longitude[0] == 2000000)
    #expect(result.locationRecords.longitude[1] == 0)
    #expect(result.locationRecords.longitude[2] == 0)

    #expect(result.accelerationsBinary.accelerations.count == 1)
    let firstAccelerationsBatch = result.accelerationsBinary.accelerations[0]
    #expect(firstAccelerationsBatch.timestamp.count == 3)
    #expect(firstAccelerationsBatch.timestamp[0] == 10_000)
    #expect(firstAccelerationsBatch.timestamp[1] == 100)
    #expect(firstAccelerationsBatch.timestamp[2] == 100)

    #expect(result.events.count == 1)
}
