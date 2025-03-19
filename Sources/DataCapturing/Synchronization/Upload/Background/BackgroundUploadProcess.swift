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

import OSLog
import Combine

/**
 An `UploadProcess` that keeps running in the background even after the app was terminated.

 - Author: Klemens Muthmann
 */
class BackgroundUploadProcess: NSObject {
    // MARK: - Properties
    /// A `URLSession` to use for sending requests and receiving responses, probably in the background.
    let discretionaryUrlSession: URLSession/* = {
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

        return URLSession(configuration: config, delegate: eventDelegate, delegateQueue: nil)
    }()*/
    /// The `UploadProcessBuilder` that created this `UploadProcess`.
    //let builder: BackgroundUploadProcessBuilder
    /// The ``SessionRegistry`` storing the currently active upload sessions.
    var sessionRegistry: SessionRegistry
    /// The location of a Cyface data collector server, to send the data to.
    let collectorUrl: URL
    /// A factory to create
    let uploadFactory: UploadFactory
    
    //let dataStoreStack: DataStoreStack
    /// Used to authenticate each request.
    let authenticator: Authenticator
    /// A *Combine* publisher to send information about the status of all the uploads.
    let uploadStatus = PassthroughSubject<UploadStatus, Never>()
    /// Store processing of upload status functions as long as this object is alive.
    var uploadStatusCancellable: AnyCancellable?

    let eventHandler: BackgroundEventHandler
    let eventDelegate: BackgroundProcessDelegate

    // MARK: - Initializers
    /// Create a new complete instance of this class.
    init(
        sessionRegistry: SessionRegistry,
        collectorUrl: URL,
        uploadFactory: UploadFactory,
        authenticator: Authenticator,
        urlSession: URLSession,
        eventHandler: BackgroundEventHandler,
        eventDelegate: BackgroundProcessDelegate
    ) {
        self.sessionRegistry = sessionRegistry
        self.collectorUrl = collectorUrl
        self.uploadFactory = uploadFactory
        self.authenticator = authenticator
        self.discretionaryUrlSession = urlSession
        self.eventHandler = eventHandler
        self.eventDelegate = eventDelegate
        super.init()

        uploadStatusCancellable = uploadStatus.sink { status in
            switch status.status {
            case .finishedSuccessfully:
                try! status.upload.onSuccess()
            case .finishedWithError(cause: let error):
                try! status.upload.onFailed(cause: error)
            default:
                break
            }
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
