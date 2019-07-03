//
//  StringMap.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/2/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation

extension String {

	private static let mappings = [
		"source.lang.swift.accessibility.private": "private",
		"source.lang.swift.accessibility.fileprivate": "fileprivate",
		"source.lang.swift.accessibility.internal": "internal",
		"source.lang.swift.accessibility.public": "public",
		"source.lang.swift.accessibility.open": "open",

		"source.lang.swift.decl.var.instance": "instance property",

		"source.lang.swift.decl.class": "class",
		"source.lang.swift.decl.enumelement": "enum element",
		"source.lang.swift.decl.enumcase": "enum case",
		"source.lang.swift.decl.enum": "enum",
		"source.lang.swift.decl.function.subscript": "subscript",
		"source.lang.swift.decl.function.method.instance": "instance method",
		"source.lang.swift.decl.var.local": "local",
		"source.lang.swift.decl.var.static": "static",
		"source.lang.swift.decl.function.method.static": "static",
		"source.lang.swift.syntaxtype.comment.mark": "mark",
		"source.lang.swift.decl.generic_type_param": "generic type parameter",
		"source.lang.swift.decl.protocol": "protocol",
		"source.lang.swift.decl.extension": "extension",
		"source.lang.swift.decl.struct": "struct",

		"source.decl.attribute.convenience": "convenience",
		"source.decl.attribute.lazy": "lazy",
		"source.decl.attribute.open": "open",
		"source.decl.attribute.fileprivate": "fileprivate",
		"source.decl.attribute.public": "public",
		"source.decl.attribute.private": "private",
		"source.decl.attribute.setter_access.private": "private(set)",
		"source.decl.attribute.final": "final",
		"source.decl.attribute.discardableResult": "discardable result",

	]

	func shortenSwiftDocClassificationString(useInterpretation: Bool = false) -> String {
		let rStr = String.mappings[self, default: ""]
		if rStr.isEmpty {
			NSLog("No interpretation for: '\(self)'")
			if useInterpretation {
				return self.split(separator: ".").map { String($0) }.last ?? rStr
			} else {
				return self
			}
		}
		return rStr
	}
}
