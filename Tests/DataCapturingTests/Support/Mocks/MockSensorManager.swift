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
import CoreMotion

/**
 A `CMMotionManager` that avoids accessing the actual sensors, but simulates sensor values with an asynchronous timer in the background.
 */
class MockSensorManager: CMMotionManager {

    override var isAccelerometerAvailable: Bool { true }
    override var isDeviceMotionAvailable: Bool { true }
    override var isGyroAvailable: Bool { true }
    var gyroTimer: DispatchSourceTimer?
    var deviceMotionTimer: DispatchSourceTimer?
    var accelerometerTimer: DispatchSourceTimer?
    let beginningTime = Date()

    override func startAccelerometerUpdates(to queue: OperationQueue, withHandler handle: @escaping CMAccelerometerHandler) {
        accelerometerTimer = DispatchSource.makeTimerSource(queue: queue.underlyingQueue)
        accelerometerTimer?.setEventHandler { [weak self] in
            if let self = self {
                let data = MockedAccelerometerData(x: 1.0, y: 1.0, z: 1.0, timestamp: Date().timeIntervalSince(beginningTime))
                handle(data, nil)
            }
        }
        accelerometerTimer?.schedule(deadline: .now(), repeating: .seconds(1))
        accelerometerTimer?.resume()
    }

    override func startGyroUpdates(to queue: OperationQueue, withHandler handle: @escaping CMGyroHandler) {
        gyroTimer = DispatchSource.makeTimerSource(queue: queue.underlyingQueue)
        gyroTimer?.setEventHandler { [weak self] in
            if let self = self {
                let data = MockedGyroData(x: 1.0, y: 1.0, z: 1.0, timestamp: Date().timeIntervalSince(beginningTime))
                handle(data, nil)
            }
        }
        gyroTimer?.schedule(deadline: .now(), repeating: .seconds(1))
        gyroTimer?.resume()
    }

    override func startDeviceMotionUpdates(using referenceFrame: CMAttitudeReferenceFrame, to queue: OperationQueue, withHandler handle: @escaping CMDeviceMotionHandler) {
        deviceMotionTimer = DispatchSource.makeTimerSource(queue: queue.underlyingQueue)
        deviceMotionTimer?.setEventHandler { [weak self] in
            if let self = self {
                let data = MockedDeviceMotion(x: 1.0, y: 1.0, z: 1.0, timestamp: Date().timeIntervalSince(beginningTime))
                handle(data, nil)
            }
        }
        deviceMotionTimer?.schedule(deadline: .now(), repeating: .seconds(1))
        deviceMotionTimer?.resume()
    }

    override func stopAccelerometerUpdates() {
        accelerometerTimer?.cancel()
    }

    override func stopGyroUpdates() {
        gyroTimer?.cancel()
    }

    override func stopDeviceMotionUpdates() {
        deviceMotionTimer?.cancel()
    }
}

class MockedAccelerometerData: CMAccelerometerData {

    let _acceleration: CMAcceleration
    let _timestamp: TimeInterval

    init(x: Double, y: Double, z: Double, timestamp: TimeInterval) {
        self._acceleration = CMAcceleration(x: x, y: y, z: z)
        self._timestamp = timestamp
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var timestamp: TimeInterval {
        _timestamp
    }

    override var acceleration: CMAcceleration {
        _acceleration
    }
}

class MockedGyroData: CMGyroData {
    let _rotationRate: CMRotationRate
    let _timestamp: TimeInterval

    init(x: Double, y: Double, z: Double, timestamp: TimeInterval) {
        _rotationRate = CMRotationRate(x: x, y: y, z: z)
        _timestamp = timestamp
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var rotationRate: CMRotationRate {
        _rotationRate
    }

    override var timestamp: TimeInterval {
        _timestamp
    }
}

class MockedDeviceMotion: CMDeviceMotion {
    let _deviceMotion: CMCalibratedMagneticField
    let _timestamp: TimeInterval

    init(x: Double, y: Double, z: Double, timestamp: TimeInterval) {
        _deviceMotion = CMCalibratedMagneticField(field: CMMagneticField(x: x, y: y, z: z), accuracy: .high)
        _timestamp = timestamp
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var magneticField: CMCalibratedMagneticField {
        _deviceMotion
    }

    override var timestamp: TimeInterval {
        _timestamp
    }
}
