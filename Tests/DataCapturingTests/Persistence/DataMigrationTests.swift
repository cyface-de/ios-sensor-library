/*
 * Copyright 2019-2024 Cyface GmbH
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

import Testing
import CoreData
import OSLog
@testable import DataCapturing

/**
 Tests that loadin a custom mapping model works. This test is used as a show case for how to load a mapping model. The code is not actually used in the app.
 */
@Test(.disabled("This currently does not work on the terminal and thus in CI."), .tags(.persistence))
func testLoadMappingModel() throws {
    let oldResource = "3"
    let newResource = "4"

    // The DataCapturing bundle is part of the test bundle and needs to be loaded from within its parent bundle directly.
    let dataCapturingBundle = appBundle()

    withKnownIssue("This currently does not work on the terminal and thus in CI.") {
        let oldMomURL = try #require(dataCapturingBundle.url(forResource: oldResource, withExtension: "mom", subdirectory: "CyfaceModel.momd"))
        let newMomURL = try #require(dataCapturingBundle.url(forResource: newResource, withExtension: "mom", subdirectory: "CyfaceModel.momd"))

        let mappingModel = NSMappingModel(from: [dataCapturingBundle], forSourceModel: NSManagedObjectModel(contentsOf: oldMomURL), destinationModel: NSManagedObjectModel(contentsOf: newMomURL))

        try #require(mappingModel != nil)
    }
}

/**
 Tests that data migration between different versions of the Cyface data model are going to work as expected.

 - Author: Klemens Muthmann
 - Version: 1.3.0
 - Since: 4.0.0
 */
@Suite(.serialized, .disabled("This currently does not work on the terminal and thus in CI."), .tags(.persistence))
struct DataMigrationTest {

    var context: NSManagedObjectContext?

    /// Initializes the test environment by cleaning the temporary directory from any files that might have remained from failed previous tests.
    private init() {
        FileManager.clearTempDirectoryContents()
    }

    @Test("Run migration from one version to another and check if the resulting data store contains the correctly migrated data.", arguments: [
        (from: CoreDataMigrationVersion.version1, to: CoreDataMigrationVersion.version2, fileNameOfExampleDatainFromFormat: "V1TestData"),
        (from: CoreDataMigrationVersion.version2, to: CoreDataMigrationVersion.version3, fileNameOfExampleDatainFromFormat: "V2TestData"),
        (from: CoreDataMigrationVersion.version3, to: CoreDataMigrationVersion.version4, fileNameOfExampleDatainFromFormat: "V3TestData"),
        (from: CoreDataMigrationVersion.version4, to: CoreDataMigrationVersion.version5, fileNameOfExampleDatainFromFormat: "V4TestData"),
        (from: CoreDataMigrationVersion.version5, to: CoreDataMigrationVersion.version6, fileNameOfExampleDatainFromFormat: "V5TestData"),
        (from: CoreDataMigrationVersion.version6, to: CoreDataMigrationVersion.version7, fileNameOfExampleDatainFromFormat: "V6TestData"),
        //(from: CoreDataMigrationVersion.version1, to: CoreDataMigrationVersion.version4, fileNameOfExampleDatainFromFormat: "V1TestData"),
        (from: CoreDataMigrationVersion.version1, to: CoreDataMigrationVersion.version5, fileNameOfExampleDatainFromFormat: "V1TestData"),
        (from: CoreDataMigrationVersion.version9, to: CoreDataMigrationVersion.version10, fileNameOfExampleDatainFromFormat: "V9TestData"),
        (from: CoreDataMigrationVersion.version10, to: CoreDataMigrationVersion.version11, fileNameOfExampleDatainFromFormat: "V10TestData"),
        (from: CoreDataMigrationVersion.version11, to: CoreDataMigrationVersion.version12, fileNameOfExampleDatainFromFormat: "V11TestData"),
        (from: CoreDataMigrationVersion.version12, to: CoreDataMigrationVersion.version13, fileNameOfExampleDatainFromFormat: "V12TestData")
        ]
    )
    mutating func testMigration(
        from: CoreDataMigrationVersion,
        to: CoreDataMigrationVersion,
        fileNameOfExampleDatainFromFormat: String
    ) throws {
        // Arrange, Act
        withKnownIssue("Run migration from one version to another and check if the resulting data store contains the correctly migrated data.") {
            let context = try #require(try migrate(
                fromVersion: from,
                toVersion: to,
                usingTestData: fileNameOfExampleDatainFromFormat
            ))

            // Assert
            switch to {
            case .version1:
                break
            case .version2:
                try V2Asserter().assert(context: context)
            case .version3:
                try V3Asserter().assert(context: context)
            case .version4:
                try V4Asserter(firstLocationCount: 300, secondLocationCount: 200).assert(context: context)
            case .version5:
                try V5Asserter().assert(context: context)
            case .version6:
                try V6Asserter().assert(context: context)
            case .version7:
                try V7Asserter().assert(context: context)
            case .version8:
                break
            case .version9:
                break
            case .version10:
                try V10Asserter().assert(context: context)
            case .version11:
                try V11Asserter().assert(context: context)
            case .version12:
                try V12Asserter().assert(context: context)
            case .version13:
                try V13Asserter().assert(context: context)
            }

            FileManager.clearTempDirectoryContents()
            context.destroyStore()
        }
    }

    /**
     Migrates a test data store `fromVersion` to a not necessarily consecutive `toVersion` using a pregenerated data store as test data.

     - Parameters:
        - fromVersion: The version of the provided pregenerated data store used as input
        - toVersion: The version to migrate the pregenerated data store to
        - usingTestData: The test data store to migrate to
     - Returns: The `NSManagedObjectContext` on the migrated data store.
     */
    mutating func migrate(fromVersion: CoreDataMigrationVersion, toVersion: CoreDataMigrationVersion, usingTestData testDatastore: String) throws -> NSManagedObjectContext? {
        // Arrange
        let migrator = CoreDataMigrator(to: toVersion)
        let bundle = appBundle()
        // The tmp folder will be cleared by deinit after each test execution
        let datastore = FileManager.move(file: testDatastore, fromBundle: testBundle()!)
        let requiresMigration = try migrator.requiresMigration(at: datastore, inBundle: bundle)
        try #require(requiresMigration)

        // Act
        try migrator.migrateStore(at: datastore, inBundle: bundle)

        // Assert
        try #require(try datastore.checkPromisedItemIsReachable())

        let model = try NSManagedObjectModel.managedObjectModel(forResource: toVersion.rawValue, inBundle: bundle, withModelName: "CyfaceModel")
        // This context is going to be destroyed by tear down
        self.context = NSManagedObjectContext(model: model, storeURL: datastore)

        return context
    }

    /**
     A test used to create an input data storeage file used by other tests. This is skipped since it is usually only required to run once when a new version of the Cyface data model is released.

     - Throws:
        - Unspecified *CoreData* errors on saving of the data model.
     */
    /*func skip_testExample() throws {
        let dataModelVersion = "12"
        let dataSetCreator = DataSetCreatorV12()

        let bundle = Bundle.module

        let migrator = CoreDataMigrator()
        let location = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let database = location.appendingPathComponent("V\(dataModelVersion)TestData").appendingPathExtension("sqlite")
        let container = loadContainer(from: "CyfaceModel", path: "DataCapturing_DataCapturing.bundle", with: dataModelVersion, at: database)
        try dataSetCreator.createData(in: container)

        for store in container.persistentStoreCoordinator.persistentStores {
            try container.persistentStoreCoordinator.remove(store)
        }
        migrator.forceWALCheckpointingForStore(at: database, inBundle: bundle)
        print("Written Version \(dataModelVersion) to \(location)!")
    }*/

    /**
     Loads an `NSPersistentContainer` with a model in a specific version from a store at the provided location inside the provided bundle.

     - Parameters:
        - from: The data model to load from
        - path: A subpath if the model is embedded within its bundle. To find out, please have a look at the actual location of your data model.
        - with: The version of the data model to load
        - at: The location of the storage file (usually an SQLite file
     - Returns: The loaded `NSPersistentContainer`
     */
    /*func loadContainer(from model: String, path: String, with version: String, at location: URL) -> NSPersistentContainer {
        let modelURL = Bundle.module.url(forResource: "\(path)/\(model)", withExtension: "momd")
        let managedObjectModelBundle = Bundle(url: modelURL!)
        let managedObjectModelVersionURL = managedObjectModelBundle?.url(forResource: version, withExtension: "mom")

        let managedObjectModel = NSManagedObjectModel.init(contentsOf: managedObjectModelVersionURL!)!

        let container = NSPersistentContainer(name: model, managedObjectModel: managedObjectModel)

        let description = NSPersistentStoreDescription()
        description.type = NSSQLiteStoreType
        description.url = location
        description.shouldInferMappingModelAutomatically = false
        description.shouldMigrateStoreAutomatically = false
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { (_, _) in
            // Nothing to do here
        }
        return container
    }*/

}

extension FileManager {

    // MARK: - Temp

    /// Removes everything from the temporary directory.
    static func clearTempDirectoryContents() {
        guard let tmpDirectoryContents = try? FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory()) else {
            fatalError()
        }
        tmpDirectoryContents.forEach {
            let fileURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent($0)
            try? FileManager.default.removeItem(atPath: fileURL.path)
        }
    }

    /**
     Moves the provided file to a temporary directory and provides a URL pointing to the new location.

     - Parameter filename: The name of the file to move
     - Returns: A `URL` pointing to the new files new location inside the temporary directory.
     */
    static func move(file filename: String, fromBundle bundle: Bundle, to: String = NSTemporaryDirectory()) -> URL {
        let destinationURL = URL(fileURLWithPath: to, isDirectory: true).appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: destinationURL)
        // The actual test bundle containing the relevant resources is bundled in some xctest meta bundle. To get the required files we need to unwrap that.
        let bundleURL = bundle.url(forResource: filename, withExtension: "sqlite")!
        do {
            try FileManager.default.copyItem(at: bundleURL, to: destinationURL)
        } catch {
            fatalError("""
            Unable to copy test data from \(bundleURL) to \(destinationURL).
            Reason: \(error)
            File Exists: \(FileManager.default.fileExists(atPath: bundleURL.absoluteString))
            """)
        }

        return destinationURL
    }
}

extension NSManagedObjectContext {

    // MARK: - Initializers

    /**
     Creates a `NSManagedObjectContext` based on its model and a store location. The file at the `storeURL` must of course be compatible with the provided `NSManagedObjectModel`.

     - Parameters:
        - model: The model to create the context for
        - storeURL: The URL of a store file compatible to the provided model. This will become the parent of this context.
     */
    convenience init(model: NSManagedObjectModel, storeURL: URL) {
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
        } catch {
            fatalError("\(error)")
        }

        self.init(concurrencyType: .mainQueueConcurrencyType)

        self.persistentStoreCoordinator = persistentStoreCoordinator
    }

    // MARK: - Destroy

    /**
     Closes and destroyes all stores.
     */
    func destroyStore() {
        persistentStoreCoordinator?.persistentStores.forEach {
            ((try? persistentStoreCoordinator?.remove($0)) as ()??)
            ((try? persistentStoreCoordinator?.destroyPersistentStore(at: $0.url!, ofType: $0.type, options: nil)) as ()??)
        }
    }
}

protocol Asserter {
    func assert(context: NSManagedObjectContext) throws
}

struct V2Asserter: Asserter {

    func assert(context: NSManagedObjectContext) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Measurement")

        let migratedMeasurements = try context.fetch(request)

        try #require(migratedMeasurements.count == 2)
        try #require(migratedMeasurements.first?.value(forKeyPath: "context") != nil)
        try #require(migratedMeasurements.first?.value(forKeyPath: "context") as? String == "BICYCLE")
    }
}

struct V3Asserter: Asserter {

    func assert(context: NSManagedObjectContext) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Measurement")

        let migratedMeasurements = try context.fetch(request)

        try #require(migratedMeasurements.count == 2)
        try #require(migratedMeasurements.first?.primitiveValue(forKey: "accelerationCount") as? Int == 0)
    }
}

struct V4Asserter: Asserter {
    let firstLocationCount: Int
    let secondLocationCount: Int

    func assert(context: NSManagedObjectContext) throws {
        let measurementFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Measurement")
        let sort = NSSortDescriptor(key: "identifier", ascending: false)
        measurementFetchRequest.sortDescriptors = [sort]
        let trackFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Track")
        let migratedMeasurements = try context.fetch(measurementFetchRequest)

        try #require(migratedMeasurements.count == 2)
        try #require(migratedMeasurements[0].primitiveValue(forKey: "identifier") as? Int64 == Int64(2))
        try #require(migratedMeasurements[1].primitiveValue(forKey: "identifier") as? Int64 == Int64(1))
        let tracksFromFirstMeasurement = try #require(migratedMeasurements[0].value(forKey: "tracks") as? NSOrderedSet, "Unable to load tracks from the first migrated measurement!")
        let tracksFromSecondMeasurement = try #require(migratedMeasurements[1].value(forKey: "tracks") as? NSOrderedSet)
        try #require(tracksFromFirstMeasurement.count == 1)
        try #require(tracksFromSecondMeasurement.count == 1)

        let tracks = try context.fetch(trackFetchRequest)
        try #require(tracks.count == 2)

        let trackOne = try #require(tracksFromFirstMeasurement.firstObject as? NSManagedObject, "Unable to load track from first migrated measurement!")
        let trackTwo = try #require(tracksFromSecondMeasurement.firstObject as? NSManagedObject, "Unable to load track from second migrated measurement!")
        let locationsFromTrackOne = try #require(trackOne.value(forKey: "locations") as? NSOrderedSet, "Unable to load geo locations from first track!")
        let locationsFromTrackTwo = try #require(trackTwo.value(forKey: "locations") as? NSOrderedSet, "Unable to load geo locations from second track!")
        try #require(locationsFromTrackOne.count == firstLocationCount)
        try #require(locationsFromTrackTwo.count == secondLocationCount)
    }
}

struct V5Asserter: Asserter {

    func assert(context: NSManagedObjectContext) throws {
        let measurementFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Measurement")
        let sort = NSSortDescriptor(key: "identifier", ascending: false)
        measurementFetchRequest.sortDescriptors = [sort]
        let migratedMeasurements = try context.fetch(measurementFetchRequest)

        try #require(migratedMeasurements.count == 2)
        #expect(try #require(migratedMeasurements[0].primitiveValue(forKey: "synchronizable") as? Bool))
        #expect(try #require(migratedMeasurements[1].primitiveValue(forKey: "synchronizable") as? Bool))
    }
}

struct V6Asserter: Asserter {

    func assert(context: NSManagedObjectContext) throws {
        let geoLocationFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "GeoLocation")
        let migratedGeoLocations = try context.fetch(geoLocationFetchRequest)

        #expect(migratedGeoLocations[0].primitiveValue(forKey: "isPartOfCleanedTrack") as! Bool)
    }
}

struct V7Asserter: Asserter {

    func assert(context: NSManagedObjectContext) throws {
        let measurementFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Measurement")
        let migratedMeasurements = try context.fetch(measurementFetchRequest)

        try #require(migratedMeasurements.count == 2)
        let events01 = (migratedMeasurements[0].value(forKey: "events") as! NSOrderedSet).array
        try #require(events01.count == 0)
        let events02 = (migratedMeasurements[1].value(forKey: "events") as! NSOrderedSet).array
        try #require(events02.count == 0)
    }
}

struct V10Asserter: Asserter {

    func assert(context: NSManagedObjectContext) throws {
        let measurementFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Measurement")
        let migratedMeasurements = try context.fetch(measurementFetchRequest)

        try #require(migratedMeasurements.count > 0)
        // All the counts have been removed for this version.
        #expect(migratedMeasurements[0].entity.attributesByName.keys.filter {$0=="accelerationsCount"}.isEmpty)
        #expect(migratedMeasurements[0].entity.attributesByName.keys.filter {$0=="rotationsCount"}.isEmpty)
        #expect(migratedMeasurements[0].entity.attributesByName.keys.filter {$0=="directionsCount"}.isEmpty)
    }
}

struct V11Asserter: Asserter {

    func assert(context: NSManagedObjectContext) throws {
        let measurementFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Measurement")
        let migratedMeasurements = try context.fetch(measurementFetchRequest)
        // Timestamps on GeoLocation and Measurement should be proper Date instances now
        try #require(migratedMeasurements.count > 0)
        #expect(migratedMeasurements[0].value(forKey: "time") is Date)
        // Now find the first `GeoLocation` and check it for having a proper `Date` as a timestamp.
        let tracks = try #require(migratedMeasurements[0].value(forKey: "tracks") as? NSOrderedSet)
        try #require(tracks.count > 0)
        let firstTrack = try #require(tracks.firstObject as? NSManagedObject)
        let locations = try #require(firstTrack.value(forKey: "locations") as? NSOrderedSet)
        try #require(locations.count > 0)
        let firstLocation = try #require(locations.firstObject as? NSManagedObject)
        try #require(firstLocation.value(forKey: "time") is Date)
    }
}

struct V12Asserter: Asserter {

    func assert(context: NSManagedObjectContext) throws {
        // trackLength and isPartOfCleanedTrack should be gone
        let measurementFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Measurement")
        let migratedMeasurements = try context.fetch(measurementFetchRequest)

        try #require(migratedMeasurements.count == 2)
        #expect(migratedMeasurements[0].entity.attributesByName.keys.filter {$0=="trackLength"}.isEmpty)
        #expect(migratedMeasurements[0].entity.attributesByName.keys.filter {$0=="isPartOfCleanedTrack"}.isEmpty)
    }
}

struct V13Asserter: Asserter {

    func assert(context: NSManagedObjectContext) throws {
        #expect(try context.fetch(UploadSession.fetchRequest()).count == 0)
        #expect(try context.fetch(UploadTask.fetchRequest()).count == 0)
    }
}
