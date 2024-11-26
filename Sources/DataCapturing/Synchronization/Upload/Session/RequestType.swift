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

/**
 An enumeration of all the HTTP request types used by the Google Media Uploda protocol.

 This type serves to make a list of all the interactions with the Cyface Data Collector server during a single session as well as a mapping from enumeration to number.
 The number is used to store this enumeration to persistent data storage.

 - Author: Klemens Muthmann
 */
public enum RequestType: Int16 {
    /// A Google Media Upload Protocol status request.
    case status = 0
    /// A Google Media Upload Protocol pre request.
    case prerequest = 1
    /// A Google Media Upload Protocol upload request.
    case upload = 2
}
