/*
 * Copyright 2024 Cyface GmbH
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

import Testing
import Foundation
import AppAuth
@testable import DataCapturing

@Test("Test that saving the authentication state and reloading from disk works, as expected.")
func savingAuthStateHappyPath() async throws {
    let oocut = OAuthAuthenticator(
        issuer: URL(string: "http://localhost/")!,
        redirectUri: URL(string: "http://localhost/callback")!,
        apiEndpoint: URL(string: "http://localhost/api")!,
        clientId: "ios-client"
    )

    let testConfiguration = OIDServiceConfiguration(
        authorizationEndpoint: URL(string: "http://localhost/authorized")!,
        tokenEndpoint: URL(string: "http://localhost/token")!,
        issuer: URL(string: "http://localhost/")!,
        registrationEndpoint: URL(string: "http://localhost/registration"),
        endSessionEndpoint: URL(string: "http://localhost/endsession")
    )
    let testRequest = OIDAuthorizationRequest(
        configuration: testConfiguration,
        clientId: "ios-client",
        scopes: [OIDScopeOpenID, OIDScopeProfile],
        redirectURL: URL(string: "http://localhost/callback")!,
        responseType: OIDResponseTypeCode, additionalParameters: [:]
    )
    let testResponse = OIDAuthorizationResponse(request: testRequest, parameters: [:])
    let testState = OIDAuthState(authorizationResponse: testResponse)

    try oocut.saveState(testState, "de.cyface.test.authstate")
    let loadedState = try oocut.loadState("de.cyface.test.authstate")

    // OIDAuthState does not implement isEqual and thus direct comparison always fails.
    // We are just comparing a few attributes here
    // There is an open issue about this: https://github.com/openid/AppAuth-iOS/issues/122
    #expect(
        loadedState?.lastAuthorizationResponse.request.authorizationRequestURL() == testState.lastAuthorizationResponse.request.authorizationRequestURL()
    )
}
