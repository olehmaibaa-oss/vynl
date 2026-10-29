//
//  InfoPlistTests.swift
//  vynlTests
//
//  SCRUM-40: iOS kills an app that opens the camera without a usage string.
//  The simulator has no real camera, so nothing else would notice it missing.
//

import Foundation
import Testing
@testable import vynl

struct InfoPlistTests {

    @Test func cameraUsageDescriptionIsSet() throws {
        let text = try #require(Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") as? String)
        #expect(!text.trimmingCharacters(in: .whitespaces).isEmpty)
    }
}
