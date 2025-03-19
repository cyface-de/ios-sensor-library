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

public class BackgroundProcessDelegate: NSObject, URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {

    // MARK: - Properties
    /// The connection to the data store, to persist data between putting the app into the background.
    let dataStoreStack: DataStoreStack
    let sensorValueFileFactory: any SensorValueFileFactory
    var sessionRegistry: SessionRegistry
    let messageBus: any Subject<UploadStatus, Never>
    let eventHandler: BackgroundEventHandler
    var backgroundUrlSessionEventDelegate: BackgroundURLSessionEventDelegate

    // MARK: - Initializers
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
        self.backgroundUrlSessionEventDelegate = backgroundUrlSessionEventDelegate
    }

    // MARK: - Methods
    /// Called by the system after an upload has finished. This can be called after the app was killed in the background.
    ///
    /// To recreate the upload from the serialized storage, the `URLSessionTask` description contains the `measurementIdentifier`, the system did try to upload with this request.
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {

        guard let description = task.taskDescription else {
            os_log("Upload - No task description aborting upload!", log: OSLog.synchronization, type: .error)
            fatalError("Upload - Wrong call to urlSession. Did not contain a taskDescription!")
        }
        os_log("Upload described as %{PUBLIC}@!", log: OSLog.synchronization, type: .debug, description)
        let descriptionPieces = description.split(separator: ":")
        guard descriptionPieces.count == 2 else {
            os_log("Upload - Invalid task description %@.", log: OSLog.synchronization, type: .error, description)
            fatalError("Upload - Task Description was not parseable!")
        }
        let responseType = descriptionPieces[0]
        guard let measurementIdentifier = UInt64(descriptionPieces[1]) else {
            fatalError("Upload - Task Description did not contain a valid measurement identifier!")
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
                os_log("Upload - No session registered for Measurement %d!", measurementIdentifier)
                return
            }

            guard let response = task.response as? HTTPURLResponse else {
                os_log("Upload response not received!", log: OSLog.synchronization, type: .error)
                messageBus.send(UploadStatus(upload: upload, status: .finishedUnsuccessfully))
                return
            }
            os_log("Upload response received!", log: OSLog.synchronization, type: .debug)

            if let error = error {
                os_log("Upload Error: %{PUBLIC}d", log: OSLog.synchronization, type: .error, error.localizedDescription)
                messageBus.send(UploadStatus(upload: upload, status: .finishedUnsuccessfully))
                return
            }
            os_log("Upload was successful!", log: OSLog.synchronization, type: .debug)

            guard let url = response.url else {
                os_log("Upload - No URL returned from response!", log: OSLog.synchronization, type: .error)
                messageBus.send(UploadStatus(upload: upload, status: .finishedUnsuccessfully))
                return
            }
            os_log("Upload targeted URL: %{PUBLiC}@", log: OSLog.synchronization, type: .debug, url.absoluteString)

            do {
                switch responseType {
                case "STATUS":
                    os_log("STATUS: %{PUBLIC}@", log: OSLog.synchronization, type: .debug, url.absoluteString)
                    try await eventHandler.onReceivedStatusRequest(
                        httpStatusCode: Int16(response.statusCode),
                        upload: upload
                    )
                case "PREREQUEST":
                    os_log("PREREQUEST: %{PUBLIC}@", log: OSLog.synchronization, type: .debug, url.absoluteString)
                    guard let locationValue = response.value(forHTTPHeaderField: "Location") else {
                        throw ServerConnectionError.noLocation
                    }
                    os_log("Upload - Received PreRequest to %@", log: OSLog.synchronization, type: .debug, locationValue)
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

    private func from(text: String) -> RequestType {
        if text == "STATUS" {
            return .status
        } else if text == "PREREQUEST" {
            return .prerequest
        } else {
            return .upload
        }
    }

    // TODO: Move this to a place where it actually gets called.
    @objc(URLSessionDidFinishEventsForBackgroundURLSession:) public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        os_log("Finished background session", log: OSLog.synchronization, type: .info)
        DispatchQueue.main.async { [weak self] in
            if let completionHandler = self?.backgroundUrlSessionEventDelegate.completionHandler {
                self?.backgroundUrlSessionEventDelegate.completionHandler = nil
                completionHandler()
            }
        }
    }
}
