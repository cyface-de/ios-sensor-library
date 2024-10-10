//
//  EventMO+CoreDataProperties.swift
//  DataCapturing
//
//  Created by Klemens Muthmann on 09.10.24.
//
//

import Foundation
import CoreData


extension EventMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EventMO> {
        return NSFetchRequest<EventMO>(entityName: "Event")
    }

    @NSManaged public var time: Date?
    @NSManaged public var type: Int16
    @NSManaged public var value: String?
    @NSManaged public var measurement: MeasurementMO?

}
