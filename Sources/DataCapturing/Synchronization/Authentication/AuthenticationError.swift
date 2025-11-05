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
 Errors thrown from `Authenticator` instances.
 */
public enum AuthenticationError: Error {
    /// Thrown if an authenticator does not provide a certain way of authentication.
    case notImplemented
    /// General error during authentication.
    case unableToAuthenticate
}

extension AuthenticationError: LocalizedError {
    public var errorDescription: String? {
        return switch self {
        case .notImplemented:
            NSLocalizedString(
                "de.cyface.datacapturing.error.authenticationerror.notimplemented",
                value: "This function has not been implemented.",
                comment: "Communicate that a function was called that was not implemented. This should not happen in production."
            )
        case .unableToAuthenticate:
            NSLocalizedString(
                "de.cyface.datacapturing.error.authenticationerror.unabletoauthenticate",
                comment: "Tell the user that authentication failed. They should check their credentials, check their connection or try again later."
            )
        }
    }
}
