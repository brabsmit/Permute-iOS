import XCTest
@testable import Permute

class PBLogicTests: XCTestCase {

    var viewModel: TimerViewModel!

    override func setUp() {
        super.setUp()
        viewModel = TimerViewModel()
        // Clear existing solves for testing
        viewModel.solves = []
        viewModel.lastSolveWasPB = false
    }

    func testFirstSolveIsPB() {
        // Simulate a solve
        viewModel.timeElapsed = 10.0
        // We need to access private method stopTimer, but we can't.
        // However, we can simulate the logic or use userTouchedDown/Up to trigger it.
        // Ideally we should test the logic itself if possible or expose it.
        // Since I cannot change visibility easily without modifying the code again for testing purposes (which is fine but maybe overkill),
        // I will try to trigger it via the public state machine methods.

        viewModel.state = .running
        viewModel.userTouchedDown() // Stops timer

        XCTAssertTrue(viewModel.lastSolveWasPB, "First solve should be a PB")
        XCTAssertEqual(viewModel.solves.count, 1)
    }

    func testBetterSolveIsPB() {
        // 1. First solve: 10s
        viewModel.state = .running
        viewModel.timeElapsed = 10.0
        viewModel.userTouchedDown()
        XCTAssertTrue(viewModel.lastSolveWasPB)

        // 2. Second solve: 12s (Worse)
        viewModel.state = .running
        viewModel.timeElapsed = 12.0
        viewModel.userTouchedDown()
        XCTAssertFalse(viewModel.lastSolveWasPB, "12s is worse than 10s")

        // 3. Third solve: 9s (Better)
        viewModel.state = .running
        viewModel.timeElapsed = 9.0
        viewModel.userTouchedDown()
        XCTAssertTrue(viewModel.lastSolveWasPB, "9s is better than 10s")
    }

    func testEqualSolveIsNotPB() {
        // 1. First solve: 10s
        viewModel.state = .running
        viewModel.timeElapsed = 10.0
        viewModel.userTouchedDown()

        // 2. Second solve: 10s (Equal)
        viewModel.state = .running
        viewModel.timeElapsed = 10.0
        viewModel.userTouchedDown()

        // Strict inequality < means equal is not better
        XCTAssertFalse(viewModel.lastSolveWasPB, "Equal time should not be PB")
    }
}
