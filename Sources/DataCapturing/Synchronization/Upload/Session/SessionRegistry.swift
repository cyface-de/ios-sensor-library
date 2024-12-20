/*
 * Copyright 2022-2024 Cyface GmbH
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

/**
 Stores the open sessions, this app knows about.

 This implementation stores sessions in memory and allows continuation as long as the app was not terminated.

 - author: Klemens Muthmann
 */
public protocol SessionRegistry {
    /// A mapping from the measurement identifier to the REST resource that session is available at.
    mutating func get(measurement: FinishedMeasurement) throws -> (any Upload)?

    /// Record a step in this session. This can be used to track errors or the sequence of requests that caused them.
    mutating func record(upload: any Upload, _ requestType: RequestType, httpStatusCode: Int16, message: String, time: Date) throws

    /// Record an erroneous step in this session.
    mutating func record(upload: any Upload, _ requestType: RequestType, httpStatusCode: Int16, error: Error) throws

    /// Register a `session`for the provided `Measurement`
    /// - Parameter upload: The ``Upload`` to register this session for.
    /// - Returns: The universal unique identifier that session has been stored under
    mutating func register(upload: any Upload) throws

    ///Remove the provided ``Upload`` from this registry.
    mutating func remove(upload: any Upload) throws
}
