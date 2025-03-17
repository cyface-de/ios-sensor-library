/*
 * Copyright 2025 Cyface GmbH
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
 A factory used as a placeholder, in cases were no sensor values are recorded.

 - Author: Klemens Muthmann
 */
public struct NoOpSensorValueFileFactory: SensorValueFileFactory {
    public typealias SpecificSerializer = NoOpSerializer

    public typealias FileType = NoOpFileType

    public func create(fileType: SensorValueFileType, qualifier: String) throws -> NoOpFileType {
        NoOpFileType(rootPath: FileManager.default.temporaryDirectory, fileType: .accelerationValueType, qualifier: "noop")
    }
}

/**
 The non-file-type used by the `NoOpSensorValueFileFactory`.

 - Author: Klemens Muthmann
 */
public struct NoOpFileType: FileSupport {
    public typealias SpecificSerializer = NoOpSerializer
    public typealias Serializable = [SensorValue]
    public var serializer: NoOpSerializer
    public var qualifiedPath: URL

    public init(qualifiedPath: URL) {
        self.qualifiedPath = qualifiedPath
        self.serializer = NoOpSerializer()
    }

    init(rootPath: URL, fileType: SensorValueFileType, qualifier: String) {
        self.qualifiedPath = FileManager.default.temporaryDirectory.appendingPathComponent(qualifier)
        self.serializer = NoOpSerializer()
    }

    public func data() throws -> Data {
        Data()
    }
}

/**
 A Serializer doing nothing.

 This is used by the ``NoOpSensorValueFileFactory``.

 - Author: Klemens Muthmann
 */
public struct NoOpSerializer: BinarySerializer {
    public typealias Serializable = [SensorValue]
    public func serialize(serializable: [SensorValue]) throws -> Data {
        Data()
    }
}
