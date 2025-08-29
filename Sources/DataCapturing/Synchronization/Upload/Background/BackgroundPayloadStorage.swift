//
//  TemporaryFileNameBuilder.swift
//  DataCapturing
//
//  Created by Klemens Muthmann on 29.08.25.
//

class BackgroundPayloadStorage {

    func storePreRequest(data: Data, for upload: Upload) throws {
        return saveToDocuments(data: data, with: upload.measurement.identifier)
    }

    func storeUpload(data: Data, for upload: Upload) throws {
        guard let filename = upload.location?.lastPathComponent else {
            throw UploadProcessError.missingLocation
        }

        return saveToDocuments(data: data, with: filename)
    }

    func cleanPreRequest(upload: Upload) throws -> String {
        try deleteFromDocuments(with: upload.measurement.identifier)
    }

    func cleanUpload(upload: Upload) throws -> String {
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
