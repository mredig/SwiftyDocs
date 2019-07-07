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
		let docHeader = MarkdownBlock(words: .header(level: 2, text: swiftDocItem.title))
		let type = MarkdownBlock(words: .bold(text: swiftDocItem.accessControl.stringValue), .italics(text: swiftDocItem.kind.stringValue))
		let declaration = MarkdownBlock(words: .codeBlock(code: swiftDocItem.declaration, syntaxHighlighting: "swift"), newLines: 2)
		let discussion = MarkdownBlock(words: .paragraph(text: swiftDocItem.comment ?? "No documentation"), newLines: 2)


		let foundIn = MarkdownLine(.paragraph(text: "Found in"))
		let codeStyleFile = MarkdownWord.inlineCode(code: swiftDocItem.sourceFile)
		let docSourceFile = MarkdownLine(.unorderedListItem(indentation: 0, text: codeStyleFile.rendered.text))
		let foundInBlock = MarkdownBlock(foundIn, docSourceFile, newLines: 2, joinedBy: "\n")


		var children = [String]()
		if let properties = swiftDocItem.properties {
			for property in properties {
				guard property.accessControl >= minimumAccessControl else { continue }
				let propTitle = "* **\(property.title)**"
				let propType = "***\(property.accessControl.stringValue)*** *\(property.kind.stringValue)*"
				let propInfo = (property.comment ?? "No documentation")
				let propDeclaration =  """
							```swift
							\(property.declaration)
							```
							"""
				let propSourceFile = "Found in\n* `\(property.sourceFile)`"

				var outDown = """
					\(propTitle)

					\(propType)

					\(propDeclaration)

					\(propInfo)
					"""
				outDown += propSourceFile != foundInBlock.rendered.text ? "\n\n\(propSourceFile)" : ""

				children.append(outDown)
			}
		}

		let tVal = [docHeader, type, declaration, discussion, foundInBlock] + (children.isEmpty ? [MarkdownOut]() : [MarkdownBlock(words: .header(level: 3, text: "Members"), newLines: 2)])
		let markdownOut = MarkdownBlock(tVal, newLines: 2, joinedBy: "")
		var tRender = markdownOut.finalRender

		for child in children {
			tRender += """
				\(child.replacingOccurrences(of: "\n", with: "\n\t"))

				___

				"""
		}

		return tRender
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

protocol MarkdownOut {
	var rendered: (text: String, footerLinks: [URL]) { get }
	var finalRender: String { get }
}

extension MarkdownOut {
	var finalRender: String {
		let tRender = rendered
		let urls = Set(tRender.footerLinks).reduce("") {
			let hash = $1.hashValue
			let formattedString = "[\(hash)]:\($1.path)"
			return $0 + "\n" + formattedString
		}
		return "\(tRender.text)\n\n\(urls)"
	}
}

struct MarkdownBlock: MarkdownOut {
	let markdowns: [MarkdownOut]
	let newLines: Int
	let joined: String

	var rendered: (text: String, footerLinks: [URL]) {
		var tMarkdowns = markdowns.reduce((text: "", footerLinks: [URL]()), { (previous, new) in
			let newTuple = new.rendered
			return (previous.text + (!previous.text.isEmpty ? joined : "") + newTuple.text,
					previous.footerLinks + newTuple.footerLinks)
		})
		let newLines = "\n".repeated(count: self.newLines)
		tMarkdowns.text += newLines
		return tMarkdowns
	}

	init(_ markdowns: MarkdownOut ..., newLines: Int = 1, joinedBy joined: String = " ") {
		self.markdowns = markdowns
		self.newLines = newLines
		self.joined = joined
	}

	init(_ markdowns: [MarkdownOut], newLines: Int = 1, joinedBy joined: String = " ") {
		self.markdowns = markdowns
		self.newLines = newLines
		self.joined = joined
	}

	init(words: MarkdownWord ..., newLines: Int = 1, joinedBy joined: String = " ") {
		self.markdowns = words
		self.newLines = newLines
		self.joined = joined
	}
}

struct MarkdownLine: MarkdownOut {
	var rendered: (text: String, footerLinks: [URL]) {
		return markdowns.reduce((text: "", footerLinks: [URL]()), { (previous, new) in
			let newTuple = new.rendered
			return (previous.text + (!previous.text.isEmpty ? joined : "") + newTuple.text,
					previous.footerLinks + newTuple.footerLinks)
		})
	}
	let markdowns: [MarkdownWord]
	let joined: String

	init(_ markdowns: MarkdownWord ..., joinedBy joined: String = " ") {
		self.markdowns = markdowns
		self.joined = joined
	}
}

enum MarkdownWord: CustomStringConvertible, MarkdownOut {
	case italics(text: String)
	case bold(text: String)
	case link(link: URL, text: String)
	case header(level: Int, text: String)
	case orderedListItem(indentation: Int, text: String)
	case unorderedListItem(indentation: Int, text: String)
	case horizontalLine
	case paragraph(text: String)
	case inlineCode(code: String)
	case codeBlock(code: String, syntaxHighlighting: String?)

	var rendered: (text: String, footerLinks: [URL]) {
		var outString = ""
		var footerLink = [URL]()
		
		switch self {
		case .italics(let text):
			outString = "*\(text)*"
		case .bold(let text):
			outString = "**\(text)**"
		case .link(let link, let text):
			outString = "[\(text)][\(link.hashValue)]"
			footerLink = [link]
		case .header(let level, let text):
			let headerLevel = min(max(1, level), 6)
			let hashtags = "#".repeated(count: headerLevel)
			outString = hashtags + " \(text)"
		case .orderedListItem(let indentation, let text):
			let tabs = "\t".repeated(count: indentation)
			outString = tabs + "1. \(text)"
		case .unorderedListItem(let indentation, let text):
			let tabs = "\t".repeated(count: indentation)
			outString = tabs + "* \(text)"
		case .horizontalLine:
			outString = "___"
		case .paragraph(let text):
			outString = text
		case .inlineCode(let code):
			outString = "`\(code)`"
		case .codeBlock(let code, let syntaxHighlighting):
			outString = """
				```\(syntaxHighlighting ?? "")
				\(code)
				```
				"""
		}
		return (outString, footerLink)
	}
	

	var description: String {
		return rendered.text
	}

}
