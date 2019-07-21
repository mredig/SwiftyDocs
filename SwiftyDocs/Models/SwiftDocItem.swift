//
//  OrganizedDocs.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/2/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation

/**
This is where the documentation data will spend most of its time. The data is first imported through the `InputDoc` struct before sitting here until it finally gets exported.

This data type is recursive and can contain children of the same type. As `SwiftDocItem` represents all entities from a class to class/struct properties to a global function and everything in between, it needs to be able to contain the items that descend from it. (A class's properties and methods, for example)
*/
struct SwiftDocItem: Hashable, CustomStringConvertible {
	/// The title of the doc item
	let title: String
	/// The access control of the doc item
	let accessControl: AccessControl
	/// If there is any documetation written for the doc item, it will go here.
	let comment: String?
	/// The file the doc item resides in. This is to help open source contributors to find where an item resides more quickly.
	let sourceFile: String
	/// The kind of the doc item. This is an enum primarily consisting of things like `class`, `enum`, `struct` and similar, but has an `other` option for situations that haven't been anticipated
	let kind: TypeKind
	/// If this item has any children (for example, a class might have properties or methods), this is where they will reside.
	let properties: [SwiftDocItem]?
	/// A list of attributes for the item. This will include things like `lazy`
	let attributes: [String]
	/// The code declaration of the item. This is not always rendered in an expected way, especially in the case of computed properties.
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

	/// The debug output string value
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

	/// A consistent, relative linking path used for html output.
	func htmlLink(format: SaveFormat = .html, output: PageCount) -> String {
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
	/// A convenient initializer
	init(title: String, accessControl: String, comment: String?, sourceFile: String, kind: TypeKind, properties: [SwiftDocItem]?, attributes: [String], docDeclaration: String?, parsedDeclaration: String?) {
		let accessControl = AccessControl.createFrom(string: accessControl)
//		self.init(title: title, accessControl: accessControl, comment: comment, sourceFile: sourceFile, kind: kind, properties: properties, declaration: declaration)
		self.init(title: title, accessControl: accessControl, comment: comment, sourceFile: sourceFile, kind: kind, properties: properties, attributes: attributes, docDeclaration: docDeclaration, parsedDeclaration: parsedDeclaration)
	}
}
