//
//  SubscriptionStateTests.swift
//  ClaudeIslandTests
//
//  Coverage for SubscriptionState — the server-truth model that
//  drives the Pair Phone banner. Two ingestion paths feed it:
//  GET /v1/subscription/status (initial fetch) and the socket
//  "subscription-updated" event (live push). Both use the same
//  field names; this file pins those names down so a server-side
//  rename breaks at test time, not in production.
//
//  Banner correctness invariants under test:
//    - Status enum maps to the 4 server values exactly
//    - isActive correctly distinguishes trial/active from expired/none
//    - daysLeftDisplay prefers server-computed daysLeft, falls back
//      to local ceil(expiresAt - now / 86400) when server omits it
//    - JSON ingestion handles missing optional fields gracefully
//    - RedemptionRecord → SubscriptionState construction matches
//      the server's "status:'trial', source:'redeem_code'" contract
//

import XCTest
@testable import ClaudeIsland

final class SubscriptionStateTests: XCTestCase {

    // MARK: - Status parsing

    func test_status_allFourValuesParse() {
        // Server contract: status is one of these 4. If server adds a
        // 5th, init?(serverPayload:) returns nil → SyncManager logs
        // and keeps prior state. Better than guessing.
        for raw in ["trial", "active", "expired", "none"] {
            let state = SubscriptionState(serverPayload: ["status": raw])
            XCTAssertNotNil(state, "status '\(raw)' should parse")
        }
    }

    func test_status_unknownValueFailsInit() {
        let state = SubscriptionState(serverPayload: ["status": "future_unknown_status"])
        XCTAssertNil(state, "unknown status should fail init, not default to .none")
    }

    func test_status_missingFailsInit() {
        let state = SubscriptionState(serverPayload: [:])
        XCTAssertNil(state, "missing status should fail init")
    }

    // MARK: - isActive

    func test_isActive_trialFutureExpiry() {
        let s = SubscriptionState(
            status: .trial,
            expiresAt: Date().addingTimeInterval(3600),
            daysLeft: 1,
            source: nil
        )
        XCTAssertTrue(s.isActive)
    }

    func test_isActive_trialPastExpiry() {
        let s = SubscriptionState(
            status: .trial,
            expiresAt: Date().addingTimeInterval(-3600),
            daysLeft: 0,
            source: nil
        )
        XCTAssertFalse(s.isActive, "expired trial should NOT be active")
    }

    func test_isActive_activeStatusAlwaysTrue() {
        // Lifetime IAP — no expiresAt needed.
        let s = SubscriptionState(status: .active, expiresAt: nil, daysLeft: nil, source: "iap")
        XCTAssertTrue(s.isActive)
    }

    func test_isActive_expiredStatusFalse() {
        let s = SubscriptionState(status: .expired, expiresAt: nil, daysLeft: nil, source: nil)
        XCTAssertFalse(s.isActive)
    }

    func test_isActive_noneStatusFalse() {
        // Pre-F4 server short-circuits Mac to {status:'none'} —
        // this case is the most common in early production.
        let s = SubscriptionState(status: .none, expiresAt: nil, daysLeft: nil, source: nil)
        XCTAssertFalse(s.isActive)
    }

    // MARK: - daysLeftDisplay

    func test_daysLeftDisplay_prefersServerValue() {
        // Server's daysLeft is authoritative — don't second-guess it,
        // even if our local clock would compute a different number
        // (avoids Mac/iPhone showing different N for the same trial).
        let s = SubscriptionState(
            status: .trial,
            expiresAt: Date().addingTimeInterval(7 * 86400),
            daysLeft: 5,  // server says 5, not 7
            source: nil
        )
        XCTAssertEqual(s.daysLeftDisplay, 5)
    }

    func test_daysLeftDisplay_localCeilFallback() {
        // No server number — fall back to local ceil(secs/86400). 18
        // hours = 1 calendar day in user-facing copy.
        let s = SubscriptionState(
            status: .trial,
            expiresAt: Date().addingTimeInterval(18 * 3600),
            daysLeft: nil,
            source: nil
        )
        XCTAssertEqual(s.daysLeftDisplay, 1)
    }

    func test_daysLeftDisplay_zeroForPastExpiry() {
        let s = SubscriptionState(
            status: .trial,
            expiresAt: Date().addingTimeInterval(-3600),
            daysLeft: nil,
            source: nil
        )
        XCTAssertEqual(s.daysLeftDisplay, 0)
    }

    func test_daysLeftDisplay_zeroForActiveLifetime() {
        // Lifetime IAP has no expiry → no day count to display.
        let s = SubscriptionState(status: .active, expiresAt: nil, daysLeft: nil, source: nil)
        XCTAssertEqual(s.daysLeftDisplay, 0)
    }

    // MARK: - JSON ingestion (server payload)

    func test_serverPayload_fullTrialPayloadIngested() {
        // Realistic shape post-F4 server fetch + post-F2 socket push.
        let payload: [String: Any] = [
            "status": "trial",
            "expiresAt": "2026-05-15T14:56:52.514Z",
            "daysLeft": 7,
            "source": "redeem_code",
        ]
        let state = SubscriptionState(serverPayload: payload)
        XCTAssertNotNil(state)
        XCTAssertEqual(state?.status, .trial)
        XCTAssertEqual(state?.daysLeft, 7)
        XCTAssertEqual(state?.source, "redeem_code")
        XCTAssertNotNil(state?.expiresAt, "ISO8601 with .NNNZ should parse")
    }

    func test_serverPayload_minimalNonePayloadIngested() {
        // Pre-F4 server response for Mac is bare-bones; only status
        // is set. Make sure init doesn't choke on missing optionals.
        let payload: [String: Any] = ["status": "none"]
        let state = SubscriptionState(serverPayload: payload)
        XCTAssertEqual(state?.status, .none)
        XCTAssertNil(state?.expiresAt)
        XCTAssertNil(state?.daysLeft)
        XCTAssertNil(state?.source)
    }

    func test_serverPayload_daysLeftAsDoubleStillWorks() {
        // Defensive: some serialization layers (JS clients via
        // server proxies) may convert int→double. Accept both.
        let payload: [String: Any] = ["status": "trial", "daysLeft": 7.0]
        let state = SubscriptionState(serverPayload: payload)
        XCTAssertEqual(state?.daysLeft, 7)
    }

    func test_serverPayload_invalidExpiresAtBecomesNil() {
        // Malformed ISO8601 — don't crash, just drop the field.
        let payload: [String: Any] = [
            "status": "trial",
            "expiresAt": "not a date",
        ]
        let state = SubscriptionState(serverPayload: payload)
        XCTAssertNotNil(state, "init shouldn't fail on bad date — only on bad status")
        XCTAssertNil(state?.expiresAt)
    }

    // MARK: - RedemptionRecord → SubscriptionState (post-redeem instant cache)

    func test_fromRedemption_constructsActiveTrial() {
        let record = RedemptionRecord(
            code: "FREE-TEST0001",
            durationDays: 7,
            redeemedAt: Date(),
            expiresAt: Date().addingTimeInterval(7 * 86400)
        )
        let state = SubscriptionState(fromRedemption: record)
        XCTAssertEqual(state.status, .trial)
        XCTAssertEqual(state.source, "redeem_code")
        XCTAssertEqual(state.daysLeft, 7, "constructed daysLeft should match the requested duration")
        XCTAssertNotNil(state.expiresAt)
        XCTAssertTrue(state.isActive)
    }

    func test_fromRedemption_partialDayCeils() {
        // Edge: redeemed at the END of day 0, expires day 7. Same as
        // the redeem flow's actual production timing.
        let record = RedemptionRecord(
            code: "X",
            durationDays: 1,
            redeemedAt: Date(),
            expiresAt: Date().addingTimeInterval(18 * 3600)
        )
        let state = SubscriptionState(fromRedemption: record)
        XCTAssertEqual(state.daysLeft, 1, "ceil should produce 1 for 18h remaining")
    }

    // MARK: - Codable round-trip (UserDefaults persistence)

    func test_codable_roundTripPreservesAllFields() throws {
        let original = SubscriptionState(
            status: .trial,
            expiresAt: Date(timeIntervalSince1970: 1_800_000_000),
            daysLeft: 7,
            source: "redeem_code"
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let restored = try decoder.decode(SubscriptionState.self, from: data)
        XCTAssertEqual(restored, original)
    }

    func test_codable_handlesNilFields() throws {
        let original = SubscriptionState(
            status: .none,
            expiresAt: nil,
            daysLeft: nil,
            source: nil
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let restored = try decoder.decode(SubscriptionState.self, from: data)
        XCTAssertEqual(restored, original)
    }
}
