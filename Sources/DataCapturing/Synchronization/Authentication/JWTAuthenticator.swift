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
 An authenticator that just receives an auth token in some way provided by the implementing app.

 This implementation only supports authentication. Deleting accounts, logout and callback URL and not supported and are going to cause errors or simply do nothing.

 - Author: Klemens Muthmann
 */
public struct JWTAuthenticator {

    /// The method providing a valid auth token.
    let tokenProvider: () async throws -> String?

    /// Create a new instance with the provided method to receive the auth token.
    init(_ tokenProvider: @escaping () async throws -> String?) {
        self.tokenProvider = tokenProvider
    }
}

// MARK: - Authenticator Implementation
extension JWTAuthenticator: Authenticator {

    public func authenticate() async throws -> String {
        if let token = try await tokenProvider() {
            if token.isEmpty {
                throw ServerConnectionError.notAuthenticated("Provided JWT token was empty.")
            }
            return token
        } else {
            throw ServerConnectionError.notAuthenticated("No JWT token provided for authentication.")
        }
    }
    
    public func delete() async throws {
        throw AuthenticationError.notImplemented
    }
    
    public func logout() async throws {
        throw AuthenticationError.notImplemented
    }
    
    public func callback(url: URL) {
        /// Nothing to do here.
    }
}
