//
//  OrganizedDocs.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/2/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation

struct SwiftDocItem: Hashable, CustomStringConvertible {
	let title: String
	let accessControl: AccessControl
	let comment: String?
	let sourceFile: String
	let kind: TypeKind
	let properties: [SwiftDocItem]?
	let attributes: [String]
	var declaration: String {
		var declaration = parsedDeclaration ?? (docDeclaration ?? "no declaration")
		// unless it is lazy...
		if attributes.contains("lazy") {
			declaration = docDeclaration ?? (parsedDeclaration ?? "no declaration")
		}
		// double check that it's clean output
		return declaration.replacingOccurrences(of: ##"\s+=$"##, with: "", options: .regularExpression, range: nil)
	}

	private let docDeclaration: String?
	private let parsedDeclaration: String?

	var description: String {
		return """
			\(title) (\(accessControl.stringValue))
			\(kind.stringValue)
			\(declaration)
			\(comment ?? "no description")
			sourced from \(sourceFile)

			\(properties ?? [])

			"""
	}

	func htmlLink(format: SaveFormat = .html, output: OutputStyle) -> String {
		let folderValue = kind.stringValue.capitalized.replacingNonWordCharacters()
		let link: String
		switch output {
		case .multiPage:
			let fileExt = format != .markdown ? "html" : "md"
			let fileName = title.replacingNonWordCharacters(lowercased: false) + "." + fileExt
			link = "\(folderValue)/\(fileName)"
		case .singlePage:
			link = "#\(title.replacingNonWordCharacters())"
		}

		return link
	}
}

extension SwiftDocItem {
	init(title: String, accessControl: String, comment: String?, sourceFile: String, kind: TypeKind, properties: [SwiftDocItem]?, attributes: [String], docDeclaration: String?, parsedDeclaration: String?) {
		let accessControl = AccessControl.createFrom(string: accessControl)
//		self.init(title: title, accessControl: accessControl, comment: comment, sourceFile: sourceFile, kind: kind, properties: properties, declaration: declaration)
		self.init(title: title, accessControl: accessControl, comment: comment, sourceFile: sourceFile, kind: kind, properties: properties, attributes: attributes, docDeclaration: docDeclaration, parsedDeclaration: parsedDeclaration)
	}
}
