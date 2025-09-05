/*
 * Copyright 2024-2025 Cyface GmbH
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

import UIKit

/**
 Delegate receiving background URL session events.

 An implementation of this class can be used to access the `completionHandler` usually stored in the `AppDelegate`, by making `AppDelegate` implement this interface.

 - Author: Klemens Muthmann
 */
public protocol BackgroundURLSessionEventDelegate: AnyObject {
    /// Central place to store the bakcground session completion handler.
    ///
    /// For additional information please refer to the [Apple documentation](https://developer.apple.com/documentation/foundation/url_loading_system/downloading_files_in_the_background).
    var completionHandler: (() -> Void)? { get set }

    /// Implement the code called when a `URLSession` is woken up.
    func received(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void)
}

/**
 One step from the ``BackgroundUploadProcessBuilder``.

 Finally create the ``UploadProcess`` from this builder.

 - Author: Klemens Muthmann
 */
public protocol BuildFunction {
    func build() -> UploadProcess
}

/**
 A builder for ``BackgroundUploadProcess`` instances. Since each upload needs its own process. This builder allows to inject the creation into objects, that are synchronizing data to a Cyface data collector service.

 - Author: Klemens Muthmann
 */
public class BackgroundUploadProcessBuilder {

    /**
     Create the builder from the provided parameters.

     - Parameters:
        - sessionRegistry: The ``SessionRegistry`` storing the currently active upload sessions.
        - collectorUrl: The location of a Cyface data collector server, to send the data to.
        - uploadFactory: A factory to create new uploads.
        - authenticator: Provide authentication information to send authenticated requests via the `urlSession`.
        - urlSession: A `URLSession` to use for sending requests and receiving responses, probably in the background.
     */
    public static func create(
        sessionRegistry: SessionRegistry,
        collectorUrl: URL,
        uploadFactory: any UploadFactory,
        authenticator: any Authenticator,
        urlSession: URLSession
    ) -> BuildFunction {
        return InternalBackgroundProcessBuilder(
            sessionRegistry: sessionRegistry,
            collectorUrl: collectorUrl,
            uploadFactory: uploadFactory,
            authenticator: authenticator,
            urlSession: urlSession
        )
    }

    /**
     Internal class implementing all the types required by the builder.

     Making this an internal class prevents callers from viewing the complete structure of the builder.

     - Author: Klemens Muthmann
     */
    public class InternalBackgroundProcessBuilder:
        BuildFunction {

        // MARK: - Attributes
        /// A `URLSession` to use for sending requests and receiving responses, probably in the background.
        let urlSession: URLSession
        /// The registry of active upload session.
        let sessionRegistry: SessionRegistry
        /// The location of a Cyface collector server, used by the created ``UploadProcess`` to send data to.
        let collectorUrl: URL
        /// Factory to create ``Upload`` instances by the ``UploadProcess`` instances.
        let uploadFactory: UploadFactory
        /// Used by the created ``UploadProcess`` to authenticate and authorize uploads with the Cyface data collector.
        let authenticator: Authenticator

        // MARK: - Initializers
        init(
            sessionRegistry: SessionRegistry,
            collectorUrl: URL,
            uploadFactory: UploadFactory,
            authenticator: Authenticator,
            urlSession: URLSession
        ) {
            self.sessionRegistry = sessionRegistry
            self.collectorUrl = collectorUrl
            self.uploadFactory = uploadFactory
            self.authenticator = authenticator
            self.urlSession = urlSession
        }

        public func build() -> UploadProcess {
            return BackgroundUploadProcess(
                sessionRegistry: sessionRegistry,
                collectorUrl: collectorUrl,
                uploadFactory: uploadFactory,
                authenticator: authenticator,
                urlSession: urlSession
            )
        }
    }
}
