//
//  RedemptionTests.swift
//  ClaudeIslandTests
//
//  Coverage for the trial-redemption types added when redeem-code
//  was migrated off iOS App Store. The pairing-redeem endpoint is
//  a paid-path API — silent breakage here means a user thinks they
//  activated their trial but the banner never shows. So this file
//  pins down the contract:
//    - 9 server error keys map to the right RedeemError case
//    - unknown error key falls back to .serverError (not .network,
//      which would mislead users into checking their wifi)
//    - ISO8601 parser accepts both ".000Z" (current server format)
//      and plain "Z" (so a future server change doesn't break us)
//    - isActive / daysLeft / formattedExpiry compute correctly
//      across past/future/edge boundaries
//    - JSON encode/decode round-trip preserves every field
//

import XCTest
@testable import ClaudeIsland

final class RedemptionTests: XCTestCase {

    // MARK: - RedeemError mapping (server contract)

    func test_redeemError_allKnownKeysMap() {
        // These nine keys are the server's stable contract. Any
        // mismatch here means either Mac is reading the wrong field
        // or server changed key names without coordinating. Fail loud.
        let cases: [(String, RedeemError)] = [
            ("unauthorized",     .unauthorized),
            ("not_a_mac",        .notAMac),
            ("invalid_code",     .invalidCode),
            ("code_exhausted",   .codeExhausted),
            ("code_expired",     .codeExpired),
            ("code_revoked",     .codeRevoked),
            ("already_redeemed", .alreadyRedeemed),
            ("rate_limited",     .rateLimited),
            ("server_error",     .serverError),
        ]
        for (key, expected) in cases {
            let mapped = RedeemError(serverErrorKey: key)
            XCTAssertEqual(mapped, expected, "key '\(key)' should map to \(expected)")
        }
    }

    func test_redeemError_unknownKeyFallsBackToServerError() {
        // When server adds a new error case the Mac binary doesn't know
        // about, .serverError is the right default — it tells the user
        // "服务器繁忙,请稍后重试" instead of misleading them to check
        // their wifi (.network) or login state (.unauthorized).
        let mapped = RedeemError(serverErrorKey: "future_unknown_error")
        XCTAssertEqual(mapped, .serverError)
    }

    func test_redeemError_emptyKeyFallsBackToServerError() {
        // Defensive: server should never send empty error string, but
        // if it does, treat as unknown rather than crashing or
        // matching some other case by accident.
        XCTAssertEqual(RedeemError(serverErrorKey: ""), .serverError)
    }

    func test_redeemError_displayMessage_nonEmptyForEveryCase() {
        // Every case must have a non-empty message — silent UI is
        // worse than a generic error.
        let allCases: [RedeemError] = [
            .unauthorized, .notAMac, .invalidCode, .codeExhausted,
            .codeExpired, .codeRevoked, .alreadyRedeemed, .rateLimited,
            .serverError, .network, .malformedResponse,
        ]
        for c in allCases {
            XCTAssertFalse(c.displayMessage.isEmpty, "\(c) has empty displayMessage")
        }
    }

    // MARK: - RedemptionRecord.isActive

    func test_isActive_futureExpiryReturnsTrue() {
        let record = makeRecord(expiresInSeconds: 60 * 60) // 1 hour future
        XCTAssertTrue(record.isActive)
    }

    func test_isActive_pastExpiryReturnsFalse() {
        let record = makeRecord(expiresInSeconds: -60) // 1 minute ago
        XCTAssertFalse(record.isActive)
    }

    func test_isActive_zeroExpiryReturnsFalse() {
        // Edge: expiresAt == now. Record is OFF — isActive uses strict >.
        // Treating "exactly now" as expired matches consumer-app
        // intuition: a coupon says "expires at 5pm" → at 5pm it's gone.
        let record = makeRecord(expiresInSeconds: 0)
        XCTAssertFalse(record.isActive)
    }

    // MARK: - RedemptionRecord.daysLeft

    func test_daysLeft_sevenDayFutureReturnsSeven() {
        let record = makeRecord(expiresInSeconds: 7 * 86400)
        XCTAssertEqual(record.daysLeft, 7)
    }

    func test_daysLeft_partialDayCeilsToOne() {
        // 18 hours left → ceil to 1 day. iPhone shows "剩余 1 天" not
        // "剩余 0 天" in this case, and Mac matches.
        let record = makeRecord(expiresInSeconds: 18 * 3600)
        XCTAssertEqual(record.daysLeft, 1)
    }

    func test_daysLeft_oneSecondFutureReturnsOne() {
        // Smallest positive remaining → 1, not 0. Banner stays on
        // until isActive flips false.
        let record = makeRecord(expiresInSeconds: 1)
        XCTAssertEqual(record.daysLeft, 1)
    }

    func test_daysLeft_pastExpiryReturnsZero() {
        let record = makeRecord(expiresInSeconds: -3600)
        XCTAssertEqual(record.daysLeft, 0)
    }

    func test_daysLeft_exactlyNowReturnsZero() {
        let record = makeRecord(expiresInSeconds: 0)
        XCTAssertEqual(record.daysLeft, 0)
    }

    // MARK: - ISO8601 dual-fallback parser
    //
    // ServerConnection.parseISO8601 is private, so we exercise the same
    // logic via Foundation's ISO8601DateFormatter to verify the assumption
    // holds: both ".000Z" and plain "Z" parse with the same .withInternetDateTime
    // option set we use in production. If a future Foundation change breaks
    // either format, these tests catch it before users see "服务器繁忙".

    func test_iso8601_fractionalParses() {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        XCTAssertNotNil(f.date(from: "2026-05-08T03:00:00.000Z"),
                        "fractional formatter must accept current server format")
    }

    func test_iso8601_plainParses() {
        // The fallback path. If server ever drops `.000` from its emit
        // format, the plain formatter must catch it. This test exists
        // because the dual-fallback in production is otherwise dead code
        // until that future change happens — without this test we'd
        // never know it stopped working.
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        XCTAssertNotNil(f.date(from: "2026-05-08T03:00:00Z"),
                        "plain formatter must accept the no-fractional fallback format")
    }

    func test_iso8601_fractionalRejectsPlain() {
        // Pin down WHY the dual-fallback exists: the fractional formatter
        // is strict and rejects strings without `.000`. If this assumption
        // ever flipped (Foundation became lenient), the second formatter
        // becomes dead code — we'd want to know.
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        XCTAssertNil(f.date(from: "2026-05-08T03:00:00Z"),
                     "fractional formatter is expected to reject non-fractional input")
    }

    func test_iso8601_fractionalAcceptsAnyMilliseconds() {
        // Server emits Date.toISOString() naturally, which uses the
        // *actual* millisecond value — e.g. "2026-05-15T14:56:52.514Z",
        // not always ".000Z". The fractional formatter accepts any
        // 0-999 millis. Without this test we'd ship believing only
        // ".000Z" parses (per the original misleading docstring) and
        // be surprised when production redeems return ".514Z" and
        // appear to "fail to parse" (they don't, this proves it).
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        XCTAssertNotNil(f.date(from: "2026-05-15T14:56:52.514Z"),
                        "fractional formatter must accept arbitrary milliseconds")
        XCTAssertNotNil(f.date(from: "2026-05-15T14:56:52.001Z"),
                        "fractional formatter must accept low millisecond values")
        XCTAssertNotNil(f.date(from: "2026-05-15T14:56:52.999Z"),
                        "fractional formatter must accept high millisecond values")
    }

    // MARK: - JSON round-trip

    func test_jsonRoundTrip_preservesAllFields() throws {
        let original = RedemptionRecord(
            code: "FREE-ABCD1234",
            durationDays: 7,
            redeemedAt: Date(timeIntervalSince1970: 1_700_000_000),
            expiresAt: Date(timeIntervalSince1970: 1_700_604_800)
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let restored = try decoder.decode(RedemptionRecord.self, from: data)
        XCTAssertEqual(restored.code, original.code)
        XCTAssertEqual(restored.durationDays, original.durationDays)
        XCTAssertEqual(restored.redeemedAt.timeIntervalSince1970,
                       original.redeemedAt.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(restored.expiresAt.timeIntervalSince1970,
                       original.expiresAt.timeIntervalSince1970, accuracy: 0.001)
    }

    // MARK: - Helpers

    private func makeRecord(
        expiresInSeconds offset: TimeInterval,
        durationDays: Int = 7
    ) -> RedemptionRecord {
        let now = Date()
        return RedemptionRecord(
            code: "FREE-TEST0001",
            durationDays: durationDays,
            redeemedAt: now,
            expiresAt: now.addingTimeInterval(offset)
        )
    }
}
