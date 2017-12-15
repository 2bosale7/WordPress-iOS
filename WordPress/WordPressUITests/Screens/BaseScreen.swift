import Foundation
import XCTest

class BaseScreen {
    var app: XCUIApplication!
    var expectedElement: XCUIElement!
    var waitTimeout: Double!
    public static var testCase: XCTestCase!

    init(element: XCUIElement) {
//        testCase = XCTestCase.init()

        app = XCUIApplication()
        expectedElement = element
        waitTimeout = 20
        _ = waitForPage()
    }

    func waitForPage() -> BaseScreen {
        _ = expectedElement.waitForExistence(timeout: waitTimeout)
        Logger.log(message: "Page \(self) is loaded", event: .i)
        return self
    }

    // predicate: "isEnabled == true"

    func waitFor(element: XCUIElement, predicate: String, timeout: Int? = nil) {
        let timeoutValue = timeout ?? 5

        let elementPredicate = XCTNSPredicateExpectation(predicate: NSPredicate(format: predicate), object: element)
        _ = XCTWaiter.wait(for: [elementPredicate], timeout: TimeInterval(timeoutValue))
    }

    func waitFor2(element: XCUIElement, predicate: String,
                                       file: String = #file, line: UInt = #line, timeout: Int? = nil) {
        let nsPredicate = NSPredicate(format: predicate)
        BaseScreen.testCase.expectation(for: nsPredicate,
                    evaluatedWith: element, handler: nil)

        let timeoutValue = timeout ?? 5

        BaseScreen.testCase.waitForExpectations(timeout: TimeInterval(timeoutValue)) { (error) -> Void in
            if error != nil {
                let message = "Failed to find \(element) after \(timeoutValue) seconds."
                BaseScreen.testCase.recordFailure(withDescription: message,
                                   inFile: file,
                                   atLine: line,
                                   expected: true)
            }
        }
    }

    func isLoaded() -> Bool {
        return expectedElement.exists
    }

    class func waitForLoadingIndicatorToDisappear(within timeout: TimeInterval) {
        #if os(tvOS)
            return
        #endif

        let networkLoadingIndicator = XCUIApplication().otherElements.deviceStatusBars.networkLoadingIndicators.element
        let networkLoadingIndicatorDisappeared = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: networkLoadingIndicator)
        XCTWaiter.wait(for: [networkLoadingIndicatorDisappeared], timeout: timeout)
    }
}

private extension XCUIElementAttributes {
    var isNetworkLoadingIndicator: Bool {
        if hasWhiteListedIdentifier { return false }

        let hasOldLoadingIndicatorSize = frame.size == CGSize(width: 10, height: 20)
        let hasNewLoadingIndicatorSize = frame.size.width.isBetween(46, and: 47) && frame.size.height.isBetween(2, and: 3)

        return hasOldLoadingIndicatorSize || hasNewLoadingIndicatorSize
    }

    var hasWhiteListedIdentifier: Bool {
        let whiteListedIdentifiers = ["GeofenceLocationTrackingOn", "StandardLocationTrackingOn"]

        return whiteListedIdentifiers.contains(identifier)
    }

    func isStatusBar(_ deviceWidth: CGFloat) -> Bool {
        if elementType == .statusBar { return true }
        guard frame.origin == .zero else { return false }

        let oldStatusBarSize = CGSize(width: deviceWidth, height: 20)
        let newStatusBarSize = CGSize(width: deviceWidth, height: 44)

        return [oldStatusBarSize, newStatusBarSize].contains(frame.size)
    }
}

private extension XCUIElementQuery {
    var networkLoadingIndicators: XCUIElementQuery {
        let isNetworkLoadingIndicator = NSPredicate { (evaluatedObject, _) in
            guard let element = evaluatedObject as? XCUIElementAttributes else { return false }

            return element.isNetworkLoadingIndicator
        }

        return self.containing(isNetworkLoadingIndicator)
    }

    var deviceStatusBars: XCUIElementQuery {
        let deviceWidth = XCUIApplication().frame.width

        let isStatusBar = NSPredicate { (evaluatedObject, _) in
            guard let element = evaluatedObject as? XCUIElementAttributes else { return false }

            return element.isStatusBar(deviceWidth)
        }

        return self.containing(isStatusBar)
    }
}

private extension CGFloat {
    func isBetween(_ numberA: CGFloat, and numberB: CGFloat) -> Bool {
        return numberA...numberB ~= self
    }
}
