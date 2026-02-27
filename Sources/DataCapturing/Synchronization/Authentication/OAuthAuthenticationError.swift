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
 Errors thrown during user authentication against an OAuth identity provider.

 - Author: Klemens Muthmann
 */
public enum OAuthAuthenticatorError: Error {
    case tokenMissing
    case invalidToken
    case invalidResponse
    case errorResponse(status: Int)
    case missingAuthState(cause: Error?)
    case discoveryFailed(cause: String)
    case missingCallbackController
    case missingResponse
    case invalidState
}

extension OAuthAuthenticatorError: Equatable {
    public static func == (lhs: OAuthAuthenticatorError, rhs: OAuthAuthenticatorError) -> Bool {
        switch (lhs, rhs) {
        case (.tokenMissing, .tokenMissing),
             (.invalidToken, .invalidToken),
             (.invalidResponse, .invalidResponse),
             (.missingCallbackController, .missingCallbackController),
             (.missingResponse, .missingResponse),
             (.invalidState, .invalidState):
            return true
        case (.errorResponse(let l), .errorResponse(let r)):
            return l == r
        case (.missingAuthState, .missingAuthState):
            return true  // Error? does not conform to Equatable; causes are ignored
        case (.discoveryFailed(let l), .discoveryFailed(let r)):
            return l == r
        default:
            return false
        }
    }
}

extension OAuthAuthenticatorError: LocalizedError {
    /// Internationalized human readable description of the error.
    public var errorDescription: String? {
        return switch self {
        case .tokenMissing:
            NSLocalizedString(
                "de.cyface.error.oauthauthenticatorerror.tokenMissing",
                value: "No token received on token refresh!",
                comment: "Tell the user that you received no valid auth token on a refresh request. This should actually not happen and points to some serious implementation mistakes.")
        case .invalidResponse:
            NSLocalizedString(
                "de.cyface.error.oauthauthenticationerror.invalidResponse",
                value: "Response was not an HTTP response",
                comment: "Tell the user, that the response was not an HTTP response. This should not happen unless there is some serious implemenetation error."
            )
        case .errorResponse(let error):
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "de.cyface.error.oauthauthenticationerror.errorResponse",
                    value: "Received HTTP status code %d but expected 200",
                    comment: "Tell the user, that the wrong HTTP status code was recieved. It should be 200. The actual value is provided as the first argument."
                ),
                error
            )
        case .missingAuthState(cause: let cause):
            String.localizedStringWithFormat(NSLocalizedString(
                "de.cyface.error.oauthauthenticationerror.missingAuthState",
                value:
"""
There was no authentication state.
This must not happen and indicates a serious implementation error.
Please verify your App and reinstall if possible.
The reported cause for this error was: %@.
""",
                comment:
"""
Tell the user, that the internal auth state did not exist.
Since it is gracefully initialized before used for the first time, this is an error, that should not happen in production.
The cause of this error is provided as the first parameter.
"""
            ),
                                             cause?.localizedDescription ?? "cause unknown"
            )
        case .discoveryFailed(cause: let cause):
            String.localizedStringWithFormat(
                NSLocalizedString(
                    "de.cyface.error.oauthauthenticationerror.discoveryFailed",
                    value:
"""
The authentication mechanism failed to discover its settings from the OAuth Discovery.
This was caused by %@.
""",
                    comment:
"""
Tell the user, that the OAuth discovery failed for some reason.
The actual reason is provided as a String message, as the first argument.
"""
                ),
                cause
            )
        case .missingCallbackController:
            NSLocalizedString(
                "de.cyface.error.oauthauthenticationerror.missingCallackController",
                value:
"""
Trying the call OAuth authentication without a controller to call upon returning to the app is invalid.
""",
                comment:
"""
Tell the user, that OAuth was called in a wrong state. Namely there was no ViewController provided to return to, after successful authentication.
"""
            )
        case .invalidToken:
            NSLocalizedString(
                "de.cyface.error.oauthauthenticationerror.invalidtoken",
                value: "Authentication was not formatted correctly and thus could not be decoded.",
                comment: "Tell the user that an invalid JWT token was encountered!"
            )
        case .missingResponse:
            NSLocalizedString(
                "de.cyface.error.oauthauthenticationerror.missingresponse",
                value: "OAuth request did not return either a response or an error! Unable to proceed with at least one of the two.",
                comment: "This error should not happen on a properly developed system. Tell the user to call for support!"
            )
        case .invalidState:
            NSLocalizedString(
                "de.cyface.error.oauthauthenticationerror.invalidstate",
                value: "The OAuth authentication state was invalid!",
                comment: "This error should not happen on a properly developed system. Tell the user to call for support!"
            )
        }
    }
}
