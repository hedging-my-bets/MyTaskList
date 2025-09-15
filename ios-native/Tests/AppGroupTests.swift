import XCTest
import Foundation
@testable import SharedKit

/// Tests to verify App Group configuration and shared state access
final class AppGroupTests: XCTestCase {

    func testAppGroupAccessible() throws {
        // Test that App Group UserDefaults is accessible
        let appGroupID = "group.com.hedgingmybets.PetProgress"
        let testDefaults = UserDefaults(suiteName: appGroupID)

        XCTAssertNotNil(testDefaults, "App Group UserDefaults should be accessible")

        // Test write/read cycle
        let testKey = "test_key_\(UUID().uuidString)"
        let testValue = "test_value_\(Date().timeIntervalSince1970)"

        testDefaults?.set(testValue, forKey: testKey)
        let retrievedValue = testDefaults?.string(forKey: testKey)

        XCTAssertEqual(retrievedValue, testValue, "Should be able to write and read from App Group storage")

        // Cleanup
        testDefaults?.removeObject(forKey: testKey)
    }

    func testSharedStoreInitialization() throws {
        // Test that SharedStore initializes without crashing
        let store = SharedStore.shared
        XCTAssertNotNil(store, "SharedStore should initialize successfully")
    }

    func testSharedStoreActorInitialization() throws {
        // Test that SharedStoreActor initializes without crashing
        let expectation = expectation(description: "SharedStoreActor initialization")

        Task {
            let actor = SharedStoreActor.shared
            let isHealthy = await actor.healthCheck()
            XCTAssertTrue(isHealthy, "SharedStoreActor should be healthy")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }
}