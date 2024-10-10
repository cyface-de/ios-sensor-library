//
//  AltitudeMO+CoreDataProperties.swift
//  DataCapturing
//
//  Created by Klemens Muthmann on 09.10.24.
//
//

import Foundation
import CoreData


extension AltitudeMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AltitudeMO> {
        return NSFetchRequest<AltitudeMO>(entityName: "Altitude")
    }

    @NSManaged public var altitude: Double
    @NSManaged public var time: Date?
    @NSManaged public var track: TrackMO?

}
