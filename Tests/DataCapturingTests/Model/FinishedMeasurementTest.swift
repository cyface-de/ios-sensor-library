//
//  FinishedMeasurementTest.swift
//  DataCapturing
//
//  Created by Klemens Muthmann on 21.10.24.
//

import Testing
import Foundation
@testable import DataCapturing

@Test("Check that the length of the measurement is calculated correctly by a FinishedMeasurement!")
func trackLength() throws {
    let track01 = Track()
    let track02 = Track()
    let track03 = Track()

    track01.locations = [
        GeoLocation(latitude: 52.210482, longitude: 11.61439 , accuracy: 8.0, speed: 0.0 ,time: Date(timeIntervalSince1970: 1696054697968), altitude: 0.0, verticalAccuracy: 0.0),
        GeoLocation(latitude: 52.210482, longitude: 11.61439 , accuracy: 6.0, speed: 0.0 ,time: Date(timeIntervalSince1970: 1696054698968), altitude: 0.0, verticalAccuracy: 0.0),
        GeoLocation(latitude: 52.210485, longitude: 11.614377, accuracy: 6.0, speed: 0.02,time: Date(timeIntervalSince1970: 1696054699968), altitude: 0.0, verticalAccuracy: 0.0),
        GeoLocation(latitude: 52.210488, longitude: 11.614377, accuracy: 6.0, speed: 0.0 ,time: Date(timeIntervalSince1970: 1696054700968), altitude: 0.0, verticalAccuracy: 0.0),
        GeoLocation(latitude: 52.210491, longitude: 11.614378, accuracy: 6.0, speed: 0.02,time: Date(timeIntervalSince1970: 1696054701968), altitude: 0.0, verticalAccuracy: 0.0),
        GeoLocation(latitude: 52.210498, longitude: 11.614388, accuracy: 6.0, speed: 0.04,time: Date(timeIntervalSince1970: 1696054702968), altitude: 0.0, verticalAccuracy: 0.0),
    ]
    track02.locations = [
        GeoLocation(latitude: 52.2105  , longitude: 11.614381, accuracy: 6.0, speed: 0.05,time: Date(timeIntervalSince1970: 1696054703968), altitude: 0.0, verticalAccuracy: 0.0),
        GeoLocation(latitude: 52.210503, longitude: 11.614376, accuracy: 6.0, speed: 0.3 ,time: Date(timeIntervalSince1970: 1696054704968), altitude: 0.0, verticalAccuracy: 0.0),
        GeoLocation(latitude: 52.210504, longitude: 11.614381, accuracy: 6.0, speed: 0.31,time: Date(timeIntervalSince1970: 1696054705968), altitude: 0.0, verticalAccuracy: 0.0),
        GeoLocation(latitude: 52.210507, longitude: 11.614387, accuracy: 6.0, speed: 0.31,time: Date(timeIntervalSince1970: 1696054706968), altitude: 0.0, verticalAccuracy: 0.0),
        GeoLocation(latitude: 52.210519, longitude: 11.614385, accuracy: 6.0, speed: 0.88,time: Date(timeIntervalSince1970: 1696054707968), altitude: 0.0, verticalAccuracy: 0.0),
        GeoLocation(latitude: 52.210532, longitude: 11.614384, accuracy: 6.0, speed: 1.37,time: Date(timeIntervalSince1970: 1696054708968), altitude: 0.0, verticalAccuracy: 0.0),
        GeoLocation(latitude: 52.210545, longitude: 11.614383, accuracy: 6.0, speed: 1.6 ,time: Date(timeIntervalSince1970: 1696054709968), altitude: 0.0, verticalAccuracy: 0.0),
    ]

    track03.locations = [
        GeoLocation(latitude: 52.210555, longitude: 11.61439 , accuracy: 4.0, speed: 1.69,time: Date(timeIntervalSince1970: 1696054710968), altitude: 0.0, verticalAccuracy: 0.0),
        GeoLocation(latitude: 52.210572, longitude: 11.614416, accuracy: 4.0, speed: 1.6 ,time: Date(timeIntervalSince1970: 1696054711968), altitude: 0.0, verticalAccuracy: 0.0),
        GeoLocation(latitude: 52.210587, longitude: 11.614435, accuracy: 4.0, speed: 1.69,time: Date(timeIntervalSince1970: 1696054712968), altitude: 0.0, verticalAccuracy: 0.0),
        GeoLocation(latitude: 52.210596, longitude: 11.614457, accuracy: 4.0, speed: 1.71,time: Date(timeIntervalSince1970: 1696054713968), altitude: 0.0, verticalAccuracy: 0.0),
        GeoLocation(latitude: 52.210599, longitude: 11.614483, accuracy: 4.0, speed: 1.97,time: Date(timeIntervalSince1970: 1696054714968), altitude: 0.0, verticalAccuracy: 0.0),
        GeoLocation(latitude: 52.210599, longitude: 11.614513, accuracy: 4.0, speed: 1.73,time: Date(timeIntervalSince1970: 1696054715968), altitude: 0.0, verticalAccuracy: 0.0),
        GeoLocation(latitude: 52.210599, longitude: 11.614542, accuracy: 4.0, speed: 1.97,time: Date(timeIntervalSince1970: 1696054716968), altitude: 0.0, verticalAccuracy: 0.0),
        GeoLocation(latitude: 52.210598, longitude: 11.614578, accuracy: 4.0, speed: 2.05,time: Date(timeIntervalSince1970: 1696054717968), altitude: 0.0, verticalAccuracy: 0.0),
    ]
    let tracks = [track01, track02, track03]
    let oocut = FinishedMeasurement(identifier: 1, tracks: tracks)

    try #require(oocut.trackLength == 23.086355857211004)
}

@Test("Distance Calculation for two GeoLocations works correctly")
func geoLocationDistance() throws {
    let firstLocation = GeoLocation(latitude: 0.0, longitude: 1.0, accuracy: 1.0, speed: 0.0, time: Date(), altitude: 0.0, verticalAccuracy: 1.0)
    let secondLocation = GeoLocation(latitude: 0.01, longitude: 1.0, accuracy: 1.0, speed: 0.0, time: Date(), altitude: 0.0, verticalAccuracy: 1.0)

    let distance = firstLocation.distance(from: secondLocation)
    try #require(distance == 1105.7427583005008)
}

@Test("Check that two equal FinishedMeasurement instances are truely equal!")
func equalFinishedMeasurement() throws {
    let firstMeasurement = FinishedMeasurement(identifier: 1)
    let secondMeasurement = FinishedMeasurement(identifier: 1, synchronizable: true)

    try #require(firstMeasurement == secondMeasurement)
}

@Test("Check that two unequal FinishedMeasurement instances are not equal!")
func nonEqualFinishedMeasurement() throws {
    let firstMeasurement = FinishedMeasurement(identifier: 1)
    let secondMeasurement = FinishedMeasurement(identifier: 2)

    try #require(firstMeasurement != secondMeasurement)
}
