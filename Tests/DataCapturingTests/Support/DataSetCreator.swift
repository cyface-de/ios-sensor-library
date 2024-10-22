/*
 * Copyright 2019-2024 Cyface GmbH
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
@testable import DataCapturing

/**
 This class contains utility code used to create data stores in specific versions of the Cyface model.

 - Author: Klemens Muthmann
 - Version: 2.0.1
 - Since: 4.0.0
 */
class DataSetCreator {
    /**
     Create a version 1 data set with two measurements 1 and 2 and 1.000 and 2.000 geo locations at timestamps 10.000 and 20.000.

     - Parameter in: The container to create the data in
     */
    static func createV1Data(in container: NSPersistentContainer) throws {
        let context = container.newBackgroundContext()
        _ = createV1Measurement(withIdentifier: 1, atTime: 10_000, containingCountOfGeoLocations: 1_000, inContext: context)
        _ = createV1Measurement(withIdentifier: 2, atTime: 20_000, containingCountOfGeoLocations: 2_000, inContext: context)
        try context.save()
    }

    /**
     Creates a version two measurement in the provided version 1 `NSManagedObjectContext`.

     - Parameters:
     - withIdentifier: The identifier of the new measurement
     - atTime: The timestamp in milliseconds since the first of january 1970 the measurement was created on
     - containingCountOfGeoLocations: The amount of geo locations to create for the new measurement
     - inContext: The *CoreData* `NSManagedObjectContext` to create the data in
     - Returns: The newly created measurement as an `NSManagedObject`
     */
    static func createV1Measurement(withIdentifier identifier: Int, atTime time: Int64, containingCountOfGeoLocations countOfGeoLocations: Int, inContext context: NSManagedObjectContext) -> NSManagedObject {
        let measurement = NSEntityDescription.insertNewObject(forEntityName: "Measurement", into: context)
        measurement.setPrimitiveValue(identifier, forKey: "identifier")
        measurement.setPrimitiveValue(false, forKey: "synchronized")
        measurement.setPrimitiveValue(time, forKey: "timestamp")

        var accelerations01 = [NSManagedObject]()
        var geoLocations01 = [NSManagedObject]()
        for i in 0..<countOfGeoLocations*10 {
            if i % 10 == 0 {
                let geoLocation = NSEntityDescription.insertNewObject(forEntityName: "GeoLocation", into: context)
                geoLocation.setPrimitiveValue(1.0, forKey: "accuracy")
                geoLocation.setPrimitiveValue(time + Int64(i * 100), forKey: "timestamp") // add 1000 milliseconds to timestamp
                geoLocation.setPrimitiveValue(51.0+Double(i)/1_000, forKey: "lat")
                geoLocation.setPrimitiveValue(13.0+Double(i)/1_000, forKey: "lon")
                geoLocation.setPrimitiveValue(1.0, forKey: "speed")
                geoLocations01.append(geoLocation)
            }

            let acceleration = NSEntityDescription.insertNewObject(forEntityName: "Acceleration", into: context)
            acceleration.setPrimitiveValue(time + Int64(i * 100), forKey: "timestamp")
            acceleration.setPrimitiveValue(1.0, forKey: "ax")
            acceleration.setPrimitiveValue(1.0, forKey: "ay")
            acceleration.setPrimitiveValue(1.0, forKey: "az")
            accelerations01.append(acceleration)
        }

        measurement.setValue(NSOrderedSet(array: geoLocations01), forKey: "geoLocations")
        measurement.setValue(NSOrderedSet(array: accelerations01), forKey: "accelerations")

        return measurement
    }

    /**
     Create a version 2 data set with two measurements 1 and 2 and 1.000 and 2.000 geo locations at timestamps 10.000 and 20.000.

     - Parameter in: The container to create the data in
     */
    static func createV2Data(in container: NSPersistentContainer) throws {
        let context = container.newBackgroundContext()
        createV2Measurement(withIdentifier: 1, atTime: 10_000, containingCountOfGeoLocations: 1_000, inContext: context)
        createV2Measurement(withIdentifier: 2, atTime: 20_000, containingCountOfGeoLocations: 2_000, inContext: context)
        try context.save()
    }

    /**
     Creates a version two measurement in the provided version 2 `NSManagedObjectContext`.

     - Parameters:
     - withIdentifier: The identifier of the new measurement
     - atTime: The timestamp in milliseconds since the first of january 1970 the measurement was created on
     - containingCountOfGeoLocations: The amount of geo locations to create for the new measurement
     - inContext: The *CoreData* `NSManagedObjectContext` to create the data in
     */
    static func createV2Measurement(withIdentifier identifier: Int, atTime time: Int64, containingCountOfGeoLocations countOfGeoLocations: Int, inContext context: NSManagedObjectContext) {
        let measurement = createV1Measurement(withIdentifier: identifier, atTime: time, containingCountOfGeoLocations: countOfGeoLocations, inContext: context)
        measurement.setValue("BICYCLE", forKey: "context")
    }

    /**
     Create a version 3 data set with two measurements 1 and 2 and 200 and 300 geo locations at timestamps 10.000 and 20.000.

     - Parameter in: The container to create the data in
     */
    static func createV3Data(in container: NSPersistentContainer) throws {
        let context = container.newBackgroundContext()
        let measurement01 = NSEntityDescription.insertNewObject(forEntityName: "Measurement", into: context)
        measurement01.setPrimitiveValue(200*100, forKey: "accelerationsCount")
        measurement01.setPrimitiveValue("BICYCLE", forKey: "context")
        measurement01.setPrimitiveValue(Int64(1), forKey: "identifier")
        measurement01.setPrimitiveValue(false, forKey: "synchronized")
        measurement01.setPrimitiveValue(Int64(10_000), forKey: "timestamp")

        var geoLocations = [NSManagedObject]()
        for i in 0...199 {
            let geoLocation = NSEntityDescription.insertNewObject(forEntityName: "GeoLocation", into: context)
            geoLocation.setPrimitiveValue(1.0, forKey: "accuracy")
            geoLocation.setPrimitiveValue(51.0+0.01*Double(i), forKey: "lat")
            geoLocation.setPrimitiveValue(13.7+0.01*Double(i), forKey: "lon")
            geoLocation.setPrimitiveValue(1.0, forKey: "speed")
            geoLocation.setPrimitiveValue(10_000 + i, forKey: "timestamp")
            geoLocations.append(geoLocation)
        }

        measurement01.setValue(NSOrderedSet(array: geoLocations), forKey: "geoLocations")

        let measurement02 = NSEntityDescription.insertNewObject(forEntityName: "Measurement", into: context)
        measurement02.setPrimitiveValue(300*100, forKey: "accelerationsCount")
        measurement02.setPrimitiveValue("BICYCLE", forKey: "context")
        measurement02.setPrimitiveValue(Int64(2), forKey: "identifier")
        measurement02.setPrimitiveValue(false, forKey: "synchronized")
        measurement02.setPrimitiveValue(Int64(20_000), forKey: "timestamp")

        var geoLocations02 = [NSManagedObject]()
        for i in 0...299 {
            let geoLocation = NSEntityDescription.insertNewObject(forEntityName: "GeoLocation", into: context)
            geoLocation.setPrimitiveValue(1.0, forKey: "accuracy")
            geoLocation.setPrimitiveValue(52.0+0.01*Double(i), forKey: "lat")
            geoLocation.setPrimitiveValue(13.7+0.01*Double(i), forKey: "lon")
            geoLocation.setPrimitiveValue(1.0, forKey: "speed")
            geoLocation.setPrimitiveValue(20_000+i, forKey: "timestamp")
            geoLocations02.append(geoLocation)
        }
        measurement02.setValue(NSOrderedSet(array: geoLocations02), forKey: "geoLocations")

        try context.save()
    }

    /**
     Creates data in the version 4 format of the Cyface database schema. This version added individual tracks to measurements

     - Parameter in: The container to create the data in
     */
    static func createV4Data(in container: NSPersistentContainer) throws {
        let context = container.newBackgroundContext()

        let measurement01 = createV4Measurement(450*100, "BICYCLE", Int64(1), false, Date(timeIntervalSince1970: 10_000), 450.0, context)
        let trackOne = NSEntityDescription.insertNewObject(forEntityName: "Track", into: context)
        let trackOneGeoLocations = createV4GeoLocations(200, Date(timeIntervalSince1970: 10_000), trackOne, context, createV4GeoLocation)
        trackOne.setValue(NSOrderedSet(array: trackOneGeoLocations), forKey: "locations")
        trackOne.setValue(measurement01, forKey: "measurement")
        let trackTwo = NSEntityDescription.insertNewObject(forEntityName: "Track", into: context)
        let trackTwoGeoLocations = createV4GeoLocations(250, Date(timeIntervalSince1970: 10_300), trackTwo, context, createV4GeoLocation)
        trackTwo.setValue(NSOrderedSet(array: trackTwoGeoLocations), forKey: "locations")
        trackTwo.setValue(measurement01, forKey: "measurement")

        let measurement02 = createV4Measurement(300*100, "BICYCLE", Int64(2), false, Date(timeIntervalSince1970: 20_000), 300, context)
        let trackForMeasurementTwo = NSEntityDescription.insertNewObject(forEntityName: "Track", into: context)
        let trackForMeasurementTwoGeoLocations = createV4GeoLocations(300, Date(timeIntervalSince1970: 20_000), trackForMeasurementTwo, context, createV4GeoLocation)
        trackForMeasurementTwo.setValue(NSOrderedSet(array: trackForMeasurementTwoGeoLocations), forKey: "locations")
        trackForMeasurementTwo.setValue(measurement02, forKey: "measurement")

        try context.save()
    }

    /**
     Creates a new measurement instance as an `NSManagedObject` in a Cyface version 4 database.

     - Parameters:
     - accelerationsCount: The number of accelerations stored with this measurement. Since accelerations are not stored in the database in version 4 anymore, these objects are not actually created.
     - vehicleContext: The vehicle used to capture the measurement. Usually one of "BICYCLE", "CAR" or "MOTORBIKE", but might be any `String` for simulation purposes.
     - identifier: The measurement identifier as a device wide unique identifier, used to distinguish this measurement from others.
     - synchronized: Whether this measurement is already synchronized to a server or not.
     - timestamp: The time the measurement was started in milliseconds since the 1st of january 1970.
     - trackLength: The length of the track in meters
     - context: An `NSManagedObjectContext` used to create the new `NSManagedObject` instance. This must be a version 4 `NSManagedObjectContext`.
     - Returns: A new version 4 measurement.
     */
    static func createV4Measurement(_ accelerationsCount: Int64, _ vehicleContext: String, _ identifier: Int64, _ synchronized: Bool, _ time: Date, _ trackLength: Double, _ context: NSManagedObjectContext) -> NSManagedObject {
        let ret = NSEntityDescription.insertNewObject(forEntityName: "Measurement", into: context)
        ret.setPrimitiveValue(accelerationsCount, forKey: "accelerationsCount")
        ret.setPrimitiveValue(vehicleContext, forKey: "context")
        ret.setPrimitiveValue(identifier, forKey: "identifier")
        ret.setPrimitiveValue(synchronized, forKey: "synchronized")
        ret.setPrimitiveValue(time, forKey: "timestamp")
        ret.setPrimitiveValue(trackLength, forKey: "trackLength")
        return ret
    }

    /**
     Creates an array filled with geo location `NSManagedObject` instances usable by *CoreData* in a Version 4 Cyface database.

     - Parameters:
     - count: The amount of instances to create.
     - startTimestamp: The timestamp used for the first instance in milliseconds since the 1st of january 1970. This is increased by 1 second per location.
     - track: The track entity these new locations are going to belong to. This `NSManagedObject` must be from the same `NSManagedObjectContext` as the one provided to this method.
     - context: The `NSManagedObjectContext` to use for instance creation. This must be a valid version 4 `NSManagedObjectContext`.
     - locationCreator: A function to create one geo location.
     - Returns: An array containing `count` geo locations.
     */
    static func createV4GeoLocations(_ count: UInt64, _ startTime: Date, _ track: NSManagedObject, _ context: NSManagedObjectContext, _ locationCreator: (UInt64, Date, NSManagedObject, NSManagedObjectContext) -> NSManagedObject ) -> [NSManagedObject] {
        var ret = [NSManagedObject]()
        for i in 0..<count {
            let geoLocation = locationCreator(i, startTime, track, context)
            ret.append(geoLocation)
        }
        return ret
    }

    /**
     A function to create a single `GeoLocation` in the version 4 data format.

     - Parameters:
     - position: The position of the `GeoLocation` within the current `Track`.
     - startTimestamp: The timestamp of the first `GeoLocation` in the current `Track` in milliseconds since the 1st of January 1970.
     - track: The `Track` to add the `GeoLocation` to.
     - context: The managed object context to save the newly created `GeoLocation` in.
     */
    static func createV4GeoLocation(position: UInt64, startTime: Date, track: NSManagedObject, context: NSManagedObjectContext) -> NSManagedObject {
        let geoLocation = NSEntityDescription.insertNewObject(forEntityName: "GeoLocation", into: context)
        geoLocation.setPrimitiveValue(1.0, forKey: "accuracy")
        geoLocation.setPrimitiveValue(52.0+0.01*Double(position), forKey: "lat")
        geoLocation.setPrimitiveValue(13.7+0.01*Double(position), forKey: "lon")
        geoLocation.setPrimitiveValue(1.0, forKey: "speed")
        geoLocation.setPrimitiveValue(startTime.addingTimeInterval(Double(position)), forKey: "timestamp")
        geoLocation.setValue(track, forKey: "track")
        return geoLocation
    }
}

/**
 The base protocol for all data set creators, starting from version 5.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 4.6.0
 */
protocol DataSetCreatorProtocol {

    /**
     Creates data within the provided `NSPersistentContainer`. This container must support the correct model version.

     - Parameter in: The container to save the create data to.
     */
    func createData(in container: NSPersistentContainer) throws
}

/**
 A data set creator creating a data set within an `NSPersistentContainer` of a version 5 database.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 4.6.0
 */
class DataSetCreatorV5: DataSetCreatorProtocol {

    func createData(in container: NSPersistentContainer) throws {
        let context = container.newBackgroundContext()
        let measurement01 = createMeasurement(
            accelerationsCount: 10_000,
            vehicleContext: "BICYCLE",
            identifier: 1,
            synchronized: false,
            time: Date(),
            trackLength: 500,
            context: context
        )
        let track0101 = appendTrack(to: measurement01, context: context)
        createGeoLocations(count: 30, track: track0101, context: context, locationCreator: DataSetCreator.createV4GeoLocation)
        let track0102 = appendTrack(to: measurement01, context: context)
        createGeoLocations(count: 20, track: track0102, context: context, locationCreator: DataSetCreator.createV4GeoLocation)

        let measurement02 = createMeasurement(
            accelerationsCount: 20_000,
            vehicleContext: "BICYCLE",
            identifier: 2,
            synchronized: false,
            time: Date(),
            trackLength: 700,
            context: context
        )
        let track0201 = appendTrack(to: measurement02, context: context)
        createGeoLocations(count: 40, track: track0201, context: context, locationCreator: DataSetCreator.createV4GeoLocation)

        try context.save()
    }

    /**
     Create a measurement in the version 5 data format.

     - Parameters:
     - accelerationsCount: The number of accelerations to "simulate" with the created measurement. These accelerations are not truly created, but the corresponding field is set to the provided value.
     - vehicleContext: The vehicle the measurement was supposed to be done with.
     - identifier: The identifier for the new measurement.
     - synchronized: Whether the measurement is synchronized or not.
     - timestamp: The time in milliseconds since the 1st of January 1970, when this measurement should have happended.
     - trackLength: The summed up length of all tracks in the measurement in meters.
     - context: A CoreData `NSManagedObjectContext` used to create and store the new measurement.
     - Returns: An `NSManagedObject` representing the created measurement.
     */
    func createMeasurement(accelerationsCount: Int64, vehicleContext: String, identifier: Int64, synchronized: Bool, time: Date, trackLength: Double, context: NSManagedObjectContext) -> NSManagedObject {
        let measurement = DataSetCreator.createV4Measurement(accelerationsCount, vehicleContext, identifier, synchronized, time, trackLength, context)
        measurement.setPrimitiveValue(false, forKey: "synchronizable")
        return measurement
    }

    /**
     Adds a track to the end of the list of tracks of an already created measurement.

     - Parameters:
     - to: The measurement to append the track to.
     - context: The `NSManagedObjectContext` used to create and store the new track.
     - Returns: The newly created track as an `NSManagedObject`.
     */
    func appendTrack(to measurement: NSManagedObject, context: NSManagedObjectContext) -> NSManagedObject {
        let track = NSEntityDescription.insertNewObject(forEntityName: "Track", into: context)
        track.setValue(measurement, forKey: "measurement")
        return track
    }

    /**
     Create a number of geo locations with random values and add them to the end of a track.

     - Parameters:
     - count: The number of geo locations to add
     - track: The track to add the geo locations to
     - context: An `NSManagedObjectContext` used to create and store the newly created geo locations. This context must also contain the provided track.
     - locationCreator: A function creating individual geo locations.
     */
    func createGeoLocations(count: Int64, track: NSManagedObject, context: NSManagedObjectContext, locationCreator: (UInt64, Date, NSManagedObject, NSManagedObjectContext) -> NSManagedObject) {
        let locations = DataSetCreator.createV4GeoLocations(40, Date(), track, context, locationCreator)
        track.setValue(NSOrderedSet(array: locations), forKey: "locations")
    }
}

/**
 A data set creator creating a data set within an `NSPersistentContainer` of a version 6 database.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 - Since: 4.6.0
 */
class DataSetCreatorV6: DataSetCreatorProtocol {

    /// A reference to version 5 data set creator used to create all the data that did not change.
    private let dataSetCreatorV5 = DataSetCreatorV5()

    func createData(in container: NSPersistentContainer) throws {
        let context = container.newBackgroundContext()
        let measurement01 = dataSetCreatorV5.createMeasurement(accelerationsCount: 10_000, vehicleContext: "BICYCLE", identifier: 1, synchronized: false, time: Date(), trackLength: 700, context: context)
        let track0101 = dataSetCreatorV5.appendTrack(to: measurement01, context: context)
        dataSetCreatorV5.createGeoLocations(count: 20, track: track0101, context: context, locationCreator: createGeoLocation)

        let measurement02 = dataSetCreatorV5.createMeasurement(accelerationsCount: 20_000, vehicleContext: "BICYCLE", identifier: 2, synchronized: false, time: Date(), trackLength: 200, context: context)
        let track0201 = dataSetCreatorV5.appendTrack(to: measurement02, context: context)
        dataSetCreatorV5.createGeoLocations(count: 5, track: track0201, context: context, locationCreator: createGeoLocation)
        let track0202 = dataSetCreatorV5.appendTrack(to: measurement02, context: context)
        dataSetCreatorV5.createGeoLocations(count: 10, track: track0202, context: context, locationCreator: createGeoLocation)

        try context.save()
    }

    /**
     Create a single version 6 geo location.

     - Parameters:
     - position: The position of the new geo location within its track.
     - startTimestamp: The start timestamp of the track.
     - track: The track to add the new geo location to.
     - context: An `NSManagedObjectContext` used to create and store the new geo location. This must be the same context, that created the track object.
     - Returns: A new geo location as `NSManagedObject`.
     */
    func createGeoLocation(position: UInt64, startTime: Date, track: NSManagedObject, context: NSManagedObjectContext) -> NSManagedObject {
        let geoLocation = DataSetCreator.createV4GeoLocation(position: position, startTime: startTime, track: track, context: context)
        geoLocation.setPrimitiveValue(true, forKey: "isPartOfCleanedTrack")
        return geoLocation
    }
}

/**
Creates a small data set for the Version 9 database format.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
class DataSetCreatorV9: DataSetCreatorProtocol {

    func createData(in container: NSPersistentContainer) throws {
        let context = container.newBackgroundContext()
        let measurement01 = measurement(context: context, identifier: 0, timestamp: 1708338253000, synchronizable: true, synchronized: false, accelerationsCount: 10, directionsCount: 15, rotationsCount: 20, trackLength: 253)

        // 2 Tracks mit entsprechenden Events und Locations
        var tracks01 = [NSManagedObject]()

        let track0101 = track(context: context, measurement: measurement01)
        let locations0101 = [
            geoLocation(context: context, accuracy: 19.49, isPartOfCleanedTrack: false, lat: 51.399973, lon: 12.196312, speed: 0.0, timestamp: 1694523963999, track: track0101),
            geoLocation(context: context, accuracy: 23.87, isPartOfCleanedTrack: true, lat: 51.399973, lon: 12.196312, speed: 0.0, timestamp: 1694523964999, track: track0101),
            geoLocation(context: context, accuracy: 15.55, isPartOfCleanedTrack: false, lat: 51.399973, lon: 12.196312, speed: 0.0, timestamp: 1694523965999, track: track0101),
            geoLocation(context: context, accuracy: 13.89, isPartOfCleanedTrack: true, lat: 51.399973, lon: 12.196312, speed: 0.0, timestamp: 1694523966999, track: track0101),
            geoLocation(context: context, accuracy: 14.89, isPartOfCleanedTrack: false, lat: 51.399973, lon: 12.196312, speed: 0.0, timestamp: 1694523967999, track: track0101),
            geoLocation(context: context, accuracy: 18.18, isPartOfCleanedTrack: true, lat: 51.399973, lon: 12.196312, speed: 0.0, timestamp: 1694523968999, track: track0101),
            geoLocation(context: context, accuracy: 15.64, isPartOfCleanedTrack: false, lat: 51.399946, lon: 12.196136, speed: 0.01, timestamp: 1694523969999, track: track0101),
            geoLocation(context: context, accuracy: 9.4, isPartOfCleanedTrack: true, lat: 51.399942, lon: 12.196116, speed: 0.0, timestamp: 1694523970999, track: track0101)
        ]
        track0101.setValue(NSOrderedSet(array: locations0101), forKey: "locations")
        tracks01.append(track0101)

        let track0102 = track(context: context, measurement: measurement01)
        let locations0102 = [
            geoLocation(context: context, accuracy: 14.87, isPartOfCleanedTrack: false, lat: 51.399995, lon: 12.196409, speed: 1.93, timestamp: 1694523956223, track: track0101),
            geoLocation(context: context, accuracy: 13.41, isPartOfCleanedTrack: true, lat: 51.39998, lon: 12.196359, speed: 0.05, timestamp: 1694523957173, track: track0101),
            geoLocation(context: context, accuracy: 12.81, isPartOfCleanedTrack: true, lat: 51.399977, lon: 12.196343, speed: 0.03, timestamp: 1694523958123, track: track0101),
            geoLocation(context: context, accuracy: 12.15, isPartOfCleanedTrack: false, lat: 51.399974, lon: 12.19633, speed: 0.02, timestamp: 1694523959073, track: track0101),
            geoLocation(context: context, accuracy: 11.73, isPartOfCleanedTrack: true, lat: 51.399974, lon: 12.19633, speed: 0.0, timestamp: 1694523960023, track: track0101),
            geoLocation(context: context, accuracy: 11.41, isPartOfCleanedTrack: false, lat: 51.399973, lon: 12.196312, speed: 0.03, timestamp: 1694523960999, track: track0101),
            geoLocation(context: context, accuracy: 12.41, isPartOfCleanedTrack: true, lat: 51.399973, lon: 12.196312, speed: 0.0, timestamp: 1694523961999, track: track0101),
            geoLocation(context: context, accuracy: 10.85, isPartOfCleanedTrack: false, lat: 51.399973, lon: 12.196312, speed: 0.0, timestamp: 1694523962999, track: track0101)
        ]
        track0102.setValue(NSOrderedSet(array: locations0102), forKey: "locations")
        tracks01.append(track0102)

        let events01 = [
            event(context: context, time: Date(timeIntervalSince1970: 1708338253000), type: EventType.modalityTypeChange, value: "BICYCLE", measurement: measurement01),
            event(context: context, time: Date(timeIntervalSince1970: 1708338253000), type: EventType.lifecycleStart, value: nil, measurement: measurement01),
            event(context: context, time: Date(timeIntervalSince1970: 1708338254), type: EventType.lifecyclePause, value: nil, measurement: measurement01),
            event(context: context, time: Date(timeIntervalSince1970: 1708338255), type: EventType.lifecycleResume, value: nil, measurement: measurement01)
        ]

        measurement01.setValue(NSOrderedSet(array: tracks01), forKey: "tracks")
        measurement01.setValue(NSOrderedSet(array: events01), forKey: "events")

        let measurement02 = measurement(context: context, identifier: 1, timestamp: 1708345816000, synchronizable: false, synchronized: true, accelerationsCount: 20, directionsCount: 25, rotationsCount: 30, trackLength: 1234)
        // 1 Track mit Events und locations
        var tracks02 = [NSManagedObject]()
        let track0201 = track(context: context, measurement: measurement02)
        let locations0201 = [
            geoLocation(context: context, accuracy: 35.0, isPartOfCleanedTrack: true, lat: 51.399841, lon: 12.196419, speed: -1.0, timestamp: 1694523938373, track: track0201),
            geoLocation(context: context, accuracy: 27.43, isPartOfCleanedTrack: false, lat: 51.39987, lon: 12.196359, speed: 0.74, timestamp: 1694523942818, track: track0201),
            geoLocation(context: context, accuracy: 24.03, isPartOfCleanedTrack: true, lat: 51.399937, lon: 12.196328, speed: 0.74, timestamp: 1694523943818, track: track0201),
            geoLocation(context: context, accuracy: 22.15, isPartOfCleanedTrack: false, lat: 51.399967, lon: 12.19631, speed: 0.64, timestamp: 1694523944768, track: track0201),
            geoLocation(context: context, accuracy: 20.7, isPartOfCleanedTrack: true, lat: 51.399967, lon: 12.19631, speed: 0.0, timestamp: 1694523945718, track: track0201),
            geoLocation(context: context, accuracy: 19.27, isPartOfCleanedTrack: false, lat: 51.399967, lon: 12.19631, speed: 0.0, timestamp: 1694523946668, track: track0201),
            geoLocation(context: context, accuracy: 18.14, isPartOfCleanedTrack: true, lat: 51.399998, lon: 12.196308, speed: 0.39, timestamp: 1694523947618, track: track0201),
            geoLocation(context: context, accuracy: 17.57, isPartOfCleanedTrack: false, lat: 51.40001, lon: 12.196315, speed: 1.54, timestamp: 1694523948622, track: track0201),
            geoLocation(context: context, accuracy: 17.25, isPartOfCleanedTrack: true, lat: 51.400021, lon: 12.196319, speed: 1.19, timestamp: 1694523949572, track: track0201),
            geoLocation(context: context, accuracy: 17.09, isPartOfCleanedTrack: false, lat: 51.400014, lon: 12.196343, speed: 1.54, timestamp: 1694523950522, track: track0201),
            geoLocation(context: context, accuracy: 17.06, isPartOfCleanedTrack: true, lat: 51.40001, lon: 12.196366, speed: 1.58, timestamp: 1694523951472, track: track0201),
            geoLocation(context: context, accuracy: 16.39, isPartOfCleanedTrack: false, lat: 51.400004, lon: 12.196401, speed: 3.41, timestamp: 1694523952422, track: track0201),
            geoLocation(context: context, accuracy: 15.56, isPartOfCleanedTrack: true, lat: 51.399994, lon: 12.196374, speed: 3.41, timestamp: 1694523953372, track: track0201),
            geoLocation(context: context, accuracy: 15.15, isPartOfCleanedTrack: false, lat: 51.400001, lon: 12.196425, speed: 3.41, timestamp: 1694523954322, track: track0201),
        ]
        track0201.setValue(NSOrderedSet(array: locations0201), forKey: "locations")
        tracks02.append(track0201)

        let events02 = [
            event(context: context, time: Date(timeIntervalSince1970: 1708345816), type: EventType.modalityTypeChange, value: "BICYCLE", measurement: measurement02),
            event(context: context, time: Date(timeIntervalSince1970: 1708345816), type: EventType.lifecycleStart, value: nil, measurement: measurement02),
            event(context: context, time: Date(timeIntervalSince1970: 1708345817), type: EventType.lifecycleStop, value: nil, measurement: measurement02)
        ]

        measurement02.setValue(NSOrderedSet(array: tracks02), forKey: "tracks")
        measurement02.setValue(NSOrderedSet(array: events02), forKey: "events")

        try context.save()
    }

    ///  Create a V9 GeoLocation.
    func geoLocation(context: NSManagedObjectContext, accuracy: Double, isPartOfCleanedTrack: Bool, lat: Double, lon: Double, speed: Double, timestamp: Int64, track: NSManagedObject) -> NSManagedObject{
        let location = NSEntityDescription.insertNewObject(forEntityName: "GeoLocation", into: context)
        location.setPrimitiveValue(accuracy, forKey: "accuracy")
        location.setPrimitiveValue(isPartOfCleanedTrack, forKey: "isPartOfCleanedTrack")
        location.setPrimitiveValue(lat, forKey: "lat")
        location.setPrimitiveValue(lon, forKey: "lon")
        location.setPrimitiveValue(speed, forKey: "speed")
        location.setPrimitiveValue(timestamp, forKey: "timestamp")
        location.setValue(track, forKey: "track")

        return location
    }

    /// Create a V9 track.
    func track(context: NSManagedObjectContext, measurement: NSManagedObject) -> NSManagedObject {
        let track = NSEntityDescription.insertNewObject(forEntityName: "Track", into: context)
        track.setValue(measurement, forKey: "measurement")

        return track
    }

    /// Create a V9 measurement.
    func measurement(
        context: NSManagedObjectContext,
        identifier: Int64,
        timestamp: Int64,
        synchronizable: Bool,
        synchronized: Bool,
        accelerationsCount: Int64,
        directionsCount: Int64,
        rotationsCount: Int64,
        trackLength: Int
    ) -> NSManagedObject {
        let measurement = NSEntityDescription.insertNewObject(forEntityName: "Measurement", into: context)
        measurement.setPrimitiveValue(accelerationsCount, forKey: "accelerationsCount")
        measurement.setPrimitiveValue(directionsCount, forKey: "directionsCount")
        measurement.setPrimitiveValue(rotationsCount, forKey: "rotationsCount")
        measurement.setPrimitiveValue(identifier, forKey: "identifier")
        // Nicht synchronisiert
        measurement.setPrimitiveValue(NSNumber(value: synchronizable), forKey: "synchronizable")
        measurement.setPrimitiveValue(NSNumber(value: synchronized), forKey: "synchronized")
        measurement.setPrimitiveValue(timestamp, forKey: "timestamp")
        measurement.setPrimitiveValue(trackLength, forKey: "trackLength")

        return measurement
    }

    /// Create a V9 event
    func event(
        context: NSManagedObjectContext,
        time: Date,
        type: EventType,
        value: String?,
        measurement: NSManagedObject
    ) -> NSManagedObject {
        let event = NSEntityDescription.insertNewObject(forEntityName: "Event", into: context)
        event.setPrimitiveValue(time, forKey: "time")
        event.setPrimitiveValue(type.rawValue, forKey: "type")
        event.setPrimitiveValue(value, forKey: "value")
        event.setValue(measurement, forKey: "measurement")

        return event
    }
}

