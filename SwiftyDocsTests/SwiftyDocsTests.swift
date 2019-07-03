//
//  SwiftyDocsTests.swift
//  SwiftyDocsTests
//
//  Created by Michael Redig on 7/2/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import XCTest
@testable import SwiftyDocs

class SwiftyDocsTests: XCTestCase {

	func testAccesssibilityCompare() {
		let isInternal = Accessibility.internal
		let isPublic = Accessibility.public

		XCTAssertTrue(isInternal < isPublic, "\(isInternal.rawValue) < \(isPublic.rawValue)")
		XCTAssertTrue(isPublic > isInternal, "\(isPublic.rawValue) > \(isInternal.rawValue)")
		XCTAssertTrue(isPublic >= isInternal, "\(isPublic.rawValue) >= \(isInternal.rawValue)")
		XCTAssertTrue(isPublic >= isPublic, "\(isPublic.rawValue) >= \(isPublic.rawValue)")
		XCTAssertFalse(isInternal >= isPublic, "\(isInternal.rawValue) >= \(isPublic.rawValue)")

	}

}
