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
import OSLog
import Combine

/**
 This class is responsible for processing server responses from the Cyface Data Collector service.

 The reason for the existence of this class is that these events must be handled in both the ``BackgroundUploadProcess`` and the ``BackgroundEventHandler``.
 To avoid code duplication, both objects share an instance of this class.

 - Author: Klemens Muthmann
 */
public class BackgroundEventHandler {

    // MARK: - Properties
    var sessionRegistry: SessionRegistry
    let messageBus: any Subject<UploadStatus, Never>
    public var discretionaryUrlSession: URLSession?
    let authenticator: Authenticator
    let collectorUrl: URL

    // MARK: - Initializers
    public init(
        sessionRegistry: SessionRegistry,
        messageBus: any Subject<UploadStatus, Never>,
        authenticator: Authenticator,
        collectorUrl: URL
    ) {
        self.sessionRegistry = sessionRegistry
        self.messageBus = messageBus
        self.authenticator = authenticator
        self.collectorUrl = collectorUrl
    }

    // MARK: - Methods
    /// Handle the response to a Google Media Upload status request.
    func onReceivedStatusRequest(httpStatusCode: Int16, upload: any Upload) async throws {
        guard let discretionaryUrlSession = self.discretionaryUrlSession else {
            throw UploadProcessError.missingUrlSession
        }

        switch httpStatusCode {
        case 200: // Upload abgeschlossen. Ignorieren
            os_log("200", log: OSLog.synchronization, type: .debug)
            try sessionRegistry.record(upload: upload, .status, httpStatusCode: httpStatusCode, message: "OK", time: Date.now)
            messageBus.send(UploadStatus(upload: upload, status: .finishedSuccessfully))

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
            messageBus.send(UploadStatus(upload: upload, status: .finishedWithError(cause: error)))
            throw error
        }
    }

    /// Handle the response to a Google Media Upload Protocol pre request.
    func onReceivedPreRequest(httpStatusCode: Int16, upload: any Upload) async throws {
        guard let discretionaryUrlSession = discretionaryUrlSession else {
            throw UploadProcessError.missingUrlSession
        }

        deletePreRequestData(for: upload.measurement)
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
            messageBus.send(UploadStatus(upload: upload, status: .finishedUnsuccessfully))
        case 409: // Upload exists: Cancel and mark as finished
            os_log("409", log: OSLog.synchronization, type: .debug)
            try sessionRegistry.record(
                upload: upload,
                .prerequest,
                httpStatusCode: httpStatusCode,
                message: "Conflict",
                time: Date.now
            )
            messageBus.send(UploadStatus(upload: upload, status: .finishedSuccessfully))

        case 412: // Server does not accept this upload. Cancel and mark as finished
            os_log("412", log: OSLog.synchronization, type: .debug)
            try sessionRegistry.record(
                upload: upload,
                .prerequest,
                httpStatusCode: httpStatusCode,
                message: "Precondition Failed",
                time: Date.now
            )
            messageBus.send(UploadStatus(upload: upload, status: .finishedSuccessfully))

        default:
            os_log("Error: %{PUBLIC}d", log: OSLog.synchronization, type: .debug, httpStatusCode)
            let error = ServerConnectionError.requestFailed(httpStatusCode: Int(httpStatusCode))
            try sessionRegistry.record(upload: upload, .prerequest, httpStatusCode: httpStatusCode, error: error)
            messageBus.send(UploadStatus(upload: upload, status: .finishedWithError(cause: error)))
            throw error
        }
    }

    /// Handle the response to a Google Media Upload Protocol upload request.
    func onReceivedUploadResponse(httpStatusCode: Int16, upload: any Upload) throws {
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
            messageBus.send(UploadStatus(upload: upload, status: .finishedSuccessfully))
        default:
            os_log("Error: %{PUBLIC}d", log: OSLog.synchronization, type: .error, httpStatusCode)
            let error = ServerConnectionError.requestFailed(httpStatusCode: Int(httpStatusCode))
            try sessionRegistry.record(upload: upload, .upload, httpStatusCode: httpStatusCode, error: error)
            messageBus.send(UploadStatus(upload: upload, status: .finishedWithError(cause: error)))
            throw error
        }
    }

    /// Delete the file containing MetaData for a PreRequest from the temporary file location.
    private func deletePreRequestData(for measurement: FinishedMeasurement) {
        let target = FileManager.default.temporaryDirectory.appendingPathComponent("\(measurement.identifier)")
        do {
            try FileManager.default.removeItem(at: target)
        } catch {
            os_log("Failed to delete pre-request data for %{PUBLIC}d: %{PUBLIC}@", log: OSLog.synchronization, type: .error, measurement.identifier, target.absoluteString)
        }
    }
}
