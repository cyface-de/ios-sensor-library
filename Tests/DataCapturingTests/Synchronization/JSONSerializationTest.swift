/*
 * Copyright 2025 Cyface GmbH
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

import Foundation
import Testing
@testable import DataCapturing

struct JSONSerializationTest {

    @Test("Check if converting a MetaData object into JSON works as expected!")
    func convertMetaDataToJSON() async throws {
        // Arrange
        let oocut = MetaData(
            locationCount: 10,
            formatVersion: 2,
            startLocLat: 13.710383608373876,
            startLocLon: 51.04965320667681,
            startLocTS: Date(timeIntervalSince1970: 1737451958.000),
            endLocLat: 13.706960955527796,
            endLocLon: 51.0331973505326,
            endLocTS: Date(timeIntervalSince1970: 1737451958.000),
            measurementId: 2,
            osVersion: "18.1",
            applicationVersion: "13.0.1",
            length: 2_400,
            modality: "BICYCLE"
        )
        let encoder = JSONEncoder()
        let installationIdentifier = installationIdentifier
        let deviceType = modelIdentifier

        // Act
        let jsonOutput = try encoder.encode(oocut)
        let result = try #require(try JSONSerialization.jsonObject(with: jsonOutput) as? [String: Any])

        // Assert
        let appVersion = try #require(result["appVersion"] as? String)
        let locationCount = try #require(result["locationCount"] as? Int)
        let formatVersion = try #require(result["formatVersion"] as? Int)
        let modality = try #require(result["modality"] as? String)
        let length = try #require(result["length"] as? Int)
        let osVersion = try #require(result["osVersion"] as? String)
        let measurementId = try #require(result["measurementId"] as? Int)
        let startLocLat = try #require(result["startLocLat"] as? Double)
        let startLocLon = try #require(result["startLocLon"] as? Double)
        let endLocLat = try #require(result["endLocLat"] as? Double)
        let endLocLon = try #require(result["endLocLon"] as? Double)
        let startLocTS = try #require(result["startLocTS"] as? Int64)
        let endLocTS = try #require(result["endLocTS"] as? Int64)
        let deviceId = try #require(result["deviceId"] as? String)
        let deviceTypeValue = try #require(result["deviceType"] as? String)

        #expect(appVersion == "13.0.1")
        #expect(locationCount == 10)
        #expect(formatVersion == 2)
        #expect(modality == "BICYCLE")
        #expect(length == 2_400)
        #expect(osVersion == "18.1")
        #expect(measurementId == 2)
        #expect(startLocLat == 13.710383608373876)
        #expect(startLocLon == 51.04965320667681)
        #expect(endLocLat == 13.706960955527796)
        #expect(endLocLon == 51.0331973505326)
        #expect(startLocTS == 1737451958000)
        #expect(endLocTS == 1737451958000)
        #expect(deviceId == installationIdentifier)
        #expect(deviceTypeValue == deviceType)
    }

}
