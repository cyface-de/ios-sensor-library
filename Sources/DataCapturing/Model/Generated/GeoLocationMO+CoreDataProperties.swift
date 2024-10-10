//
//  GeoLocationMO+CoreDataProperties.swift
//  DataCapturing
//
//  Created by Klemens Muthmann on 09.10.24.
//
//

import Foundation
import CoreData


extension GeoLocationMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GeoLocationMO> {
        return NSFetchRequest<GeoLocationMO>(entityName: "GeoLocation")
    }

    @NSManaged public var accuracy: Double
    @NSManaged public var altitude: Double
    @NSManaged public var lat: Double
    @NSManaged public var lon: Double
    @NSManaged public var speed: Double
    @NSManaged public var time: Date?
    @NSManaged public var verticalAccuracy: Double
    @NSManaged public var track: TrackMO?

}
