/*
 * Copyright 2025 Cyface GmbH
 *
 * This file is part of the Ready for Robots App.
 *
 * The Ready for Robots App is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The Ready for Robots App is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Ready for Robots App. If not, see <http://www.gnu.org/licenses/>.
 */
import OSLog
import Foundation
import Testing
@testable import DataCapturing

let log = OSLog(subsystem: "DataUploadIT", category: "de.cyface.test")

@Test("Check if a basic upload works as expected.", .disabled("Since this test send actual data to the Cyface Staging Server it should only be executed manually in a controlled environment. Usually this means it should run locally on a developers machine prior to a new release but not from within continous integration. Before you run this test you need to set the four parameters at the top to appropriate values and NEVER commit them to version control!"))
func upload() async throws {
    let collectionUrl = URL(string: "")!
    // Our Keycloak Instance contains a test client for such cases. Use that client here.
    let authUrl = ""
    let clientId = ""
    let clientSecret = ""

    let delegate = TestSessionDelegate()

    let urlSession = try #require(delegate.session)
    let testTrack = Track()
    testTrack.locations = [
        TestFixture.randomLocation(),
        TestFixture.randomLocation(),
        TestFixture.randomLocation(),
        TestFixture.randomLocation(),
        TestFixture.randomLocation()
    ]
    let measurement = FinishedMeasurement(
        identifier: 14,
        synchronizable: true,
        synchronized: false,
        time: Date(),
        events: [Event](),
        tracks: [testTrack],
        accelerationData: Data(),
        rotationData: Data(),
        directionData: Data()
    )
    let upload = MockUpload(measurement: measurement)

    // Authenticate
    let authService = KeycloakAuthService(
        authURL: authUrl,
        clientID: clientId,
        clientSecret: clientSecret) // TODO: Remove the Client Secret
    let authToken = try await authService.requestAuthToken()

    let preRequest = BackgroundPreRequest(
        collectorUrl: collectionUrl,
        session: urlSession,
        upload: upload,
        authToken: authToken
    )
    let (preRequestData, preRequestResponse) = try await delegate.send(preRequest)

    #expect(preRequestResponse?.statusCode == 200)
    os_log("Pre Request Location: %@", log: log, type: .debug, preRequestResponse?.allHeaderFields["Location"] as? String ?? "None")
    let uploadLocation = try #require(preRequestResponse?.allHeaderFields["Location"] as? String)
    upload.location = URL(string: uploadLocation)

    let uploadRequest = BackgroundUploadRequest(
        session: urlSession,
        upload: upload
    )

    let (_, uploadRequestResponse) = try await delegate.send(uploadRequest)

    #expect(uploadRequestResponse?.statusCode == 201)
    os_log("Upload Response Header fields \n%@", log: log, type: .debug, uploadRequestResponse?.allHeaderFields ?? "None")

    let statusRequest = BackgroundStatusRequest(
        session: urlSession,
        authToken: authToken,
        upload: upload
    )
    let (_, statusRequestResponse) = try await delegate.send(statusRequest)

    #expect(statusRequestResponse?.statusCode == 200)
    os_log("Status Response Header fields \n%@", log: log, type: .debug, statusRequestResponse?.allHeaderFields ?? "None")

    delegate.cleanUp()
}

/**
 A `URLSessionDataDelegate` used to catch responses and return them to the test for assertion.
 */
class TestSessionDelegate: NSObject, URLSessionDataDelegate {
    // MARK: - Internal Properties
    /// This contains the data received a body from a URL request.
    private var receivedData = Data()
    /// A strong reference to the Continuation is required here.
    /// We must ensure that the Continuation is always resumed/thrown,
    /// to prevent the test from hanging.
    private var continuation: CheckedContinuation<(Data, HTTPURLResponse?), Error>?

    // MARK: - Properties
    /// The delegate manages its own session.
    var session: URLSession?
    /// A strong reference to the current task is also required or else upload will be interrupted.
    var currentTask: URLSessionTask?

    // MARK: - Initializers/Deinitializers
    override init() {
        super.init()

        // Create the session here to enable using `self` as a delegate.
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }

    deinit {
        os_log("Destroying TestSessionDelegate! (Should happen last)", log: log, type: .info)
    }

    // MARK: - Methods
    /// Send the provided `CyfaceServerRequest` asynchronosly and return the body data as well as the response object.
    func send(_ request: CyfaceServerRequest) async throws -> (Data, HTTPURLResponse?) {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(Data, HTTPURLResponse?), Error>) in
            self.continuation = continuation
            do {
                currentTask = try request.send()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Finish the URLSession after being finished with the delegate.
    ///
    /// This is probably unnecessary, if the test is finished without using multiple delegates.
    func cleanUp() {
        self.session?.finishTasksAndInvalidate()
    }
}

// MARK: - URLSessionDelegate implementation
extension TestSessionDelegate: URLSessionDelegate {

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let response = response as? HTTPURLResponse,
              (200...399).contains(response.statusCode) else {
            // Bei Fehler die Continuation fortsetzen mit einem Fehler
            continuation?.resume(throwing: URLError(.badServerResponse))
            continuation = nil // Set to nil to avoid multiple continuations.
            completionHandler(.cancel)
            return
        }
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.receivedData.append(data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Task completed with error: \(error)")
            continuation?.resume(throwing: error)
        } else {
            print("Task completed successfully. Received \(receivedData.count) bytes.")
            // Resume without error.
            continuation?.resume(returning: (receivedData, task.response as? HTTPURLResponse))
        }
        continuation = nil
    }
}

/**
 A service class to get an auth token from a Keycloak OAuth Server.
 */
class KeycloakAuthService {

    // The URL for the token endpoint.
    private let tokenURLString: String
    // The id if the client to use for authentication.
    private let clientID: String
    // The secret used by the client for authentication.
    private let clientSecret: String

    init(authURL: String, clientID: String, clientSecret: String) {
        self.tokenURLString = authURL
        self.clientID = clientID
        self.clientSecret = clientSecret
    }

    /// Request an authentication token from the Keycloak OAuth Server.
    func requestAuthToken() async throws -> String {

        guard let url = URL(string: tokenURLString) else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let parameters = [
            "grant_type": "client_credentials",
            "client_id": clientID,
            "client_secret": clientSecret
        ]

        // Parameter URL encoding
        let postString = parameters.map { (key, value) in
            return "\(key)=\(value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }.joined(separator: "&")

        request.httpBody = postString.data(using: .utf8)

        return try await withCheckedThrowingContinuation { continuation in
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    return continuation.resume(throwing: error)
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    return continuation.resume(throwing: AuthError.invalidResponse)
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    if let data = data, let errorString = String(data: data, encoding: .utf8) {
                        print("Server responded with error: \(httpResponse.statusCode) - \(errorString)")
                        continuation.resume(throwing: AuthError.serverError(statusCode: httpResponse.statusCode, message: errorString))
                    } else {
                        continuation.resume(throwing: AuthError.serverError(statusCode: httpResponse.statusCode, message: "Unknown server error"))
                    }
                    return
                }

                guard let data = data else {
                    return continuation.resume(throwing: AuthError.noData)
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let accessToken = json["access_token"] as? String {
                        continuation.resume(returning: accessToken)
                    } else {
                        continuation.resume(throwing: AuthError.invalidJSONResponse)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            task.resume()
        }
    }

    /// Errors that might occur during authentication.
    enum AuthError: LocalizedError {
        /// Thrown if the autentication URL was invalid.
        case invalidURL
        /// Thrown if the auth server returned an invalid response
        case invalidResponse
        /// Thrown if the auth response was missing its body
        case noData
        /// Thrown if the auth response body was not parseable as proper JSON.
        case invalidJSONResponse
        /// Thrown if the auth server returned an erroneous response status code.
        case serverError(statusCode: Int, message: String)

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "The authentication URL is invalid."
            case .invalidResponse:
                return "The server response was invalid."
            case .noData:
                return "No data received in the server response."
            case .invalidJSONResponse:
                return "The server's JSON response could not be parsed or did not contain an 'access_token'."
            case .serverError(let statusCode, let message):
                return "Server error \(statusCode): \(message)"
            }
        }
    }
}
