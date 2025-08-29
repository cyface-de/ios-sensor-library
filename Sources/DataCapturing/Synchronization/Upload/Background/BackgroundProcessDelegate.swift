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
import OSLog
import Combine

/**
 Implement all delegates required for a background `URLSession` for a Cyface ``BackgroundUploadProcess``.

 - Author: Klemens Muthmann
 */
public class BackgroundProcessDelegate: NSObject, URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {

    // MARK: - Properties
    /// The connection to the data store, to persist data between putting the app into the background.
    let dataStoreStack: DataStoreStack
    /// Store values to an appropriate file for later background uploads.
    let sensorValueFileFactory: any SensorValueFileFactory
    /// Manage currently open upload sessions.
    var sessionRegistry: SessionRegistry
    /// Send updates about the current state of uploads to interested partys.
    let messageBus: any Subject<UploadStatus, Never>
    /// Handle events on network responses.
    let eventHandler: BackgroundEventHandler
    // TODO: This should probably be a weak reference.
    /// The delegate containing the `completionHandler` provided by the system.
    /// This is often the `AppDelegate`.
    var backgroundUrlSessionEventDelegate: BackgroundURLSessionEventDelegate

    // MARK: - Initializers
    /**
     Initialize a new object of this class with the provided paramters.

     - Parameters:
        - dataStoreStack: The connection to the data store, to persist data between putting the app into the background.
        - sensorValueFileFactory: Store values to an appropriate file for later background uploads.
        - sessionRegistry: Manage currently open upload sessions.
        -  messageBus: Send updates about the current state of uploads to interested partys.
        - eventHandler: Handle events on network responses.
        - backgroundURLSessionEventDelegate: The delegate containing the `completionHandler` provided by the system. This is often the `AppDelegate`.
     */
    public init(
        dataStoreStack: DataStoreStack,
        sensorValueFileFactory: any SensorValueFileFactory,
        sessionRegistry: SessionRegistry,
        messageBus: any Subject<UploadStatus, Never>,
        eventHandler: BackgroundEventHandler,
        backgroundUrlSessionEventDelegate: BackgroundURLSessionEventDelegate
    ) {
        self.dataStoreStack = dataStoreStack
        self.sensorValueFileFactory = sensorValueFileFactory
        self.sessionRegistry = sessionRegistry
        self.messageBus = messageBus
        self.eventHandler = eventHandler
        // TODO: Make this reference weak
        self.backgroundUrlSessionEventDelegate = backgroundUrlSessionEventDelegate
        super.init()
        os_log("✅ BackgroundProcessDelegate wurde INITIALISIERT.", log: OSLog.default, type: .debug)
    }

    deinit {
        os_log("❌ BackgroundProcessDelegate wird ZERSTÖRT (deinit).", log: OSLog.default, type: .error)
    }

    // MARK: - Methods

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        os_log("Sync - Session datatask did receive completionhandler.", log: OSLog.synchronization, type: .debug)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        os_log("Sync - Session datatask did receive.", log: OSLog.synchronization, type: .debug)
    }

    /// Called by the system after an upload has finished. This can be called after the app was killed in the background.
    ///
    /// To recreate the upload from the serialized storage, the `URLSessionTask` description contains the `measurementIdentifier`, the system did try to upload with this request.
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        os_log("Sync - Request Session complete!", log: OSLog.synchronization, type: .debug)

        defer {
            DispatchQueue.main.async { [weak self] in
                if let completionHandler = self?.backgroundUrlSessionEventDelegate.completionHandler {
                    self?.backgroundUrlSessionEventDelegate.completionHandler = nil
                    completionHandler()
                }
            }
        }

        guard let description = task.taskDescription else {
            os_log("Sync - No task description aborting upload!", log: OSLog.synchronization, type: .error)
            fatalError("Sync - Wrong call to urlSession. Did not contain a taskDescription!")
        }
        os_log("Sync - Response described as %{PUBLIC}@!", log: OSLog.synchronization, type: .debug, description)
        let descriptionPieces = description.split(separator: ":")
        guard descriptionPieces.count == 2 else {
            os_log("Sync - Invalid task description %@.", log: OSLog.synchronization, type: .error, description)
            fatalError("Sync - Task Description was not parseable!")
        }
        let responseType = descriptionPieces[0]
        guard let measurementIdentifier = UInt64(descriptionPieces[1]) else {
            fatalError("Sync - Task Description did not contain a valid measurement identifier!")
        }

        let measurement = try! dataStoreStack.wrapInContextReturn { context in
            let request = MeasurementMO.fetchRequest()
            request.predicate = NSPredicate(format: "identifier=%d", measurementIdentifier)
            request.fetchLimit = 1
            guard let storedMeasurement = try request.execute().first else {
                throw PersistenceError.measurementNotLoadable(measurementIdentifier)
            }
            return try FinishedMeasurement(managedObject: storedMeasurement, sensorValueFileFactory: sensorValueFileFactory)
        }

        Task {
            guard var upload = try! sessionRegistry.get(measurement: measurement) else {
                os_log("Sync - No session registered for Measurement %d!", measurementIdentifier)
                return
            }

            guard let response = task.response as? HTTPURLResponse else {
                os_log("Sync - Response not received!", log: OSLog.synchronization, type: .error)
                messageBus.send(UploadStatus(upload: upload, status: .finishedUnsuccessfully))
                return
            }
            os_log("Sync - HTTP response received with Status Code %{PUBLIC}d!", log: OSLog.synchronization, type: .debug, response.statusCode)

            if let error = error {
                os_log("Sync - Error: %{PUBLIC}d", log: OSLog.synchronization, type: .error, error.localizedDescription)
                messageBus.send(UploadStatus(upload: upload, status: .finishedUnsuccessfully))
                return
            }
            os_log("Sync - Request processed successfully!", log: OSLog.synchronization, type: .debug)

            guard let url = response.url else {
                os_log("Sync - No URL returned from response!", log: OSLog.synchronization, type: .error)
                messageBus.send(UploadStatus(upload: upload, status: .finishedUnsuccessfully))
                return
            }
            os_log("Sync targeted URL: %{PUBLiC}@", log: OSLog.synchronization, type: .debug, url.absoluteString)

            do {
                switch responseType {
                case "STATUS":
                    os_log("STATUS: %{PUBLIC}@", log: OSLog.synchronization, type: .debug, url.absoluteString)

                    upload.bytesUploaded = try bytesUploaded(response: response)
                    try await eventHandler.onReceivedStatusRequest(
                        httpStatusCode: Int16(response.statusCode),
                        upload: upload
                    )
                case "PREREQUEST":
                    os_log("PREREQUEST: %{PUBLIC}@", log: OSLog.synchronization, type: .debug, url.absoluteString)
                    guard let locationValue = response.value(forHTTPHeaderField: "Location") else {
                        os_log("Sync - PreRequest is missing upload location!")
                        throw ServerConnectionError.noLocation
                    }
                    os_log("Sync - Received PreRequest to %@", log: OSLog.synchronization, type: .debug, locationValue)
                    guard let locationUrl = URL(string: locationValue) else {
                        throw ServerConnectionError.invalidUploadLocation(locationValue)
                    }

                    upload.location = locationUrl
                    try await eventHandler.onReceivedPreRequest(
                        httpStatusCode: Int16(response.statusCode),
                        upload: upload
                    )
                case "UPLOAD":
                    os_log("UPLOAD", log: OSLog.synchronization, type: .debug)
                    upload.bytesUploaded = try bytesUploaded(response: response)

                    try eventHandler.onReceivedUploadResponse(
                        httpStatusCode: Int16(response.statusCode),
                        upload: upload
                    )
                default:
                    os_log("%{PUBLIC}@", log: OSLog.synchronization, type: .debug, description)
                }
            } catch {
                try sessionRegistry.record(upload: upload, from(text: String(responseType)), httpStatusCode: Int16(response.statusCode), error: error)
                messageBus.send(UploadStatus(upload: upload, status: .finishedWithError(cause: error)))
                os_log("%{PUBLIC}d", log: OSLog.synchronization, type: .error, error.localizedDescription)
            }
        }
    }

    /// This method seems to never be called, but if removed the delegate does not work any longer. Therefore this method should never be deleted.
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        os_log("Sync - URLSession did finish events", log: OSLog.synchronization, type: .debug)
        defer {
            DispatchQueue.main.async { [weak self] in
                if let completionHandler = self?.backgroundUrlSessionEventDelegate.completionHandler {
                    self?.backgroundUrlSessionEventDelegate.completionHandler = nil
                    completionHandler()
                }
            }
        }
    }

    private func from(text: String) -> RequestType {
        if text == "STATUS" {
            return .status
        } else if text == "PREREQUEST" {
            return .prerequest
        } else {
            return .upload
        }
    }

    /**
     Calculates the number of bytes uploaded by the request producing the `response`.

     For this to work the response must contain the "Range"-header with a value in the form "bytes=0-XXX", where XXX is the actual value of bytes uploaded.
     If no such header is found or the format is not correct, this function throws an Exception.
     */
    private func bytesUploaded(response: HTTPURLResponse) throws -> Int {
        guard let rangeHeader = (response.allHeaderFields["Range"] as? String) else {
            throw UploadProcessError.missingRangeHeader
        }

        guard let range = rangeHeader.range(of: "bytes=0-") else {
            throw UploadProcessError.invalidRangeHeaderValue
        }

        guard let bytesUploaded = Int(rangeHeader[range.upperBound...]) else {
            throw UploadProcessError.uploadedBytesUnparseable
        }

        return bytesUploaded
    }
}
