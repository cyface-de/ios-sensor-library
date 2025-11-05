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

/**
 Errors occuring during the ``UploadProcess``.
 */
public enum UploadProcessError: Error {
    /// Initialization was wrong. You need to provide a valid `URLSession` before calling any methods on an `UploadProcess`.
    case missingUrlSession
    /// Received a response and tried to find out which bytes had been uploaded but the range header was missing.
    case missingRangeHeader
    /// Tried to parse a range header in an HTTP response but it contained an unparseable value.
    case invalidRangeHeaderValue
    /// Parsed a range header but could not convert the uploadedBytes value to a 64 Bit Integer.
    case uploadedBytesUnparseable
    /// An `Upload` did not contain location information when it was expected.
    case missingLocation
}

extension UploadProcessError: LocalizedError {
    public var localizedDescription: String? {
        return switch self {
        case .missingUrlSession:
            NSLocalizedString("de.cyface.datacapturing.error.uploadprocesserror.missingurlsession", comment: "The URL Session was not assigned correctly to the upload process! If this happens, the SDK was implemented incorrectly.")
        case .missingRangeHeader:
            NSLocalizedString("de.cyface.datacapturing.error.uploadprocesserror.missingrangeheader", comment: "The response from the server did not provide the range of bytes to upload. Is this a valid Cyface Data Collector Server?")
        case .invalidRangeHeaderValue:
            NSLocalizedString("de.cyface.datacapturing.error.uploadprocesserror.invalidrangeheadervalue", comment: "The response from the server did contain a range header but the value was not parseable. Is this a valid Cyface Data Collector Server? The correct value of the range header should follow the format: bytes=0-XXX")
        case .uploadedBytesUnparseable:
            NSLocalizedString("de.cyface.datacapturing.error.uploadprocesserror.uploadedbytesunparseable", comment: "The bytes value provided by the range header was no parseable integer. Is this a valid Cyface Data Collector Server?")
        case .missingLocation:
            NSLocalizedString("de.cyface.datacapturing.error.uploadprocesserror.missinglocation", comment: "The response from the server did not provide a valid location header. Is this a valid Cyface Data Collector Server?")
        }
    }

}
