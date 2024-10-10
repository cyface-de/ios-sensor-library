//
//  UploadTask+CoreDataProperties.swift
//  DataCapturing
//
//  Created by Klemens Muthmann on 09.10.24.
//
//

import Foundation
import CoreData


extension UploadTask {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UploadTask> {
        return NSFetchRequest<UploadTask>(entityName: "UploadTask")
    }

    @NSManaged public var causedError: Bool
    @NSManaged public var command: Int16
    @NSManaged public var httpStatus: Int16
    @NSManaged public var message: String?
    @NSManaged public var time: Date?
    @NSManaged public var uploadSession: UploadSession?

}
