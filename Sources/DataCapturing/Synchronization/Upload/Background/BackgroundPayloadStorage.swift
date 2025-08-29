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

class BackgroundPayloadStorage {

    func storePreRequest(data: Data, for upload: any Upload) throws -> URL {
        return try saveToDocuments(data: data, with: String(upload.measurement.identifier))
    }

    func storeUpload(data: Data, for upload: any Upload) throws -> URL {
        guard let filename = upload.location?.lastPathComponent else {
            throw UploadProcessError.missingLocation
        }

        return try saveToDocuments(data: data, with: filename)
    }

    func cleanPreRequest(upload: any Upload) throws {
        try deleteFromDocuments(with: String(upload.measurement.identifier))
    }

    func cleanUpload(upload: any Upload) throws {
        guard let filename = upload.location?.lastPathComponent else {
            throw UploadProcessError.missingLocation
        }

        try deleteFromDocuments(with: filename)
    }

    /**
     Speichert gegebene Daten in einer Datei im Documents-Verzeichnis der App.

     - Parameters:
       - data: Das `Data`-Objekt, das gespeichert werden soll.
       - filename: Der Name für die zu erstellende Datei (z.B. "upload-123.json").
     - Throws: Wirft einen Fehler, wenn das Documents-Verzeichnis nicht gefunden oder die Datei nicht geschrieben werden kann.
     - Returns: Die `URL` zur neu erstellten Datei.
    */
    private func saveToDocuments(data: Data, with filename: String) throws -> URL {
        // 1. Find the URL to the users documents directory
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            // This error should not occur.
            throw NSError(domain: "de.cyface.fileerror", code: 1, userInfo: [NSLocalizedDescriptionKey: "Documents-Directory not found."])
        }

        // 2. Create complete URL for the file
        let fileURL = documentsDirectory.appendingPathComponent(filename)

        // 3. Write data to that location
        // Atomic ensures the file is only written if that can be done completely and without error.
        try data.write(to: fileURL, options: .atomic)

        print("File save to: \(fileURL.path)")

        return fileURL
    }

    private func deleteFromDocuments(with filename: String) throws {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "de.cyface.fileerror", code: 1, userInfo: [NSLocalizedDescriptionKey: "Documents-Directory not found."])
        }

        try FileManager.default.removeItem(at: documentsDirectory.appendingPathComponent(filename))
    }
}
