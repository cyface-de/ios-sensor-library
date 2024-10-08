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
 This test case shows some example code on how to create new measurements and retreive existing ones from the database.
 Thereby it also tests the integrity of the Cyface SDK data model.

 - Author: Klemens Muthmann
 */
final class PersistenceTests: XCTestCase {

    var moc: NSManagedObjectContext?

    override func setUpWithError() throws {
        let bundle = Bundle.module
        guard let modelURL = bundle.url(forResource: "CyfaceModel", withExtension: "momd") else {
            return XCTFail()
        }
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            return XCTFail()
        }
        let persistentContainer = NSPersistentContainer(name: "CyfaceModel", managedObjectModel: mom)
        // This is appearantly the more recent version of loading a persistent store in memory.
        persistentContainer.persistentStoreDescriptions.first?.url  = URL(fileURLWithPath: "/dev/null")
        persistentContainer.loadPersistentStores { result, error in

        }

        // Store a measurement
        moc = persistentContainer.viewContext

    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCreateMeasurement() throws {
        guard let moc = moc else {
            return XCTFail("Unable to initialize NSManagedObjectContext!")
        }

        let measurement = MeasurementMO(context: moc)
        let startTime = Date()
        measurement.time = startTime
        measurement.addToTracks(track(context: moc, startTime: startTime))

        let startEvent = EventMO(context: moc)
        startEvent.time = measurement.time
        startEvent.typeEnum = EventType.lifecycleStart
        measurement.addToEvents(startEvent)

        let endEvent = EventMO(context: moc)
        endEvent.time = Date(timeInterval: 10, since: startTime)
        endEvent.typeEnum = EventType.lifecycleStop
        measurement.addToEvents(endEvent)

        XCTAssertNoThrow(try moc.save())

        // TODO: load the measurement and check properties
        // Load a measurement
        let fetchRequest = MeasurementMO.fetchRequest()
        let predicate = NSPredicate(format: "identifier == %@", NSNumber(value: measurement.identifier))
        fetchRequest.predicate = predicate

        let fetchResult = try moc.fetch(fetchRequest)
        XCTAssertEqual(fetchResult.count, 1)
        guard let loadedMeasurement = fetchResult.first else {
            return XCTFail("Unable to load stored measurement!")
        }

        XCTAssertEqual(loadedMeasurement.identifier, measurement.identifier)
        XCTAssertEqual(loadedMeasurement.time, measurement.time)
        XCTAssertNotNil(loadedMeasurement.tracks)
        XCTAssertEqual(loadedMeasurement.tracks?.count, 1)
        XCTAssertNotNil(loadedMeasurement.events)
        XCTAssertEqual(loadedMeasurement.events?.count, 2)
    }

    // TODO: Test Delete with cascading delete
    func testCascadingDelete() throws {
        guard let moc = moc else {
            return XCTFail("Unable to initialize NSManagedObjectContext")
        }

        let measurement = MeasurementMO(context: moc)
        let startTime = Date()
        measurement.time = startTime
        measurement.addToTracks(track(context: moc, startTime: startTime))

        XCTAssertNoThrow(try moc.save())

        var measurementsFromStorage = try moc.fetch(MeasurementMO.fetchRequest())
        var tracksFromStorage = try moc.fetch(TrackMO.fetchRequest())
        guard let measurementFromStorage = measurementsFromStorage.first else {
            return XCTFail("Unable to reload saved measurement!")
        }
        XCTAssertEqual(tracksFromStorage.count, 1)

        moc.delete(measurementFromStorage)

        measurementsFromStorage = try moc.fetch(MeasurementMO.fetchRequest())
        XCTAssertNil(measurementsFromStorage.first)
        tracksFromStorage = try moc.fetch(TrackMO.fetchRequest())
        XCTAssertNil(tracksFromStorage.first)
    }

    // TODO: Test loading only synchronizable measurement
    func testLoadOnlySynchronizable() throws {
        guard let moc = moc else {
            return XCTFail("Unable to load NSManagedObjectContext")
        }

        let measurement = MeasurementMO(context: moc)
        measurement.synchronizable = true
        let startTime = Date()
        measurement.time = startTime
        measurement.addToTracks(track(context: moc, startTime: startTime))

        let unsynchronizableMeasurement = MeasurementMO(context: moc)
        let unsynchronizableStartTime = Date()
        unsynchronizableMeasurement.synchronizable = false
        unsynchronizableMeasurement.time = unsynchronizableStartTime
        unsynchronizableMeasurement.addToTracks(track(context: moc, startTime: unsynchronizableStartTime))

        XCTAssertNoThrow(try moc.save())

        let fetchRequest = MeasurementMO.fetchRequest()
        let synchronizablePredicate = NSPredicate(format: "synchronizable == %@", NSNumber(value: true))
        fetchRequest.predicate = synchronizablePredicate

        let fetchResult = try moc.fetch(fetchRequest)
        XCTAssertEqual(fetchResult.count, 1)
        let fetchedMeasurement = try XCTUnwrap(fetchResult.first, "Unable to load synchronizable measurement!")
        XCTAssertEqual(fetchedMeasurement.identifier, measurement.identifier)
    }

    func testPerformanceSave() throws {
        // This is an example of a performance test case.
        measure {
            do {
                let moc = try XCTUnwrap(moc, "Unable to load NSManagedObjectContext!")

                let measurement = MeasurementMO(context: moc)
                measurement.synchronizable = true
                let startTime = Date()
                measurement.time = startTime
                measurement.addToTracks(track(context: moc, startTime: startTime))

                XCTAssertNoThrow(try moc.save())
            } catch {
                XCTFail()
            }
        }
    }

    func testPerformanceLoad() throws {
        let moc = try XCTUnwrap(moc, "Unable to load NSManagedObjectContext!")

        let measurement = MeasurementMO(context: moc)
        measurement.synchronizable = true
        let startTime = Date()
        measurement.time = startTime
        measurement.addToTracks(track(context: moc, startTime: startTime))

        XCTAssertNoThrow(try moc.save())
        measure {
            do {
                let fetchRequest = MeasurementMO.fetchRequest()
                let fetchResult = try moc.fetch(fetchRequest)
                let result = try XCTUnwrap(fetchResult.first)
                XCTAssertEqual(result.identifier, measurement.identifier)
            } catch {
                XCTFail()
            }
        }
    }

    func track(context: NSManagedObjectContext, startTime: Date) -> TrackMO {
        let track = TrackMO(context: context)

        track.addToAltitudes(altitude(
            context: context,
            value: 1.0,
            time: Date(timeInterval: 1, since: startTime)
        ))
        track.addToAltitudes(altitude(
            context: context,
            value: 2.0,
            time: Date(timeInterval: 2, since: startTime)
        ))
        track.addToAltitudes(altitude(
            context: context,
            value: 3.0,
            time: Date(timeInterval: 3, since: startTime)
        ))
        track.addToAltitudes(altitude(
            context: context,
            value: 4.0,
            time: Date(timeInterval: 4, since: startTime)
        ))
        track.addToAltitudes(altitude(
            context: context,
            value: 5.0,
            time: Date(timeInterval: 5, since: startTime)
        ))
        track.addToAltitudes(altitude(
            context: context,
            value: 6.0,
            time: Date(timeInterval: 6, since: startTime)
        ))
        track.addToAltitudes(altitude(
            context: context,
            value: 7.0,
            time: Date(timeInterval: 7, since: startTime)
        ))
        track.addToAltitudes(altitude(
            context: context,
            value: 8.0,
            time: Date(timeInterval: 8, since: startTime)
        ))
        track.addToAltitudes(altitude(
            context: context,
            value: 9.0,
            time: Date(timeInterval: 9, since: startTime)
        ))
        track.addToAltitudes(altitude(
            context: context,
            value: 10.0,
            time: Date(timeInterval: 10, since: startTime)
        ))

        track.addToLocations(geoLocation(
            context: context,
            latitude: 1.0,
            longitude: 1.0,
            accuracy: 1.0,
            altitude: 1.0,
            speed: 1.0,
            time: Date(timeInterval: 1, since: startTime),
            verticalAccuracy: 1.0
        ))
        track.addToLocations(geoLocation(
            context: context,
            latitude: 2.0,
            longitude: 2.0,
            accuracy: 2.0,
            altitude: 2.0,
            speed: 2.0,
            time: Date(timeIntervalSinceNow: 2),
            verticalAccuracy: 2.0
        ))
        track.addToLocations(geoLocation(
            context: context,
            latitude: 3.0,
            longitude: 3.0,
            accuracy: 3.0,
            altitude: 3.0,
            speed: 3.0,
            time: Date(timeIntervalSinceNow: 3),
            verticalAccuracy: 3.0
        ))
        track.addToLocations(geoLocation(
            context: context,
            latitude: 4.0,
            longitude: 4.0,
            accuracy: 4.0,
            altitude: 4.0,
            speed: 4.0,
            time: Date(timeIntervalSinceNow: 4),
            verticalAccuracy: 4.0
        ))
        track.addToLocations(geoLocation(
            context: context,
            latitude: 5.0,
            longitude: 5.0,
            accuracy: 5.0,
            altitude: 5.0,
            speed: 5.0,
            time: Date(timeIntervalSinceNow: 5),
            verticalAccuracy: 5.0
        ))
        track.addToLocations(geoLocation(
            context: context,
            latitude: 6.0,
            longitude: 6.0,
            accuracy: 6.0,
            altitude: 6.0,
            speed: 6.0,
            time: Date(timeIntervalSinceNow: 6),
            verticalAccuracy: 6.0
        ))
        track.addToLocations(geoLocation(
            context: context,
            latitude: 7.0,
            longitude: 7.0,
            accuracy: 7.0,
            altitude: 7.0,
            speed: 7.0,
            time: Date(timeIntervalSinceNow: 7),
            verticalAccuracy: 7.0
        ))
        track.addToLocations(geoLocation(
            context: context,
            latitude: 8.0,
            longitude: 8.0,
            accuracy: 8.0,
            altitude: 8.0,
            speed: 8.0,
            time: Date(timeIntervalSinceNow: 8),
            verticalAccuracy: 8.0
        ))
        track.addToLocations(geoLocation(
            context: context,
            latitude: 9.0,
            longitude: 9.0,
            accuracy: 9.0,
            altitude: 9.0,
            speed: 9.0,
            time: Date(timeIntervalSinceNow: 9),
            verticalAccuracy: 9.0
        ))
        track.addToLocations(geoLocation(
            context: context,
            latitude: 10.0,
            longitude: 10.0,
            accuracy: 10.0,
            altitude: 10.0,
            speed: 10.0,
            time: Date(timeIntervalSinceNow: 10),
            verticalAccuracy: 10.0
        ))
        track.addToLocations(geoLocation(
            context: context,
            latitude: 11.0,
            longitude: 11.0,
            accuracy: 11.0,
            altitude: 11.0,
            speed: 11.0,
            time: Date(timeIntervalSinceNow: 11),
            verticalAccuracy: 11.0
        ))

        return track
    }

    func altitude(context: NSManagedObjectContext, value: Double, time: Date) -> AltitudeMO {
        let altitude = AltitudeMO(context: context)

        altitude.altitude = value
        altitude.time = time

        return altitude
    }

    func geoLocation(
        context: NSManagedObjectContext,
        latitude: Double,
        longitude: Double,
        accuracy: Double,
        altitude: Double,
        speed: Double,
        time: Date,
        verticalAccuracy: Double
    ) -> GeoLocationMO {
        let geoLocation = GeoLocationMO(context: context)

        geoLocation.lat = latitude
        geoLocation.lon = longitude
        geoLocation.accuracy = accuracy
        geoLocation.altitude = altitude
        geoLocation.speed = speed
        geoLocation.time = time
        geoLocation.verticalAccuracy = verticalAccuracy

        return geoLocation
    }

}
