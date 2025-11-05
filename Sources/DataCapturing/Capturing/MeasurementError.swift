/*
 * Copyright 2018-2025 Cyface GmbH
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
 An enumeration for all errors caused by capturing data.
 ````
 case isPaused
 case notPaused
 case isRunning
 case notRunning
 ````
 */
public enum MeasurementError: Error {
    /// Thrown if the service was paused when it should not have been.
    case isPaused
    /// Thrown if the service was not paused when it should have been.
    case notPaused
    /// Thrown if the service was running when it should not have been.
    case isRunning
    /// Thrown if the service was not running when it should have been.
    case notRunning
}

extension MeasurementError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .isPaused:
            return NSLocalizedString(
                "de.cyface.datacapturing.error.measurementerror.ispaused",
                comment: "Encountered a paused measurement where none should be!"
            )
        case .notPaused:
            return NSLocalizedString(
                "de.cyface.datacapturing.error.measurementerror.notpaused",
                comment: "The current measurement was not paused but it should have been!"
            )
        case .isRunning:
            return NSLocalizedString(
                "de.cyface.datacapturing.error.measurementerror.isrunning",
                comment: "The current measurement is running but it should not have been!"
            )
        case .notRunning:
            return NSLocalizedString(
                "de.cyface.datacapturing.error.measurementerror.notrunning",
                comment: "The current measurement is not running, but it should!"
            )
        }
    }
}
