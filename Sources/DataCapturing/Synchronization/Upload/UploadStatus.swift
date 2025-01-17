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

/**
 A mapping between an ``Upload`` and and its current upload status.

 - Author: Klemens Muthmann
 */
public struct UploadStatus {
    /// The measurement identifier of this status.
    public let upload: any Upload
    /// The current status.
    public let status: UploadStatusType

    /// Create a new completely initialized object of this class.
    public init(upload: any Upload, status: UploadStatusType) {
        self.upload = upload
        self.status = status
    }
}

/**
 The current status of an upload to a Cyface Data Collector service.

 - Author: Klemens Muthmann
 */
public enum UploadStatusType: CustomStringConvertible {
    /// Upload has been started
    case started
    /// Upload was finished successfully.
    case finishedSuccessfully
    /// Encountered an issue but a retry is advisable.
    case finishedUnsuccessfully
    /// Upload failed because of the provided error. No further upload attempts should be started.
    case finishedWithError(cause: Error)

    public var description: String {
        switch(self) {
        case .started:
            "started"
        case .finishedSuccessfully:
            "finishedSuccessfully"
        case .finishedUnsuccessfully:
            "finishedUnsuccessfully"
        case .finishedWithError(cause: let error):
            "finishedWithError: \(error.localizedDescription)"
        }
    }
}
