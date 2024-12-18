/*
 * Copyright 2023-2024 Cyface GmbH
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
import Combine
import OSLog
import CoreData

/**
 Protocol for a storage process for captured sensor data.

 Implementations of this protocol are capable of storing captured data to some kind of permanent storage.
 Since it can happen, that the iOS System shuts down an application, which is in the background, it is possible that an app with a paused measurement is getting shut down.
 To recreate such a measurement, when the application comes back online use `pausedMeasurement(:SensorCapturer:LocationCapturer:(UInt64) -> Void) -> Measurement?`.

 - author: Klemens Muthmann
 */
public protocol CapturedDataStorage {
    /// Subscribe to a running measurement and store the data produced by that measurement.
    ///
    /// You may provide clean up operations as part of `receiveCompletion`.
    /// That block is called after all the data is stored to the database.
    ///  - Returns: The application wide unique identifier under which the new measurement is stored in the database.
    func subscribe(
        to measurement: Measurement,
        _ initialMode: String,
        _ receiveCompletion: @escaping ((_ databaseIdentifier: UInt64) async -> Void)) throws -> UInt64
    /// Stop receiving updates from the currently subscribed measurement or do nothing if this was not subscribed at the moment.
    func unsubscribe()

    /**
     If there is a previously paused measurement, this function recreates that measurement from the database, to enable resume after the app was killed.

     You may provide clean up operations as part of `receiveCompletion`.
     That block is called after all the data is stored to the database.
     */
    func pausedMeasurement(sensorCapturer: SensorCapturer, locationCapturer: LocationCapturer, _ receiveCompletion: @escaping ((_ databaseIdentifier: UInt64) async -> Void)) throws -> Measurement?
}

/**
 An implementation of `CapturedDataStorage` for storing the data to a CoreData database.

 - author: Klemens Muthmann
 */
public class CapturedCoreDataStorage<SVFF: SensorValueFileFactory> where SVFF.Serializable == [SensorValue] {
    // MARK: - Properties
    /// The `DataStoreStack` to write the captured data to.
    let dataStoreStack: DataStoreStack
    /// A queue used to buffer received data until writing it as a bulk for performance reasons.
    let cachingQueue = DispatchQueue(label: "de.cyface.cache")
    /// The time interval to wait until the next batch of data is stored to the data storage. Increasing this time should improve performance but increases memory usage.
    let interval: TimeInterval
    /// The *Combine* cancellables used so new values are transmitted. References to this must be kept here, so that *Combine* does not stop the data flow.
    var cancellables = [AnyCancellable]()
    /// Creator for storing sensor values to a file.
    let sensorValueFileFactory: SVFF
    /// A Publisher of messages sent by the persistence layer on storage events.
    let persistenceMessages = PassthroughSubject<Message, Never>()

    // MARK: - Initializers
    /**
     - Parameter interval: The time interval to wait until the next batch of data is stored to the data storage. Increasing this time should improve performance but increases memory usage.
     */
    public init(
        _ dataStoreStack: DataStoreStack,
        _ interval: TimeInterval,
        _ sensorValueFileFactory: SVFF
    ) {
        self.dataStoreStack = dataStoreStack
        self.interval = interval
        self.sensorValueFileFactory = sensorValueFileFactory
    }

    // MARK: - Private Methods
    /// Create a new measurement within the data store.
    private func createMeasurement(_ initialMode: String) throws -> UInt64 {
        return try dataStoreStack.wrapInContextReturn { context in
            let time = Date()
            let measurementMO = MeasurementMO(context: context)
            measurementMO.time = time
            let identifier = try dataStoreStack.nextValidIdentifier()
            measurementMO.identifier = Int64(identifier)
            measurementMO.synchronized = false
            measurementMO.synchronizable = false
            measurementMO.addToEvents(EventMO(event: Event(time: time, type: .modalityTypeChange, value: initialMode), context: context))
            try context.save()
            return identifier
        }
    }

    private func _subscribe(to measurement: Measurement, _ measurementIdentifier: UInt64,_ receiveCompletion: @escaping ((_ databaseIdentifier: UInt64) async -> Void)) throws {
        let messageHandler = try MessageHandler(fileFactory: sensorValueFileFactory, measurementIdentifier: measurementIdentifier, dataStoreStack: dataStoreStack)

        let cachedFlow = measurement.events.collect(.byTime(cachingQueue, 1.0))
        cachedFlow.sink(receiveCompletion: { status in
            switch status {
            case .finished:
                os_log(
                    "Completing storage flow.",
                    log: OSLog.persistence,
                    type: .debug
                )
                Task {
                    await receiveCompletion(measurementIdentifier)
                }
            case .failure(let error):
                os_log("Unable to complete measurement %@", log: OSLog.persistence, type: .error, error.localizedDescription)
            }
        }) { messages in
            do {
                try messageHandler.handle(messages: messages)
            } catch {
                os_log("Unable to store data! Error %{PUBLIC}@", log: OSLog.persistence, type: .error, error.localizedDescription)
            }
        }.store(in: &cancellables)
    }
}

// MARK: - Implementation of CapturedDataStorage Protocol
extension CapturedCoreDataStorage: CapturedDataStorage {

    /// Recievie updates from the provided ``Measurement`` and store the data to a ``DataStoreStack``.
    public func subscribe(
        to measurement: Measurement,
        _ initialMode: String,
        _ receiveCompletion: @escaping ((_ databaseIdentifier: UInt64) async -> Void)
    ) throws -> UInt64 {
        let measurementIdentifier = try createMeasurement(initialMode)
        try _subscribe(to: measurement, measurementIdentifier, receiveCompletion)
        return measurementIdentifier
    }

    public func unsubscribe() {
        cancellables.removeAll(keepingCapacity: true)
    }

    public func pausedMeasurement(
        sensorCapturer: any SensorCapturer,
        locationCapturer: any LocationCapturer,
        _ receiveCompletion: @escaping ((_ databaseIdentifier: UInt64) async -> Void)
    ) throws -> (any Measurement)? {
        return try dataStoreStack.wrapInContextReturn { context in
            let request = MeasurementMO.fetchRequest()
            request.predicate = NSPredicate(format: "synchronizable == false && synchronized == false")
            request.sortDescriptors = [NSSortDescriptor(key: "time", ascending: false)]

            if let serializedMeasurement = try request.execute().first {
                let measurement = MeasurementImpl(sensorCapturer: sensorCapturer, locationCapturer: locationCapturer)
                measurement.isPaused = true
                try self._subscribe(to: measurement, serializedMeasurement.unsignedIdentifier, receiveCompletion)
                return measurement
            } else {
                return nil
            }
        }
    }
}

/**
 Used to process messages received during an active `Measurement`.
 */
struct MessageHandler<SVFF: SensorValueFileFactory> where SVFF.Serializable == [SensorValue] {
    // MARK: - Properties
    /// The identifier of the currently active measurement.
    public let measurementIdentifier: UInt64
    /// A file to store acceleration values to.
    public let accelerationsFile: SVFF.FileType
    /// A file to store rotation values to.
    public let rotationsFile: SVFF.FileType
    /// A file to store direction values to.
    public let directionsFile: SVFF.FileType
    /// Connection to data storage to store captured results to.
    let dataStoreStack: DataStoreStack

    // MARK: - Initializers
    init(fileFactory: SVFF, measurementIdentifier: UInt64, dataStoreStack: DataStoreStack) throws {
        self.dataStoreStack = dataStoreStack
        self.measurementIdentifier = measurementIdentifier
        self.accelerationsFile = try fileFactory.create(
             fileType: SensorValueFileType.accelerationValueType,
             qualifier: String(measurementIdentifier)
        )
        self.rotationsFile = try fileFactory.create(
             fileType: SensorValueFileType.rotationValueType,
             qualifier: String(measurementIdentifier)
        )
        self.directionsFile = try fileFactory.create(
            fileType: SensorValueFileType.directionValueType,
            qualifier: String(measurementIdentifier)
        )
    }

    // MARK: - Methods

    func handle(messages: [Message]) throws {
        try self.dataStoreStack.wrapInContext { context in
            let measurementMo = try self.load(measurement: measurementIdentifier, from: context)

            try messages.forEach { message in
                switch message {
                case .capturedLocation(let location):
                    self.store(location: location, to: measurementMo, context)
                case .capturedAltitude(let altitude):
                    self.store(altitude: altitude, to: measurementMo, context)
                case .capturedRotation(let rotation):
                    try self.store(rotation, to: rotationsFile)
                case .capturedDirection(let direction):
                    try self.store(direction, to: directionsFile)
                case .capturedAcceleration(let acceleration):
                    try self.store(acceleration, to: accelerationsFile)
                case .started(timestamp: let time):
                    os_log("Storing started event to database.", log: OSLog.persistence, type: .debug)
                    measurementMo.addToTracks(TrackMO(context: context))
                    measurementMo.addToEvents(EventMO(event: Event(time: time, type: .lifecycleStart), context: context))
                case .resumed(timestamp: let time):
                    measurementMo.addToTracks(TrackMO(context: context))
                    measurementMo.addToEvents(EventMO(event: Event(time: time, type: .lifecycleResume), context: context))
                case .paused(timestamp: let time):
                    measurementMo.addToEvents(EventMO(event: Event(time: time, type: .lifecyclePause), context: context))
                case .stopped(timestamp: let time):
                    try self.onStop(measurement: measurementMo, context, time)
                default:
                    os_log("Message %{PUBLIC}@ irrelevant for data storage and thus ignored.",log: OSLog.persistence, type: .debug, message.description)
                }
            }

            try context.save()
        }
    }

    // MARK: - Private Methods
    /// Load a measurement from the database. This should only be executed within a valid CoreData context.
    private func load(measurement identifier: UInt64, from context: NSManagedObjectContext) throws -> MeasurementMO {
        guard let measurementRequest = context.persistentStoreCoordinator?.managedObjectModel.fetchRequestFromTemplate(
            withName: "measurementByIdentifier",
            substitutionVariables: ["identifier": identifier]
        ) else {
            os_log(
                "Unable to load measurement fetch request.",
                log: OSLog.persistence,
                type: .debug
            )
            throw PersistenceError.measurementNotLoadable(identifier)
        }
        guard let measurementMO = try measurementRequest.execute().first as? MeasurementMO else {
            os_log(
                "Unable to load measurement to store to",
                log: OSLog.persistence,
                type: .debug
            )
            throw PersistenceError.measurementNotLoadable(identifier)
        }

        return measurementMO
    }

    /// Store a ``GeoLocation`` to the database.
    ///
    /// - Parameter location: The location to store.
    /// - Parameter measurementMo: The measurement to store the location to.
    private func store(location: GeoLocation, to measurementMo: MeasurementMO, _ context: NSManagedObjectContext) {
        os_log("Storing location to database.", log: OSLog.persistence, type: .debug)
        if let lastTrack = measurementMo.typedTracks().last {
            lastTrack.addToLocations(GeoLocationMO(location: location, context: context))
        }
    }

    /// Store an ``Altitude`` to the database.
    ///
    /// - Parameter altitude: The altitude to store.
    /// - Parameter measurementMo: The measurement to store the altitude to.
    private func store(altitude: Altitude, to measurementMo: MeasurementMO, _ context: NSManagedObjectContext) {
        if let lastTrack = measurementMo.typedTracks().last {
            lastTrack.addToAltitudes(AltitudeMO(altitude: altitude, context: context))
        }
    }

    /// Store a sensor value (e.g. direction, rotation, acceleration) to a file on the local disk.
    ///
    /// - Parameter value: The value to store to the file.
    /// - Parameter to: The file to store the value to.
    private func store<SVF: FileSupport>(_ value: SensorValue, to file: SVF) throws where SVF.Serializable == SVFF.Serializable {
        do {
            _ = try file.write(serializable: [value])
        } catch {
            debugPrint("Unable to write data to file \(file.qualifiedPath)!")
            throw error
        }
    }

    /// Callback, called when the measurement has been stopped and all values have been stored.
    ///
    /// - Parameter measurement: The measurement that was finished.
    /// - Parameter context: The database context used to communicate with the database.
    /// - Parameter time: The time for the final stop event.
    /// - Attention: Only call this within a valid CoreData context (same thread as the one that opened the provided context).
    private func onStop(measurement measurementMo: MeasurementMO, _ context: NSManagedObjectContext, _ time: Date) throws {
        os_log("Storing stopped event to database.", log: OSLog.persistence, type: .debug)
        measurementMo.addToEvents(EventMO(event: Event(time: time, type: .lifecycleStop), context: context))
        measurementMo.synchronizable = true
        try context.save()
        os_log("Stored finished measurement.", log: OSLog.persistence, type: .debug)
    }
}
