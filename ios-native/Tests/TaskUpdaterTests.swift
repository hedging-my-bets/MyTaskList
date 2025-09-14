import XCTest
@testable import SharedKit
@testable import PetProgressWidget

@MainActor
final class TaskUpdaterTests: XCTestCase {

    func testParameterValidation() async throws {
        // Test invalid dayKey
        do {
            try await TaskUpdater.markNextDone(dayKey: "invalid")
            XCTFail("Should have thrown error for invalid dayKey")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "TaskUpdater")
            XCTAssertEqual(nsError.code, 3)
        }

        // Test empty dayKey
        do {
            try await TaskUpdater.markNextDone(dayKey: "")
            XCTFail("Should have thrown error for empty dayKey")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "TaskUpdater")
        }

        // Test invalid taskId for complete
        do {
            try await TaskUpdater.complete(taskId: "invalid-uuid", dayKey: "2025-01-01")
            XCTFail("Should have thrown error for invalid taskId")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "TaskUpdater")
            XCTAssertEqual(nsError.code, 1)
        }

        // Test empty taskId for snooze
        do {
            try await TaskUpdater.snoozeNextTask(taskId: "", dayKey: "2025-01-01")
            XCTFail("Should have thrown error for empty taskId")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "TaskUpdater")
            XCTAssertEqual(nsError.code, 2)
        }
    }

    func testValidParameterFormats() async throws {
        // Valid dayKey formats should not throw
        let validDayKeys = ["2025-01-01", "2024-12-31", "2023-06-15"]

        for dayKey in validDayKeys {
            do {
                // This will fail due to no state, but should not fail validation
                try await TaskUpdater.markNextDone(dayKey: dayKey)
            } catch {
                // Expected to fail due to missing state, not validation
                let nsError = error as NSError
                XCTAssertNotEqual(nsError.code, 3) // Should not be validation error
            }
        }

        // Valid UUID format
        let validUUID = UUID().uuidString
        do {
            try await TaskUpdater.complete(taskId: validUUID, dayKey: "2025-01-01")
        } catch {
            let nsError = error as NSError
            XCTAssertNotEqual(nsError.code, 1) // Should not be validation error
        }
    }

    func testDayKeyRegexValidation() {
        let validDayKeys = ["2025-01-01", "2024-12-31", "2023-02-28", "2000-01-01"]
        let invalidDayKeys = ["2025-1-1", "25-01-01", "2025/01/01", "2025-13-01", "2025-01-32", "abcd-ef-gh"]

        for dayKey in validDayKeys {
            XCTAssertNotNil(dayKey.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression),
                           "Valid dayKey \(dayKey) should match regex")
        }

        for dayKey in invalidDayKeys {
            XCTAssertNil(dayKey.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression),
                        "Invalid dayKey \(dayKey) should not match regex")
        }
    }
}