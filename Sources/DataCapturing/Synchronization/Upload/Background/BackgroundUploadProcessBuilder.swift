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

import Foundation
import UIKit

/**
 Delegate receiving background URL session events.

 - Author: Klemens Muthmann
 */
public protocol BackgroundURLSessionEventDelegate {
    /// Central place to store the bakcground session completion handler.
    ///
    /// For additional information please refer to the [Apple documentation](https://developer.apple.com/documentation/foundation/url_loading_system/downloading_files_in_the_background).
    var completionHandler: (() -> Void)? { get set }

    func received(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void)
}

/**
 A builder for ``BackgroundUploadProcess`` instances. Since each upload needs its own process. This builder allows to inject the creation into objects, that are synchronizing data to a Cyface data collector service.

 - Author: Klemens Muthmann
 */
public class BackgroundUploadProcessBuilder {

    func create(
        sessionRegistry: SessionRegistry,
        collectorUrl: URL,
        uploadFactory: any UploadFactory,
        authenticator: any Authenticator,
        urlSession: URLSession
    ) -> EventHandlerBuilder {
        return InternalBackgroundProcessBuilder(
            sessionRegistry: sessionRegistry,
            collectorUrl: collectorUrl,
            uploadFactory: uploadFactory,
            authenticator: authenticator,
            urlSession: urlSession
        )
    }

    public protocol DelegateBuilder {
        func add(delegate: BackgroundProcessDelegate) -> BuildFunction
    }

    public protocol EventHandlerBuilder {
        func add(handler: BackgroundEventHandler) -> DelegateBuilder
    }

    public protocol BuildFunction {
        func build() -> UploadProcess
    }

    public class InternalBackgroundProcessBuilder:
        BuildFunction,
            DelegateBuilder,
            EventHandlerBuilder {

        // MARK: - Attributes
        let urlSession: URLSession
        /// The registry of active upload session.
        let sessionRegistry: SessionRegistry
        /// The location of a Cyface collector server, used by the created ``UploadProcess`` to send data to.
        let collectorUrl: URL
        /// Factory to create ``Upload`` instances by the ``UploadProcess`` instances.
        let uploadFactory: UploadFactory
        /// Storage to keep session data of running uploads while this application is in suspended or killed.
        //let dataStoreStack: DataStoreStack
        /// Used by the created ``UploadProcess`` to authenticate and authorize uploads with the Cyface data collector.
        let authenticator: Authenticator
        //let sensorValueFileFactory: any SensorValueFileFactory
        //let backgroundUrlSessionEventDelegate: BackgroundURLSessionEventDelegate
        var delegate: BackgroundProcessDelegate?
        var eventHandler: BackgroundEventHandler?

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

        public func add(handler: BackgroundEventHandler) -> any DelegateBuilder {
            self.eventHandler = handler
            return self
        }

        public func add(delegate: BackgroundProcessDelegate) -> any BuildFunction {
            self.delegate = delegate
            return self
        }

        public func build() -> UploadProcess {
            return BackgroundUploadProcess(
                sessionRegistry: sessionRegistry,
                collectorUrl: collectorUrl,
                uploadFactory: uploadFactory,
                authenticator: authenticator,
                urlSession: urlSession,
                eventHandler: eventHandler!,
                eventDelegate: delegate!
            )
        }
    }
}
