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

		let children = setupChildrenProperties(from: swiftDocItem.properties,
											   minimumAccessControl: minimumAccessControl,
											   parentSourceFile: sourceFile,
											   includeTOCLinks: includeTOCLinks)

		let extensions = setupChildrenProperties(from: swiftDocItem.extensions,
												 minimumAccessControl: minimumAccessControl,
												 parentSourceFile: sourceFile,
												 includeTOCLinks: includeTOCLinks)

		if !children.isEmpty {
			rootDoc = rootDoc.appending(nodes: [.header(3, "Members"), .newline()])
			rootDoc = rootDoc.appending(nodes: children)
		}

		if !extensions.isEmpty {
			rootDoc = rootDoc.appending(nodes: [.header(3, "Extensions"), .newline()])
			rootDoc = rootDoc.appending(nodes: extensions)
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

	private func setupChildrenProperties(from children: [SwiftDocItem]?, minimumAccessControl: AccessControl, parentSourceFile: MDNode, includeTOCLinks: Bool) -> [MDNode] {
		guard let children = children else { return [] }
		var outChildren = [MDNode]()
		for child in children {
			guard child.accessControl >= minimumAccessControl else { continue }

			if child.kind == .extension {
				outChildren.append(contentsOf: setupChildrenProperties(from: child.properties,
																	   minimumAccessControl: minimumAccessControl,
																	   parentSourceFile: parentSourceFile,
																	   includeTOCLinks: includeTOCLinks))
				continue
			}

			let childSourceFile: MDNode = .nonIndentedCollection([
				.paragraphWithInlineElements([.italics("Found in:")]),
				.unorderedListItem("\(MDNode.codeInline(child.sourceFile))")
				])

			let tocLink = includeTOCLinks ? "##--\(child.kind.docSetType)/\(child.title.percentEscaped)/\(child.title)--##" : child.title
			var childDoc: MDNode = .unorderedListItem("\(tocLink)",
				.paragraphWithInlineElements([.boldItalics(child.accessControl.stringValue), .italics(child.kind.stringValue)]),
				.paragraph(child.comment ?? "No documentation"),
				.codeBlock(child.declaration, syntax: "swift")
			)

			if parentSourceFile != childSourceFile {
				childDoc = childDoc.appending(node: childSourceFile)
			}
			outChildren.append(childDoc)
		}
		return outChildren
	}
}
