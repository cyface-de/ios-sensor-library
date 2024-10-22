//
//  DataSetCreatorV11.swift
//  DataCapturing
//
//  Created by Klemens Muthmann on 17.10.24.
//
import CoreData
import DataCapturing

/**
 Create a small data set in the V11 Cyface data format.

 - Author: Klemens Muthmann
 - Version: 1.0.0
 */
class DataSetCreatorV11: DataSetCreatorProtocol {
    func createData(in container: NSPersistentContainer) throws {
        let context = container.newBackgroundContext()
        let measurement01 = measurement(context: context, identifier: 1, time: Date(timeIntervalSince1970: 724950914.080129), synchronizable: false, synchronized: true, trackLength: 589)
        let measurement02 = measurement(context: context, identifier: 2, time: Date(timeIntervalSince1970: 725888583.465175), synchronizable: false, synchronized: true, trackLength: 2389)
        let track01 = track(context: context, measurement: measurement01)
        let track02 = track(context: context, measurement: measurement02)
        let track03 = track(context: context, measurement: measurement02)

        let altitudes01 = [
            altitude(context: context, value: 0.0, time: 724950913.664336, track: track01),
            altitude(context: context, value: -0.03436279296875, time: 724950914.68575, track: track01),
            altitude(context: context, value: -0.07135009765625, time: 724950915.706904, track: track01),
            altitude(context: context, value: -0.10040283203125, time: 724950916.728335, track: track01),
            altitude(context: context, value: -0.105682373046875, time: 724950917.749481, track: track01),
            altitude(context: context, value: -0.177032470703125, time: 724950918.770539, track: track01),
            altitude(context: context, value: -0.177032470703125, time: 724950918.924874, track: track01),
            altitude(context: context, value: -0.042266845703125, time: 724950919.870301, track: track01),
            altitude(context: context, value: -0.039642333984375, time: 724950920.815657, track: track01),
            altitude(context: context, value: -0.087188720703125,time: 724950922.706452, track: track01)
        ]

        let altitudes02 = [
            altitude(context: context, value: -0.039642333984375, time: 724950921.761045, track: track02),
            altitude(context: context, value: -0.1268310546875, time: 724950923.651794, track: track02),
            altitude(context: context, value: -0.40692138671875, time: 724950924.5971, track: track02),
            altitude(context: context, value: -0.62359619140625, time: 724950925.542801, track: track02),
            altitude(context: context, value: -0.75042724609375, time: 724950926.488403, track: track02)
        ]

        let altitudes03 = [
            altitude(context: context, value: -0.800628662109375, time: 724950927.433945, track: track03),
            altitude(context: context, value: -0.82177734375, time: 724950928.37943, track: track03),
            altitude(context: context, value: -0.82177734375, time: 724950929.324949, track: track03),
            altitude(context: context, value: -0.8138427734375, time: 724950930.270192, track: track03),
            altitude(context: context, value: -0.760986328125, time: 724950931.215444, track: track03)
        ]

        let geoLocations01 = [
            geoLocation(context: context, accuracy: 56.1642180529081, altitude: 223.446949473874, isPartOfCleanedTrack: true, lat: 51.1270468849433, lon: 13.8406174958848, speed: 0.301344692707062, time: 724950902.615889, verticalAccuracy: 18.4028893294856, track: track01),
            geoLocation(context: context, accuracy: 49.3451165179181, altitude: 213.086007889293, isPartOfCleanedTrack: true, lat: 51.1268701915571, lon: 13.8405518295847, speed: 0.158189192414284, time: 724950921.418904, verticalAccuracy: 123.098972255692, track: track01),
            geoLocation(context: context, accuracy: 32.9940151653233, altitude: 224.084928618521, isPartOfCleanedTrack: true, lat: 51.1268711625691, lon: 13.8405693744368, speed: 0.0998419374227524, time: 724950922.422895, verticalAccuracy: 20.1111012073857, track: track01),
            geoLocation(context: context, accuracy: 28.0445549549875, altitude: 224.165700251402, isPartOfCleanedTrack: true, lat: 51.1268596060179, lon: 13.840545231267, speed: 0.158189192414284, time: 724950923.421886, verticalAccuracy: 20.7650852987605, track: track01),
            geoLocation(context: context, accuracy: 25.667383478623, altitude: 224.179272047587, isPartOfCleanedTrack: true, lat: 51.1268691340547, lon: 13.840557462392, speed: 0.0791846066713333, time: 724950924.425877, verticalAccuracy: 21.603323978082, track: track01),
            geoLocation(context: context, accuracy: 28.7234627465758, altitude: 224.067943695888, isPartOfCleanedTrack: true, lat: 51.1268730890032, lon: 13.8405747526639, speed: 0.280316174030304, time: 724950925.426868, verticalAccuracy: 30.4089647328314, track: track01),
            geoLocation(context: context, accuracy: 16.3220083159378, altitude: 224.156405706542, isPartOfCleanedTrack: true, lat: 51.1268837485623, lon: 13.8405603880926, speed: 0.237982839345932, time: 724950926.41886, verticalAccuracy: 19.7885743730682, track: track01),
            geoLocation(context: context, accuracy: 27.4181586179649, altitude: 224.128535215531, isPartOfCleanedTrack: true, lat: 51.126887568951, lon: 13.8405619588199, speed: 0.0307688973844051, time: 724950927.370358, verticalAccuracy: 36.0837321603331, track: track01),
            geoLocation(context: context, accuracy: 28.2862901461546, altitude: 224.08801813116, isPartOfCleanedTrack: true, lat: 51.1268888120324, lon: 13.8405689569235, speed: 0.146752059459686, time: 724950928.319752, verticalAccuracy: 40.1092861955452, track: track01),
            geoLocation(context: context, accuracy: 29.8227075197582, altitude: 224.13220483198, isPartOfCleanedTrack: true, lat: 51.1268867765506, lon: 13.8405818086027, speed: 0.0989893227815628, time: 724950929.269751, verticalAccuracy: 45.2987996990959, track: track01),
        ]

        let geoLocations02 = [
            geoLocation(context: context, accuracy: 21.6957010221049, altitude: 224.065939401193, isPartOfCleanedTrack: true, lat: 51.1268805997835, lon: 13.8405856052651, speed: 0.0603708364069462, time: 724950930.219758, verticalAccuracy: 34.7857215402413, track: track02),
            geoLocation(context: context, accuracy: 28.9867414045402, altitude: 224.033373801766, isPartOfCleanedTrack: true, lat: 51.1268802739109, lon: 13.8405906114663, speed: 0.112321317195892, time: 724950931.169769, verticalAccuracy: 48.9433901628204, track: track02),
            geoLocation(context: context, accuracy: 23.6322162119336, altitude: 223.972528854363, isPartOfCleanedTrack: true, lat: 51.1268802672219, lon: 13.8405964386421, speed: 0.126897633075714, time: 724950932.119773, verticalAccuracy: 40.4641177841932, track: track02),
            geoLocation(context: context, accuracy: 21.1750783227442, altitude: 223.940635123387, isPartOfCleanedTrack: true, lat: 51.1268847502428, lon: 13.8406049800891, speed: 0.097839817404747, time: 24950933.069781, verticalAccuracy: 34.5918533014181, track: track02),
            geoLocation(context: context, accuracy: 21.1750783227442, altitude: 223.940635189414, isPartOfCleanedTrack: true, lat: 51.1268847502431, lon: 13.8406049800891, speed: 0.097839817404747, time: 724950934.019789, verticalAccuracy: 34.5918533014181, track: track02),
        ]

        let geoLocations03 = [
            geoLocation(context: context, accuracy: 20.130087350333, altitude: 223.865958902985, isPartOfCleanedTrack: true, lat: 51.1268885253556, lon: 13.8405978896466, speed: 0.0643103495240211, time: 724950934.999789, verticalAccuracy: 33.8971608315388, track: track03),
            geoLocation(context: context, accuracy: 27.5634382861303, altitude: 223.873959284276, isPartOfCleanedTrack: true, lat: 51.126890002955, lon: 13.8406112093355, speed: 0.131205871701241, time: 724950935.999803, verticalAccuracy: 48.2118172990258, track: track03),
            geoLocation(context: context, accuracy: 19.0548840755892, altitude: 223.829758910462, isPartOfCleanedTrack: true, lat: 51.1268838711546, lon: 13.8406060071526, speed: 0.0586166977882385, time: 724950936.999811, verticalAccuracy: 33.0066329662987, track: track03),
            geoLocation(context: context, accuracy: 19.8054513560839, altitude: 223.80559986271, isPartOfCleanedTrack: true, lat: 51.1268830543949, lon: 13.8406016673672, speed: 0.199678122997284, time: 724950937.99981, verticalAccuracy: 33.9514543403076, track: track03),
            geoLocation(context: context, accuracy: 20.9461961042093, altitude: 223.752341356128, isPartOfCleanedTrack: true, lat: 51.1268873236406, lon: 13.8406092554929, speed: 0.12847051024437, time: 724950938.999823, verticalAccuracy: 34.2733579187143, track: track03),
        ]

        let events01 = [
            event(context: context, time: Date(timeIntervalSince1970: 724950902.615889), type: .modalityTypeChange, value: "BICYCLE", measurement: measurement01),
            event(context: context, time: Date(timeIntervalSince1970: 724950902.615889), type: .lifecycleStart, value: nil, measurement: measurement01),
            event(context: context, time: Date(timeIntervalSince1970: 724950929.269751), type: .lifecycleStop, value: nil, measurement: measurement01)
        ]

        let events02 = [
            event(context: context, time: Date(timeIntervalSince1970: 724950930.219758), type: .modalityTypeChange, value: "BICYCLE", measurement: measurement01),
            event(context: context, time: Date(timeIntervalSince1970: 724950930.219758), type: .lifecycleStart, value: nil, measurement: measurement01),
            event(context: context, time: Date(timeIntervalSince1970: 724950934.019789), type: .lifecyclePause, value: nil, measurement: measurement01),
            event(context: context, time: Date(timeIntervalSince1970: 724950934.999789), type: .lifecycleResume, value: nil, measurement: measurement01),
            event(context: context, time: Date(timeIntervalSince1970: 724950938.999823), type: .lifecycleStop, value: nil, measurement: measurement01)
        ]
        let tracks01 = [track01]
        let tracks02 = [track02, track03]

        track01.setValue(NSOrderedSet(array: altitudes01), forKey: "altitudes")
        track01.setValue(NSOrderedSet(array: geoLocations01), forKey: "locations")
        track02.setValue(NSOrderedSet(array: altitudes02), forKey: "altitudes")
        track02.setValue(NSOrderedSet(array: geoLocations02), forKey: "locations")
        track03.setValue(NSOrderedSet(array: altitudes03), forKey: "altitudes")
        track03.setValue(NSOrderedSet(array: geoLocations03), forKey: "locations")
        measurement01.setValue(NSOrderedSet(array: tracks01), forKey: "tracks")
        measurement01.setValue(NSOrderedSet(array: events01), forKey: "events")
        measurement02.setValue(NSOrderedSet(array: tracks02), forKey: "tracks")
        measurement02.setValue(NSOrderedSet(array: events02), forKey: "events")

        try context.save()
    }

    /// Create a V11 geo location from a `Double` timestamp in seconds since 1st january 1970..
    func geoLocation(context: NSManagedObjectContext, accuracy: Double, altitude: Double, isPartOfCleanedTrack: Bool, lat: Double, lon: Double, speed: Double, time: Double, verticalAccuracy: Double, track: NSManagedObject) -> NSManagedObject {
        return geoLocation(
            context: context,
            accuracy: accuracy,
            altitude: altitude,
            isPartOfCleanedTrack: isPartOfCleanedTrack,
            lat: lat,
            lon: lon,
            speed: speed,
            time: Date(timeIntervalSince1970: time),
            verticalAccuracy: verticalAccuracy,
            track: track
        )
    }

    /// Create a V11 geo location.
    func geoLocation(context: NSManagedObjectContext, accuracy: Double, altitude: Double, isPartOfCleanedTrack: Bool, lat: Double, lon: Double, speed: Double, time: Date, verticalAccuracy: Double, track: NSManagedObject) -> NSManagedObject{

        let properties: [String: Any?] = [
            "accuracy": accuracy,
            "altitude":altitude,
            "lat":lat,
            "lon":lon,
            "speed":speed,
            "time":time,
            "verticalAccuracy":verticalAccuracy
        ]

        let relations: [String: Any?] = [
            "track":track
        ]

        return geoLocation(context: context, properties: properties, relations: relations)
    }

    func geoLocation(context: NSManagedObjectContext, properties: [String: Any?], relations: [String: Any?]) -> NSManagedObject {
        let location = NSEntityDescription.insertNewObject(forEntityName: "GeoLocation", into: context)
        properties.forEach { property in
            location.setPrimitiveValue(property.value, forKey: property.key)
        }
        relations.forEach { relation in
            location.setValue(relation.value, forKey: relation.key)
        }

        return location
    }

    /// Create a V11 track.
    func track(context: NSManagedObjectContext, measurement: NSManagedObject) -> NSManagedObject {
        let track = NSEntityDescription.insertNewObject(forEntityName: "Track", into: context)
        track.setValue(measurement, forKey: "measurement")

        return track
    }

    /// Create a V11 measurement.
    func measurement(
        context: NSManagedObjectContext,
        identifier: Int64,
        time: Date,
        synchronizable: Bool,
        synchronized: Bool,
        trackLength: Int
    ) -> NSManagedObject {
        let properties: [String: Any?] = [
            "identifier": identifier,
            // Nicht synchronisiert
            "synchronizable":synchronizable,
            "synchronized":synchronized,
            "time":time,
            "trackLength":trackLength
        ]

        return measurement(context: context, properties: properties)
    }

    func measurement(context: NSManagedObjectContext, properties: [String: Any?]) -> NSManagedObject {
        let measurement = NSEntityDescription.insertNewObject(forEntityName: "Measurement", into: context)
        properties.forEach { property in
            measurement.setPrimitiveValue(property.value, forKey: property.key)
        }

        return measurement
    }

    /// Create a V11 event.
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

    /// Create a V11 altitude with a `Double` timestamp in seconds since 1st january 1970.
    func altitude(
        context: NSManagedObjectContext,
        value: Double,
        time: Double,
        track: NSManagedObject
    ) -> NSManagedObject {
        return self.altitude(context: context, value: value, time: Date(timeIntervalSince1970: time), track: track)
    }

    /// Create a V11 altitude.
    func altitude(
        context: NSManagedObjectContext,
        value: Double,
        time: Date,
        track: NSManagedObject
    ) -> NSManagedObject {
        let altitude = NSEntityDescription.insertNewObject(forEntityName: "Altitude", into: context)
        altitude.setPrimitiveValue(value, forKey: "altitude")
        altitude.setPrimitiveValue(time, forKey: "time")
        altitude.setValue(track, forKey: "track")

        return altitude
    }
}
