//
//  TrackMO+CoreDataProperties.swift
//  DataCapturing
//
//  Created by Klemens Muthmann on 09.10.24.
//
//

import Foundation
import CoreData


extension TrackMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TrackMO> {
        return NSFetchRequest<TrackMO>(entityName: "Track")
    }

    @NSManaged public var altitudes: NSOrderedSet?
    @NSManaged public var locations: NSOrderedSet?
    @NSManaged public var measurement: MeasurementMO?

}

// MARK: Generated accessors for altitudes
extension TrackMO {

    @objc(insertObject:inAltitudesAtIndex:)
    @NSManaged public func insertIntoAltitudes(_ value: AltitudeMO, at idx: Int)

    @objc(removeObjectFromAltitudesAtIndex:)
    @NSManaged public func removeFromAltitudes(at idx: Int)

    @objc(insertAltitudes:atIndexes:)
    @NSManaged public func insertIntoAltitudes(_ values: [AltitudeMO], at indexes: NSIndexSet)

    @objc(removeAltitudesAtIndexes:)
    @NSManaged public func removeFromAltitudes(at indexes: NSIndexSet)

    @objc(replaceObjectInAltitudesAtIndex:withObject:)
    @NSManaged public func replaceAltitudes(at idx: Int, with value: AltitudeMO)

    @objc(replaceAltitudesAtIndexes:withAltitudes:)
    @NSManaged public func replaceAltitudes(at indexes: NSIndexSet, with values: [AltitudeMO])

    @objc(addAltitudesObject:)
    @NSManaged public func addToAltitudes(_ value: AltitudeMO)

    @objc(removeAltitudesObject:)
    @NSManaged public func removeFromAltitudes(_ value: AltitudeMO)

    @objc(addAltitudes:)
    @NSManaged public func addToAltitudes(_ values: NSOrderedSet)

    @objc(removeAltitudes:)
    @NSManaged public func removeFromAltitudes(_ values: NSOrderedSet)

}

// MARK: Generated accessors for locations
extension TrackMO {

    @objc(insertObject:inLocationsAtIndex:)
    @NSManaged public func insertIntoLocations(_ value: GeoLocationMO, at idx: Int)

    @objc(removeObjectFromLocationsAtIndex:)
    @NSManaged public func removeFromLocations(at idx: Int)

    @objc(insertLocations:atIndexes:)
    @NSManaged public func insertIntoLocations(_ values: [GeoLocationMO], at indexes: NSIndexSet)

    @objc(removeLocationsAtIndexes:)
    @NSManaged public func removeFromLocations(at indexes: NSIndexSet)

    @objc(replaceObjectInLocationsAtIndex:withObject:)
    @NSManaged public func replaceLocations(at idx: Int, with value: GeoLocationMO)

    @objc(replaceLocationsAtIndexes:withLocations:)
    @NSManaged public func replaceLocations(at indexes: NSIndexSet, with values: [GeoLocationMO])

    @objc(addLocationsObject:)
    @NSManaged public func addToLocations(_ value: GeoLocationMO)

    @objc(removeLocationsObject:)
    @NSManaged public func removeFromLocations(_ value: GeoLocationMO)

    @objc(addLocations:)
    @NSManaged public func addToLocations(_ values: NSOrderedSet)

    @objc(removeLocations:)
    @NSManaged public func removeFromLocations(_ values: NSOrderedSet)

}
