//
//  SerializationTests.swift
//  DataCapturing
//
//  Created by Klemens Muthmann on 22.10.24.
//
import Testing
import Foundation
@testable import DataCapturing

@Test("Test that serializing a measurement provides some data and does not crash!")
func measurementSerialization() throws {
    let oocut = MeasurementSerializer()
    let measurement = FinishedMeasurement(identifier: 1)

    let serializedMeasurement = try oocut.serialize(serializable: measurement)
    try #require(serializedMeasurement.count > 0)
}

@Test("Test that serializing a measurement provides some data and does not crash!")
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

@Test("Test that the difference encoder provides a correct value!")
func valueDifferential() throws {
    let oocut = DiffValue(start: 5)

    let difference = try oocut.diff(value: 10)

    try #require(difference == 5)
}

@Test("Test that the inverse of the difference encoder provides a correct value!")
func valueUndifferential() throws {
    let oocut = DiffValue(start: 5)

    let undiffed = try oocut.undiff(value: 5)

    try #require(undiffed == 10)
}

@Test("Test that double equality works as expected!", arguments: [
    (3.0, 3.0, 1),
    (10.1-9.93, 0.17, 2),
    (110-8.59, 101.41, 3)
])
func doubleEquality(op1: Double, op2: Double, precise: Int) throws {
    try #require(op1.equal(op2, precise: precise))
}
