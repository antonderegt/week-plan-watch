//
//  weekPlanWatch_Watch_AppTests.swift
//  weekPlanWatch Watch AppTests
//
//  Created by Anton De Regt on 22/02/2026.
//

import Testing
@testable import weekPlanWatch_Watch_App

struct weekPlanWatch_Watch_AppTests {

    @MainActor
    @Test func testServiceLeavesLoadingState() async {
        let service = WeekPlanService()
        await service.load()
        // After load(), state should be .error (no real server in tests) — never .loading
        if case .loading = service.state {
            Issue.record("Service should not remain in loading state after load()")
        }
    }

}
