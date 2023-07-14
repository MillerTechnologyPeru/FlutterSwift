// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import AnyCodable // FIXME: remove type erasure
import Foundation

/**
 * Error object representing an unsuccessful outcome of invoking a method
 * on a `FlutterMethodChannel`, or an error event on a `FlutterEventChannel`.
 */
public struct FlutterError: Error, Codable {
    let code: String
    let message: String?
    let details: (any Codable)?

    public init(
        code: String,
        message: String?,
        details: (any Codable)?
    ) {
        self.code = code
        self.message = message
        self.details = details
    }

    // according to FlutterCodecs.mm, errors are encoded as unkeyed arrays
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        code = try container.decode(String.self)
        message = try container.decodeIfPresent(String.self)
        details = try container.decodeIfPresent(AnyCodable.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(code)
        if let message {
            try container.encode(message)
        } else {
            try container.encodeNil()
        }
        if let details {
            try container.encode(AnyCodable(details))
        } else {
            try container.encodeNil()
        }
    }
}
