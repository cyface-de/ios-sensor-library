/*
 * Copyright 2024-2025 Cyface GmbH
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
 Create the default ``SensorValueFile`` required by a recent Cyface Data Collector processing the Protobuf format and using the Google Media Upload Protocol.

 - Author: Klemens Muthmann
 */
public struct DefaultSensorValueFileFactory: SensorValueFileFactory {
    /// This factory is used to create files storing arrays of ``SensorValue``.
    public typealias Serializable = [SensorValue]

    /// This factory creates files that serialize data using a ``SensorValueSerializer``.
    public typealias SpecificSerializer = SensorValueSerializer

    /// This factory creates ``SensorValueFile``.
    public typealias FileType = SensorValueFile

    // MARK: - Properties
    let rootPath: URL

    // MARK: - Initializers
    /// Create a new instance of this struct.
    public init() throws {
        rootPath = try DataCapturing.rootPath()
    }

    /// Create a new ``SensorValueFile``.
    ///
    /// - Parameter qualifier: Used to make the file unique and distinguishable from other files storing the same type of data. Usually this is the measurement identifier.
    /// - Parameter fileType: The type of ``SensorValue`` to store.
    public func create(fileType: SensorValueFileType, qualifier: String) throws -> SensorValueFile {
        return try SensorValueFile(
            rootPath: rootPath,
            fileType: fileType,
            qualifier: qualifier
        )
    }
}
