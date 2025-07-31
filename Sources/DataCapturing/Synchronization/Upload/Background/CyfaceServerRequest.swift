import Foundation

/**
 Base protocol for all requests issued during data upload, via the Cyface Upload Protocol.
 */
protocol CyfaceServerRequest {
    /// Provide the `UploadTask` used for the request.
    ///
    /// You need to store this reference as long as the upload runs, or it will be discarded.
    func send() throws -> URLSessionTask
}
