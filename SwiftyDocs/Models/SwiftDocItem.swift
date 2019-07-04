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
	let declaration: String

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
}

extension SwiftDocItem {
	init(title: String, accessControl: String, comment: String?, sourceFile: String, kind: TypeKind, properties: [SwiftDocItem]?, declaration: String) {
		let accessControl = AccessControl.createFrom(string: accessControl)
		self.init(title: title, accessControl: accessControl, comment: comment, sourceFile: sourceFile, kind: kind, properties: properties, declaration: declaration)
	}
}
