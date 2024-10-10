//
//  UploadSession+CoreDataProperties.swift
//  DataCapturing
//
//  Created by Klemens Muthmann on 09.10.24.
//
//

import Foundation
import CoreData


extension UploadSession {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UploadSession> {
        return NSFetchRequest<UploadSession>(entityName: "UploadSession")
    }

    @NSManaged public var location: URL?
    @NSManaged public var time: Date?
    @NSManaged public var measurement: MeasurementMO?
    @NSManaged public var uploadProtocol: NSOrderedSet?

}

// MARK: Generated accessors for uploadProtocol
extension UploadSession {

    @objc(insertObject:inUploadProtocolAtIndex:)
    @NSManaged public func insertIntoUploadProtocol(_ value: UploadTask, at idx: Int)

    @objc(removeObjectFromUploadProtocolAtIndex:)
    @NSManaged public func removeFromUploadProtocol(at idx: Int)

    @objc(insertUploadProtocol:atIndexes:)
    @NSManaged public func insertIntoUploadProtocol(_ values: [UploadTask], at indexes: NSIndexSet)

    @objc(removeUploadProtocolAtIndexes:)
    @NSManaged public func removeFromUploadProtocol(at indexes: NSIndexSet)

    @objc(replaceObjectInUploadProtocolAtIndex:withObject:)
    @NSManaged public func replaceUploadProtocol(at idx: Int, with value: UploadTask)

    @objc(replaceUploadProtocolAtIndexes:withUploadProtocol:)
    @NSManaged public func replaceUploadProtocol(at indexes: NSIndexSet, with values: [UploadTask])

    @objc(addUploadProtocolObject:)
    @NSManaged public func addToUploadProtocol(_ value: UploadTask)

    @objc(removeUploadProtocolObject:)
    @NSManaged public func removeFromUploadProtocol(_ value: UploadTask)

    @objc(addUploadProtocol:)
    @NSManaged public func addToUploadProtocol(_ values: NSOrderedSet)

    @objc(removeUploadProtocol:)
    @NSManaged public func removeFromUploadProtocol(_ values: NSOrderedSet)

}
