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
 A factory to externalize the creation of ``SensorValueFile`` instances.

 An instance of this class is required to create a ``CapturedDataStorage``.
 Since each measurement requires new instances of a ``SensorValueFile``, this class provides the `CapturedDataStorage` the capability to create the correct type of `SensorValueFile`.
 This can be used if different formats are required or the actual file is mocked for testing.

 - Author: Klemens Muthmann
 */
public protocol SensorValueFileFactory {
    /// The type of object to serialize in the files created from this factory.
    associatedtype Serializable
    /// The serializer for the provided `Serializable`.
    associatedtype SpecificSerializer
    /// The type of objects this factory creates.
    associatedtype FileType: FileSupport where FileType.Serializable == Serializable, FileType.SpecificSerializer == SpecificSerializer
    /// Create the actual file for a certain type
    func create(fileType: SensorValueFileType, qualifier: String) throws -> FileType
}

/// The root path used to store data via this app. This is in global scope, so it gets initialized at application start, since finding the location is a computation heavy operation.
func rootPath() throws -> URL {
    let root = "Application Support"
    let measurementDirectory = "measurements"
    let fileManager = FileManager.default
    let libraryDirectory = FileManager.SearchPathDirectory.libraryDirectory
    let libraryDirectoryUrl = try fileManager.url(for: libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

    let measurementUrl = libraryDirectoryUrl
        .appendingPathComponent(root)
        .appendingPathComponent(measurementDirectory)
    try fileManager.createDirectory(at: measurementUrl, withIntermediateDirectories: true)
    return measurementUrl
}
