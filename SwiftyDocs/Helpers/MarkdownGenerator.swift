//
//  MarkdownGenerator.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/3/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation

/**
A helper class to generate markdown from an input `SwiftDocItem`.
*/
class MarkdownGenerator {
	/**
	Generates a markdown String and returns the result. `includeTOCLinks` is togglable - embeds property and method entries within a class, struct, enum, etc in a unique string structure that the markdown renderer/custom javascript will find and replace with docset compatible TOC links. Generally harmless if you're not using docsets, but you can turn it off if you're finding that it's causing you trouble.
	*/
	func generateMarkdownDocumentString(fromRootDocItem swiftDocItem: SwiftDocItem, minimumAccessControl: AccessControl, includeTOCLinks: Bool = true) -> String {

		let sourceFile: MDNode = .nonIndentedCollection([
				.paragraphWithInlineElements([.italics("Found in:")]),
				.unorderedListItem("\(MDNode.codeInline(swiftDocItem.sourceFile))")
			])
		var rootDoc: MDNode = .document(
			.header(2, swiftDocItem.title),
			.paragraphWithInlineElements([.bold(swiftDocItem.accessControl.stringValue), .italics(swiftDocItem.kind.stringValue)]),
			.codeBlock(swiftDocItem.declaration, syntax: "swift"),
			.paragraph(swiftDocItem.comment ?? "No documentation"),
			.newline(),
			sourceFile
		)

		var children = [MDNode]()
		if let properties = swiftDocItem.properties {
			for property in properties {
				guard property.accessControl >= minimumAccessControl else { continue }

				let propertySourceFile: MDNode = .nonIndentedCollection([
					.paragraphWithInlineElements([.italics("Found in:")]),
					.unorderedListItem("\(MDNode.codeInline(property.sourceFile))")
				])

				let tocLink = includeTOCLinks ? "##--\(property.kind.docSetType)/\(property.title.percentEscaped)/\(property.title)--##" : property.title
				var propertyDoc: MDNode = .unorderedListItem("\(tocLink)",
					.paragraphWithInlineElements([.boldItalics(property.accessControl.stringValue), .italics(property.kind.stringValue)]),
					.paragraph(property.comment ?? "No documentation"),
					.codeBlock(property.declaration, syntax: "swift")
				)

				if sourceFile != propertySourceFile {
					propertyDoc = propertyDoc.appending(node: propertySourceFile)
				}
				children.append(propertyDoc)
			}
		}

		if !children.isEmpty {
			rootDoc = rootDoc.appending(nodes: [.header(3, "Members"), .newline()])
			rootDoc = rootDoc.appending(nodes: children)
		}

		return rootDoc.finalRender()
	}

	/**
	Generates a contents page from an array of top level `SwiftDocItem`s.
	*/
	func generateMarkdownContents(fromTopLevelIndex topLevelIndex: [SwiftDocItem], minimumAccessControl: AccessControl, linkStyle: PageCount, format: SaveFormat) -> String {

		var currentTitle = ""
		var rootMD: MDNode = .document()
		for item in (topLevelIndex.sorted { $0.kind.stringValue < $1.kind.stringValue }) {
			guard item.accessControl >= minimumAccessControl else { continue }

			if currentTitle != item.kind.stringValue.capitalized {
				currentTitle = item.kind.stringValue.capitalized
				rootMD = rootMD.appending(node: .header(4, currentTitle))
			}

			let link = MDNode.link("\(item.title)", item.htmlLink(format: format, output: linkStyle))

			rootMD = rootMD.appending(node: .paragraphWithInlineElements([.text("* "), link]))
			rootMD = rootMD.appending(node: .newline())
		}

		return rootMD.finalRender()
	}
}
