//
//  MarkdownGenerator.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/3/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation

class MarkdownGenerator {
	func generateMarkdownDocumentString(fromRootDocItem swiftDocItem: SwiftDocItem, minimumAccessControl: AccessControl) -> String {

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

				var propertyDoc: MDNode = .unorderedListItem("\(MDNode.bold(property.title))",
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

	func generateMarkdownContents(fromTopLevelIndex topLevelIndex: [SwiftDocItem], minimumAccessControl: AccessControl, linkStyle: OutputStyle, format: SaveFormat) -> String {

		var markOut = ""
		var links = ""
		var currentTitle = ""
		for (index, item) in (topLevelIndex.sorted { $0.kind.stringValue < $1.kind.stringValue }).enumerated() {
			guard item.accessControl >= minimumAccessControl else { continue }
			if currentTitle != item.kind.stringValue.capitalized {
				currentTitle = item.kind.stringValue.capitalized
				markOut += currentTitle.isEmpty ? "" : "\n"
				markOut += "#### \(currentTitle)\n\n"
			}
			markOut += "* [\(item.title)][\(index)]\n"
			switch linkStyle {
			case .singlePage:
				let linkValue = item.title.replacingNonWordCharacters()
				links += "[\(index)]:#\(linkValue)\n"
			case .multiPage:
				let fileExt = format == .html ? "html" : "md"
				let linkValue = item.title.replacingNonWordCharacters(lowercased: false)
				let folderValue = currentTitle.replacingNonWordCharacters()
				links += "[\(index)]:\(folderValue)/\(linkValue).\(fileExt)\n"
			}
		}

		return markOut + "\n\n" + links
	}
}

extension String {
	func replacingNonWordCharacters(lowercased: Bool = true) -> String {
		var rVal = self
		if lowercased {
			rVal = rVal.lowercased()
		}
		return rVal.replacingOccurrences(of: ##"\W+"##, with: "-", options: .regularExpression, range: nil)
	}
}

extension String: MarkdownInlineProtocol {
	var inlineRender: String {
		return self
	}
}

protocol MarkdownInlineProtocol {
	var inlineRender: String { get }
}

protocol MarkdownBlockProtocol {
	var rendered: (text: String, footerLinks: [URL]) { get }
	var finalRender: String { get }
}

extension MarkdownBlockProtocol {
	var finalRender: String {
		let tRender = rendered
		let urls = Set(tRender.footerLinks).reduce("") {
			let hash = $1.hashValue
			let formattedString = "[\(hash)]:\($1.path)"
			return $0 + "\n" + formattedString
		}
		return "\(tRender.text)\n\n\(urls)\n"
	}
}

struct MarkdownLine: MarkdownBlockProtocol {
	let markdowns: [MarkdownBlockProtocol]
	let newLines: Int
	let joined: String
	let indentation: Int

	var rendered: (text: String, footerLinks: [URL]) {
		let indents = "\t".repeated(count: indentation)
		var tMarkdowns = markdowns.reduce((text: indents, footerLinks: [URL]()), { (previous, new) in
			let newTuple = new.rendered
			return (previous.text + (!previous.text.isEmpty ? joined : "") + newTuple.text,
					previous.footerLinks + newTuple.footerLinks)
		})
		let newLines = "\n".repeated(count: self.newLines)
		tMarkdowns.text += newLines
		return tMarkdowns
	}
}

// to get the basic init for free
extension MarkdownLine {
	init(_ markdowns: MarkdownBlockProtocol ..., newLines: Int = 1, joinedBy joined: String = " ", indentation: Int = 0) {
		self.markdowns = markdowns
		self.newLines = newLines
		self.joined = joined
		self.indentation = indentation
	}

//	init(_ markdowns: [MarkdownBlockProtocol], newLines: Int = 1, joinedBy joined: String = " ") {
//		self.markdowns = markdowns
//		self.newLines = newLines
//		self.joined = joined
//	}

	init(words: MarkdownWord ..., newLines: Int = 1, joinedBy joined: String = " ", indentation: Int = 0) {
		self.markdowns = words
		self.newLines = newLines
		self.joined = joined
		self.indentation = indentation
	}
}

struct MarkdownLineComposer: MarkdownBlockProtocol {
	var rendered: (text: String, footerLinks: [URL]) {
		return (text, footerLinks)
	}

	private let text: String
	private let footerLinks: [URL]

	init(_ markdownLines: [MarkdownLine]) {
		let tVal = markdownLines.reduce( (text: "", footerLinks: [URL]() ), { (previous, new) in
			let newTuple = new.rendered
			return (previous.text + newTuple.text,
					previous.footerLinks + newTuple.footerLinks)
		})
		self.text = tVal.text
		self.footerLinks = tVal.footerLinks
	}

	init(_ markdownLineComposers: [MarkdownLineComposer]) {
		let tVal = markdownLineComposers.reduce( (text: "", footerLinks: [URL]() ), { (previous, new) in
			let newTuple = new.rendered
			return (previous.text + newTuple.text,
					previous.footerLinks + newTuple.footerLinks)
		})
		self.text = tVal.text
		self.footerLinks = tVal.footerLinks
	}
}


//struct MarkdownLine: MarkdownBlockProtocol {
//	var rendered: (text: String, footerLinks: [URL]) {
//		let indents = "\t".repeated(count: indentation)
//		return markdowns.reduce((text: indents, footerLinks: [URL]()), { (previous, new) in
//			let newTuple = new.rendered
//			return (previous.text + (!previous.text.isEmpty ? joined : "") + newTuple.text,
//					previous.footerLinks + newTuple.footerLinks)
//		})
//	}
//	let markdowns: [MarkdownWord]
//	let joined: String
//	let indentation: Int
//
//	init(_ markdowns: MarkdownWord ..., joinedBy joined: String = " ", indentation: Int = 0) {
//		self.markdowns = markdowns
//		self.joined = joined
//		self.indentation = indentation
//	}
//}

indirect enum MarkdownWord: LosslessStringConvertible, MarkdownBlockProtocol, MarkdownInlineProtocol, ExpressibleByStringInterpolation {
	typealias StringLiteralType = String

	case italics(text: MarkdownWord)
	case bold(text: MarkdownInlineProtocol)
	case link(link: URL, text: MarkdownWord)
	case header(level: Int, text: MarkdownWord)
	case orderedListItem(indentation: Int, text: MarkdownWord)
	case unorderedListItem(indentation: Int, text: MarkdownWord)
	case horizontalLine
	case text(MarkdownInlineProtocol)
	case inlineCode(code: MarkdownWord)
	case codeBlock(code: MarkdownWord, syntaxHighlighting: String?)

	var rendered: (text: String, footerLinks: [URL]) {
		var outString = ""
		var footerLink = [URL]()
		
		switch self {
		case .italics(let text):
			outString = "*\(text.inlineRender)*"

		case .bold(let text):
			outString = "**\(text.inlineRender)**"

		case .link(let link, let text):
			outString = "[\(text.inlineRender)][\(link.hashValue)]"
			footerLink = [link]

		case .header(let level, let text):
			let headerLevel = min(max(1, level), 6)
			let hashtags = "#".repeated(count: headerLevel)
			outString = hashtags + " \(text.inlineRender)"

		case .orderedListItem(let indentation, let text):
			let tabs = "\t".repeated(count: indentation)
			outString = tabs + "1. \(text.inlineRender)"

		case .unorderedListItem(let indentation, let text):
			let tabs = "\t".repeated(count: indentation)
			outString = tabs + "* \(text.inlineRender)"

		case .horizontalLine:
			outString = "___"

		case .text(let text):
			outString = text.inlineRender

		case .inlineCode(let code):
			outString = "`\(code.inlineRender)`"

		case .codeBlock(let code, let syntaxHighlighting):
			outString = """
				```\(syntaxHighlighting ?? "")
				\(code.inlineRender)
				```
				"""
		}
		return (outString, footerLink)
	}

	init<T: LosslessStringConvertible>(_ description: T) {
		self = .text(description.description)
	}

	init(stringLiteral value: String) {
		self = .text(value)
	}

	var description: String {
		return inlineRender
	}

	var inlineRender: String {
		if case .link(let link, let text) = self {
			return "[\(text)](\(link.path))"
		}
		return rendered.text
	}
}
