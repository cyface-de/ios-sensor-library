//
//  MeasurementMO+ManualExtensions.swift
//  DataCapturing
//
//  Created by Klemens Muthmann on 14.04.22.
//

import Foundation
import CoreData

/**
 The class extended here is generated during the build process, by CoreData from the data model file.
 */
extension MeasurementMO {
    /// The identifier is actually unsigned, but CoreData is unable to represent this.
    /// Therefore this computed property provides a convenient conversion.
    public var unsignedIdentifier: UInt64 {
        return UInt64(identifier)
    }

    /**
     The altitudes in this measurement already cast to the correct type.
     */
    public func typedTracks() -> [TrackMO] {
        guard let typedTracks = tracks?.array as? [TrackMO] else {
            fatalError("Unable to cast tracks to the correct type!")
        }

        return typedTracks
    }

    public func typedEvents() -> [EventMO] {
        guard let typedEvents = events?.array as? [EventMO] else {
            fatalError("Unable to cast events to the correct type!")
        }

        return typedEvents
    }
}
