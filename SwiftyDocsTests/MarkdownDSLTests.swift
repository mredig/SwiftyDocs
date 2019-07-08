//
//  MarkdownDSLTests.swift
//  SwiftyDocsTests
//
//  Created by Michael Redig on 7/7/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import XCTest
@testable import SwiftyDocs

class MarkdownDSLTests: XCTestCase {

	func testItemsRenders() {
		var node: MDNode = .header(1, "Header 1")
		XCTAssertEqual(node.description, "# Header 1")
		XCTAssertEqual(node.render().text, "# Header 1\n")
		XCTAssertEqual(node.finalRender(), "# Header 1\n\n")
	}

	// this is ugly and i won't be surprised if it breaks in the future.
	// (due to the nature of sets, you can't promise consistent order, so the links that are included can change order
	// randomly... so to check accuracy, we need to doctor the result to match the "correct" (also doctored to match)
	// value)
	func testCleanUp() {
		let document: MDNode = .document(
			.header(4, "MyDoc"),
			.paragraph("these are some of my words. I will just talk about stuff."),
			.paragraphWithInlineElements([.text("This is an inline"), .italics("italicized"), .bold("text."), .boldItalics("Rejoice!")]),
			.paragraphWithInlineElements([.text("This line has a link. Don't believe me?"), .link("Click here!", "https://mikespsyche.com")]),
			.paragraph("Another way to \(MDNode.link("do things", "https://redeggproductions.com"))."),
			.unorderedListItem("item a"),
			.unorderedListItem("item b",
							   .unorderedListItem("sub item c"),
							   .unorderedListItem("sub item d"),
							   .unorderedListItem("sub item e"),
							   .paragraph("This is non bulleted text", indentation: 1),
							   .unorderedListItem("continuing the sub list",
												  .unorderedListItem("a sub sub list!")
				)
			),
			.unorderedListItem("item f"),
			.paragraph("This is to separate things."),
			.orderedListItem("item 1"),
			.orderedListItem("item 2",
							 .orderedListItem("sub item 1"),
							 .orderedListItem("sub item 2"),
							 .orderedListItem("sub item 3"),
							 .paragraph("this is a paragrah interuption"),
							 .orderedListItem("sub item 4")
			),
			.orderedListItem("item 3"),
			.codeBlock("public var foo = Bar()", syntax: "swift")
		)
		let finalRender = document.finalRender()

		let links = finalRender.ranges(of: ##"\[\d+\]"##, options: .regularExpression, range: nil, locale: nil)
		XCTAssertEqual(links.count, 3)
		let uniqueLinks = Set(links.map { finalRender[$0] })
		XCTAssertEqual(uniqueLinks.count, 2)

		let correctOutput = """
				#### MyDoc

				these are some of my words. I will just talk about stuff.

				This is an inline *italicized* **text.** ***Rejoice!***

				This line has a link. Don't believe me? [Click here!]

				Another way to [do things](https://redeggproductions.com).

				* item a
				* item b
					* sub item c
					* sub item d
					* sub item e
						This is non bulleted text
					* continuing the sub list
						* a sub sub list!
				* item f

				This is to separate things.

				1. item 1
				1. item 2
					1. sub item 1
					1. sub item 2
					1. sub item 3
					this is a paragrah interuption
					1. sub item 4
				1. item 3

				```swift
				public var foo = Bar()
				```
				"""
		var finalSansLinks = finalRender
			.replacingOccurrences(of: ##"\[\d+\]"##, with: "", options: .regularExpression)
			.split(separator: "\n", omittingEmptySubsequences: false)
			.map { String($0) }
		for (index, line) in finalSansLinks.enumerated().reversed() {
			if line.hasPrefix(":https") || line.isEmpty {
				finalSansLinks.remove(at: index)
			} else {
				break
			}
		}
		XCTAssertEqual(finalSansLinks.joined(separator: "\n"), correctOutput)
//		print(finalRender)
	}

	func testSubListing() {
		let doc: MDNode = .document(
			.unorderedListItem("list item",
			   .unorderedListItem("sub list item",
				  .unorderedListItem("sub sub list item",
					 .unorderedListItem("sub sub sub list item",
						.unorderedListItem("sub sub sub sub list item")
						)
					)
				)
			)
		)

		let correctOutput = """
		* list item
			* sub list item
				* sub sub list item
					* sub sub sub list item
						* sub sub sub sub list item



		"""

		XCTAssertEqual(doc.finalRender(), correctOutput)
	}


	func testAppending() {
		let doc: MDNode = .document(
			.header(1, "Doc 1"),
			.paragraph("This is my first doc!"),
			.codeBlock("lets add a code block... public var poop")
		)

		let doc2: MDNode = .indentedCollection([
			.header(3, "Doc 2"),

			.unorderedListItem("\(MDNode.bold("mockData"))"),
			.paragraphWithInlineElements([.boldItalics("internal"), .italics("instance property")], indentation: 1),
			.codeBlock("let mockData: Data?", syntax: "swift", indentation: 1),
			.paragraph("this should be part of doc1", indentation: 1),
			.paragraph("Found in", indentation: 1),
			.unorderedListItem("`NetworkHandler/NetworkHandler.swift`", indentation: 1),
			.hr(),

			.unorderedListItem("\(MDNode.bold("mockData2"))"),
			.paragraphWithInlineElements([.boldItalics("external"), .italics("global property")], indentation: 1),
			.codeBlock("let mockData: Data?", syntax: "swift", indentation: 1),
			.paragraph("this should be part of doc1", indentation: 1),
			.paragraph("Found in", indentation: 1),
			.unorderedListItem("`NetworkHandler/NetworkHandler.swift`", indentation: 1),
			.hr(),

			.unorderedListItem("\(MDNode.bold("mockData"))",
				.paragraphWithInlineElements([.boldItalics("internal"), .italics("instance property")]),
				.codeBlock("let mockData: Data?", syntax: "swift"),
				.paragraph("this should be part of doc1"),
				.paragraph("Found in"),
				.unorderedListItem("`NetworkHandler/NetworkHandler.swift`")
			),
			.hr()
		])

		var doc3 = doc
		for _ in 0..<5 {
			let tDoc: MDNode = .indentedCollection([
				.unorderedListItem("\(MDNode.bold("mockData"))",
					.paragraphWithInlineElements([.boldItalics("internal"), .italics("instance property")]),
					.codeBlock("let mockData: Data?", syntax: "swift"),
					.paragraph("this should be part of doc1"),
					.paragraph("Found in"),
					.unorderedListItem("`NetworkHandler/NetworkHandler.swift`")
				),
				.hr()
			])
			doc3 = doc3.appending(node: tDoc)
		}


		print(doc3.finalRender())
	}

	func testEquatable() {
		let attr1 = MDNode.MDAttribute.indentation(2)
		let attr2 = MDNode.MDAttribute.indentation(3)
		let attr3 = MDNode.MDAttribute.linkURL(URL(string: "/")!)

		let attr4 = MDNode.MDAttribute.indentation(2)
		let attr5 = MDNode.MDAttribute.indentation(3)
		let attr6 = MDNode.MDAttribute.linkURL(URL(string: "/")!)

		XCTAssertNotEqual(attr1, attr2)
		XCTAssertNotEqual(attr1, attr3)
		XCTAssertEqual(attr1, attr4)

		XCTAssertEqual(attr2, attr5)
		XCTAssertNotEqual(attr2, attr3)

		XCTAssertEqual(attr3, attr6)
		XCTAssertNotEqual(attr3, attr5)

	}
}
