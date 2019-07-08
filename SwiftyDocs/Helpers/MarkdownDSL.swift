//
//  MarkdownDSL.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/7/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation


public enum MDNode: CustomStringConvertible {
	public enum MDAttribute {
		case indentation(Int)
		case linkURL(URL)
		case newlinePrefix(Int)
	}

	public enum MDType {
		case inline
		case block
	}

	// make sure this is an inline value
	public var description: String {
		let rendered = render(inlineLinks: true)
		return rendered.text
	}

	static var linkCache = Set<URL>()

	var type: MDType? {
		if case .element(_, let type, _, _) = self {
			return type
		}
		return nil
	}

	var text: String? {
		if case .element(let text, _, _, _) = self {
			return text
		}
		return nil
	}

	func finalRender(inlineLinks: Bool = false) -> String {
		let tuple = render(inlineLinks: inlineLinks)
		let links = MDNode.linkCache.map { "[\($0.hashValue)]:\($0)" }.joined(separator: "\n")
		MDNode.linkCache.removeAll()
		let cleaned = cleanupRender(renderedString: tuple.text)

		return cleaned + "\n" + links
	}

	func render(inheritedIndentation: Int = 0, parent: MDNode? = nil, inlineLinks: Bool = false) -> (text: String, links: [URL]) {
		switch self {
		case .element(let text, let type, let attrs, let children):
			var rVal = text

			var links = attrs.getLinks()
			if links.count == 1 {
				if inlineLinks {
					rVal += "(\(links[0].absoluteString))"
					links.removeAll()
				} else {
					rVal += "[\(links[0].hashValue)]"
				}
			}

			if type == .block {
				rVal += "\n"
			}
			let additionalIndentation = "\t".repeated(count: attrs.getIndentation())
			rVal = "\(additionalIndentation)\(rVal)"

			let childRender = children.render(inheritedIndentation: inheritedIndentation + 1, parent: self, inlineLinks: inlineLinks)
			rVal += childRender.text
			links += childRender.links
			return (rVal, links)

		case .indentedCollection(let nodes):
			var rVal = ""
			var links = [URL]()
			for node in nodes {
				let rendered = node.render(inheritedIndentation: inheritedIndentation, parent: self)
				if rVal.last == "\n" || rVal.isEmpty {
					rVal += "\t".repeated(count: inheritedIndentation)
				}
				rVal += rendered.text
				links += rendered.links
			}
			return (rVal, links)

		case .nonIndentedCollection(let nodes):
			var rVal = ""
			var links = [URL]()
			for node in nodes {
				let rendered = node.render(inheritedIndentation: inheritedIndentation, parent: self)

				rVal += rendered.text + "\n"
				links += rendered.links
			}
			return (rVal, links)
		}
	}

	private func cleanupRender(renderedString: String) -> String {

		var lines = renderedString.split(separator: "\n", maxSplits: Int.max, omittingEmptySubsequences: false)

		var previousContent = ""
		var linesSinceContent = 0

		var linesToRemove = [Int]()

		for (index, line) in lines.enumerated() {
			let content = line.trimmingCharacters(in: .whitespacesAndNewlines)
			// if has content
			if !content.isEmpty {
				// if both this line and the previous line of content are lists...
				if content.hasPrefix("1. ") || content.hasPrefix("* ") {
					if previousContent.hasPrefix("1. ") || previousContent.hasPrefix("* ") {
						for count in (1..<linesSinceContent + 1).reversed() {
							// remove excess newlines
							linesToRemove.append(index - count)
						}
					}
				}
				// set state for next loop
				previousContent = content
				linesSinceContent = 0
			} else {
				linesSinceContent += 1
			}
		}

		for indexToRemove in linesToRemove.reversed() {
			lines.remove(at: indexToRemove)
		}

		return lines.joined(separator: "\n")
	}


	indirect case element(String, MDType, [MDAttribute], MDNode)
	case nonIndentedCollection([MDNode])
	case indentedCollection([MDNode])
}

extension Array where Element == MDNode.MDAttribute {
	public func getLinks() -> [URL] {
		return self.reduce([URL]()) {
			if case .linkURL(let url) = $1 {
				return $0 + [url]
			}
			return $0
		}
	}

	public func getIndentation() -> Int {
		return self.reduce(0) {
			if case .indentation(let value) = $1 {
				return $0 + value
			}
			return $0
		}
	}
}

extension MDNode {
	public static func document(_ children: MDNode...) -> MDNode {
		return nonIndentedCollection(children)
	}

	public static func element(_ value: String, _ type: MDType, attributes: [MDAttribute], _ children: MDNode...) -> MDNode {
		return .element(String(describing: value), type, attributes, .indentedCollection(children))
	}

	public static func header(_ headerValue: Int, _ text: String) -> MDNode {
		let headerValue = min(max(headerValue, 1), 6)
		let hashTags = "#".repeated(count: headerValue)
		return .element("\(hashTags) \(text)", .block, attributes: [], .indentedCollection([]) )
	}

	public static func paragraph(_ text: String, indentation: Int = 0) -> MDNode {
		return .element(text, .block, [.indentation(indentation)], .indentedCollection([]))
	}

	public static func paragraphWithInlineElements(_ elements: [MDNode], indentation: Int = 0) -> MDNode {
		let value = elements.map { $0.render().text }.joined(separator: " ")
		return .element(value, .block, [.indentation(indentation)], .indentedCollection([]))
	}

	public static func text(_ text: String, indentation: Int = 0) -> MDNode {
		return .element(text, .inline, [.indentation(indentation)], .indentedCollection([]))
	}

	public static func unorderedListItem(_ text: String, _ children: MDNode ..., indentation: Int = 0) -> MDNode {
		return .element("* \(text)", .block, [.indentation(indentation)], .indentedCollection(children))
	}

	public static func orderedListItem(_ text: String, _ children: MDNode ..., indentation: Int = 0) -> MDNode {
		return .element("1. \(text)", .block, [.indentation(indentation)], .indentedCollection(children))
	}

	public static func codeBlock(_ text: String, syntax: String = "", indentation: Int = 0) -> MDNode {
		return .element("```\(syntax)\n\(text)\n```", .block, [.indentation(indentation)], .indentedCollection([]))
	}

	public static func line(_ children: MDNode ...) -> MDNode {
		return .nonIndentedCollection(children)
	}

	public static func link(_ text: String, _ destination: String) -> MDNode {
		let url = URL(string: destination) ?? URL(string: "#")!
		MDNode.linkCache.insert(url)
		return .element("[\(text)]", .inline, [.linkURL(url)], .indentedCollection([]))
	}

	public static func italics(_ text: String) -> MDNode {
		return .element("*\(text)*", .inline, [], .indentedCollection([]))
	}

	public static func bold(_ text: String) -> MDNode {
		return .element("**\(text)**", .inline, [], .indentedCollection([]))
	}

	public static func boldItalics(_ text: String) -> MDNode {
		return .element("***\(text)***", .inline, [], .indentedCollection([]))
	}

	public static func newline() -> MDNode {
		return .element("\n", .inline, [], .indentedCollection([]))
	}

	public func appending(linkText name: String, destination: String) -> MDNode {
		return MDNode.nonIndentedCollection([self, .link(name, destination)])
	}
}
