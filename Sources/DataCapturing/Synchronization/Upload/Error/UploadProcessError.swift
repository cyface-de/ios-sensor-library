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

/**
 Errors occuring during the ``UploadProcess``.

 - Author: Klemens Muthmann
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
