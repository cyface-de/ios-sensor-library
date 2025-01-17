/*
 * Copyright 2024 Cyface GmbH
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

import OSLog
import Combine

/**
 An `UploadProcess` that keeps running in the background even after the app was terminated.

 - Author: Klemens Muthmann
 */
class BackgroundUploadProcess: NSObject {
    // MARK: - Properties
    // TODO: There should be only one URLSession per App. Make sure this gets injected.
    /// A `URLSession` to use for sending requests and receiving responses, probably in the background.
    lazy var discretionaryUrlSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: DefaultUploadProcess.discretionaryUrlSessionIdentifier)
        //Determines the maximum number of simulataneous connections to a Host. This is a per session property.
        config.httpMaximumConnectionsPerHost = 1
        // This controles whether you are allowed to continue your upload/download over cellular access.
        config.allowsCellularAccess = false
        // This makes sure you get an event on your app session launch (in your AppDelegate). (Your app might be killed by system even if your upload/download is going on)
        config.sessionSendsLaunchEvents = true
        // This tells the system to wait for connectivity and then resume uploading/downloading. If the network goes away, it will restart from 0.
        // This is ignored by background sessions always waiting for connectivity
        config.waitsForConnectivity = true
        // Only transmit during convenient times
        config.isDiscretionary = true

        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    /// The `UploadProcessBuilder` that created this `UploadProcess`.
    let builder: BackgroundUploadProcessBuilder
    /// The ``SessionRegistry`` storing the currently active upload sessions.
    var sessionRegistry: SessionRegistry
    /// The location of a Cyface data collector server, to send the data to.
    let collectorUrl: URL
    /// A factory to create
    let uploadFactory: UploadFactory
    /// The connection to the data store, to persist data between putting the app into the background.
    let dataStoreStack: DataStoreStack
    /// Used to authenticate each request.
    let authenticator: Authenticator
    /// A *Combine* publisher to send information about the status of all the uploads.
    let uploadStatus = PassthroughSubject<UploadStatus, Never>()
    let sensorValueFileFactory: any SensorValueFileFactory
    var backgroundUrlSessionEventDelegate: BackgroundURLSessionEventDelegate
    /// Store processing of upload status functions as long as this object is alive.
    var uploadStatusCancellable: AnyCancellable?

    // MARK: - Initializers
    /// Create a new complete instance of this class.
    init(
        builder: BackgroundUploadProcessBuilder,
        sessionRegistry: SessionRegistry,
        collectorUrl: URL,
        uploadFactory: UploadFactory,
        dataStoreStack: DataStoreStack,
        authenticator: Authenticator,
        sensorValueFileFactory: any SensorValueFileFactory,
        backgroundUrlSessionEventDelegate: BackgroundURLSessionEventDelegate
    ) {
        self.builder = builder
        self.sessionRegistry = sessionRegistry
        self.collectorUrl = collectorUrl
        self.uploadFactory = uploadFactory
        self.dataStoreStack = dataStoreStack
        self.authenticator = authenticator
        self.sensorValueFileFactory = sensorValueFileFactory
        self.backgroundUrlSessionEventDelegate = backgroundUrlSessionEventDelegate
        super.init()

        uploadStatusCancellable = uploadStatus.sink { [weak self] status in
            switch status.status {
            case .finishedSuccessfully:
                try! status.upload.onSuccess()
                try! self?.sessionRegistry.remove(upload: status.upload)
            case .finishedWithError(cause: let error):
                try! status.upload.onFailed(cause: error)
                try! self?.sessionRegistry.remove(upload: status.upload)
            case .finishedUnsuccessfully:
                try! self?.sessionRegistry.remove(upload: status.upload)
            default:
                break
            }
        }
    }

    // MARK: - Methods
    /// Handle the response to a Google Media Upload status request.
    private func onReceivedStatusRequest(httpStatusCode: Int16, upload: any Upload) async throws {
        switch httpStatusCode {
        case 200: // Upload abgeschlossen. Ignorieren
            os_log("200", log: OSLog.synchronization, type: .debug)
            try sessionRegistry.record(upload: upload, .status, httpStatusCode: httpStatusCode, message: "OK", time: Date.now)
            uploadStatus.send(UploadStatus(upload: upload, status: .finishedSuccessfully))

        case 308: // Upload fortsetzen
            // TODO: Header zum Fortsetzen setzen
            os_log("308", log: OSLog.synchronization, type: .debug)
            try sessionRegistry.record(
                upload: upload,
                RequestType.status,
                httpStatusCode: httpStatusCode,
                message: "Permanent Redirect",
                time: Date.now)
            let uploadRequest = BackgroundUploadRequest(
                session: discretionaryUrlSession,
                upload: upload
            )
            try uploadRequest.send()

        case 404: // Upload neu starten
            os_log("404", log: OSLog.synchronization, type: .debug)
            try sessionRegistry.record(
                upload: upload,
                RequestType.status,
                httpStatusCode: httpStatusCode,
                message: "Not Found",
                time: Date.now
            )
            let preRequest = BackgroundPreRequest(
                collectorUrl: collectorUrl,
                session: discretionaryUrlSession,
                upload: upload,
                authToken: try await authenticator.authenticate()
            )
            try preRequest.send()

        default:
            os_log("Error: %{PUBLIC}d", log: OSLog.synchronization, type: .debug, httpStatusCode)
            let error = ServerConnectionError.requestFailed(httpStatusCode: Int(httpStatusCode))
            try sessionRegistry.record(upload: upload, .status, httpStatusCode: httpStatusCode, error: error)
            uploadStatus.send(UploadStatus(upload: upload, status: .finishedWithError(cause: error)))
            throw error
        }
    }

    /// Handle the response to a Google Media Upload Protocol pre request.
    private func onReceivedPreRequest(httpStatusCode: Int16, upload: any Upload) async throws {
        switch httpStatusCode {
        case 200: // Send Upload Request
            os_log("200", log: OSLog.synchronization, type: .debug)

            try sessionRegistry.record(
                upload: upload,
                RequestType.prerequest,
                httpStatusCode: httpStatusCode,
                message: "OK",
                time: Date.now
            )
            let uploadRequest = BackgroundUploadRequest(
                session: discretionaryUrlSession,
                upload: upload
            )
            try uploadRequest.send()
        case 401: // Authentication was not successful. Retry later
            os_log("401", log: OSLog.synchronization, type: .error)
            try sessionRegistry.record(
                upload: upload,
                .prerequest,
                httpStatusCode: httpStatusCode,
                message: "Unauthorized",
                time: Date.now
            )
            uploadStatus.send(UploadStatus(upload: upload, status: .finishedUnsuccessfully))
        case 409: // Upload exists: Cancel and mark as finished
            os_log("409", log: OSLog.synchronization, type: .debug)
            try sessionRegistry.record(
                upload: upload,
                .prerequest,
                httpStatusCode: httpStatusCode,
                message: "Conflict",
                time: Date.now
            )
            uploadStatus.send(UploadStatus(upload: upload, status: .finishedSuccessfully))

        case 412: // Server does not accept this upload. Cancel and mark as finished
            os_log("412", log: OSLog.synchronization, type: .debug)
            try sessionRegistry.record(
                upload: upload,
                .prerequest,
                httpStatusCode: httpStatusCode,
                message: "Precondition Failed",
                time: Date.now
            )
            uploadStatus.send(UploadStatus(upload: upload, status: .finishedSuccessfully))

        default:
            os_log("Error: %{PUBLIC}d", log: OSLog.synchronization, type: .debug, httpStatusCode)
            let error = ServerConnectionError.requestFailed(httpStatusCode: Int(httpStatusCode))
            try sessionRegistry.record(upload: upload, .prerequest, httpStatusCode: httpStatusCode, error: error)
            uploadStatus.send(UploadStatus(upload: upload, status: .finishedWithError(cause: error)))
            throw error
        }
    }

    /// Handle the response to a Google Media Upload Protocol upload request.
    private func onReceivedUploadResponse(httpStatusCode: Int16, upload: any Upload) throws {
        switch httpStatusCode {
        case 201:
            os_log("201", log: OSLog.synchronization, type: .debug)
            try sessionRegistry.record(
                upload: upload,
                .upload,
                httpStatusCode: httpStatusCode,
                message: "Created",
                time: Date.now
            )
            uploadStatus.send(UploadStatus(upload: upload, status: .finishedSuccessfully))
        default:
            os_log("Error: %{PUBLIC}d", log: OSLog.synchronization, type: .error, httpStatusCode)
            let error = ServerConnectionError.requestFailed(httpStatusCode: Int(httpStatusCode))
            try sessionRegistry.record(upload: upload, .upload, httpStatusCode: httpStatusCode, error: error)
            uploadStatus.send(UploadStatus(upload: upload, status: .finishedWithError(cause: error)))
            throw error
        }
    }
}

// MARK: - Implementation of UploadProcess
extension BackgroundUploadProcess: UploadProcess {
    func upload(measurement: FinishedMeasurement) async throws -> any Upload {
        /// Check for an open session.
        if let upload = try sessionRegistry.get(measurement: measurement), upload.location != nil {
            /// If there is an open session continue by sending a status request
            uploadStatus.send(UploadStatus(upload: upload, status: .started))
            let statusRequest = BackgroundStatusRequest(
                session: discretionaryUrlSession,
                authToken: try await authenticator.authenticate(),
                upload: upload
            )
            try statusRequest.send()
            /// If the status request was successful continue by sending an upload starting at the byte given by the status request
            /// If the status request was not successful contnue with a pre request
            return upload
        } else {
            /// If there is no open session continue by sending a pre request
            let upload = uploadFactory.upload(for: measurement)
            uploadStatus.send(UploadStatus(upload: upload, status: .started))
            try sessionRegistry.register(upload: upload)
            let preRequest = BackgroundPreRequest(
                collectorUrl: collectorUrl,
                session: discretionaryUrlSession,
                upload: upload,
                authToken: try await authenticator.authenticate()
            )
            try preRequest.send()
            /// If the pre request was successful create a session and start uploading the data
            /// If the upload request completes see if another chunk is due to be uploaded
            /// If yes than start the upload for the next chunk
            /// If not report successful completion
            /// If the upload request failed finish by reporting the error
            /// if the pre request fails finish by reporting the error
            return upload
        }
    }
}

// MARK: - Implementation of Delegates for URLSession
extension BackgroundUploadProcess: URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {
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
                uploadStatus.send(UploadStatus(upload: upload, status: .finishedUnsuccessfully))
                return
            }
            os_log("Upload response received!", log: OSLog.synchronization, type: .debug)

            if let error = error {
                os_log("Upload Error: %{PUBLIC}d", log: OSLog.synchronization, type: .error, error.localizedDescription)
                uploadStatus.send(UploadStatus(upload: upload, status: .finishedUnsuccessfully))
                return
            }
            os_log("Upload was successful!", log: OSLog.synchronization, type: .debug)

            guard let url = response.url else {
                os_log("Upload - No URL returned from response!", log: OSLog.synchronization, type: .error)
                uploadStatus.send(UploadStatus(upload: upload, status: .finishedUnsuccessfully))
                return
            }
            os_log("Upload targeted URL: %{PUBLiC}@", log: OSLog.synchronization, type: .debug, url.absoluteString)

            do {
                // Loading the Upload from the session three times is no accident. This is necessary due to multi threading constraints. Do not try to refactor this.
                // See: https://stackoverflow.com/questions/69556237/use-reference-to-captured-variable-in-concurrently-executing-code
                switch responseType {
                case "STATUS":
                    os_log("STATUS: %{PUBLIC}@", log: OSLog.synchronization, type: .debug, url.absoluteString)
                    try await onReceivedStatusRequest(httpStatusCode: Int16(response.statusCode), upload: upload)
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
                    try await onReceivedPreRequest(httpStatusCode: Int16(response.statusCode), upload: upload)
                case "UPLOAD":
                    os_log("UPLOAD", log: OSLog.synchronization, type: .debug)
                    try onReceivedUploadResponse(httpStatusCode: Int16(response.statusCode), upload: upload)
                default:
                    os_log("%{PUBLIC}@", log: OSLog.synchronization, type: .debug, description)
                }
            } catch {
                uploadStatus.send(UploadStatus(upload: upload, status: .finishedWithError(cause: error)))
                os_log("%{PUBLIC}d", log: OSLog.synchronization, type: .error, error.localizedDescription)
            }
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
