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
import Combine
import OSLog

/**
 An implementation of the ``SensorCapturer`` protocol, that does nothing.

 This may be used to disable capturing IMU sensor data, if only locations are supposed to be captured.

 - Author: Klemens Muthmann
 */
public class NoOpSensorCapturer: SensorCapturer {
    private var messagePublisher: PassthroughSubject<Message, Never>?

    public init() {
        // Nothing to do here, but we need a public initializer.
    }

    public func start() -> AnyPublisher<Message, Never> {
        let messagePublisher = PassthroughSubject<Message, Never>()
        self.messagePublisher = messagePublisher
        return messagePublisher.eraseToAnyPublisher()
    }
    
    public func stop() {

        if let messagePublisher = messagePublisher {
            os_log(.debug, log: .sensor, "Sending Finished Event from NoOpSensorCapturer!")
            messagePublisher.send(completion: .finished)
        }
        os_log(.info, log: .sensor, "Stopping NoOpSensorCapturer!")
    }
}
