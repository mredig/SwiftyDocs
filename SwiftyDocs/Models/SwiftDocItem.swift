//
//  OrganizedDocs.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/2/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation

struct SwiftDocItem: Hashable, CustomStringConvertible {
	enum Kind: Hashable {
		case `extension`, `enum`, `class`, `struct`, `protocol`, other(String)

		static func == (lhs: Kind, rhs: Kind) -> Bool {
			switch lhs {
			case .extension:
				if case .extension = rhs { return true }
			case .enum:
				if case .enum = rhs { return true }
			case .class:
				if case .class = rhs { return true }
			case .struct:
				if case .struct = rhs { return true }
			case .protocol:
				if case .protocol = rhs { return true }
			case .other(let value):
				if case .other(let value2) = rhs, value == value2 { return true }
			}
			return false
		}

		var stringValue: String {
			switch self {
			case .extension: return "extension"
			case .enum: return "enum"
			case .class: return "class"
			case .struct: return "struct"
			case .protocol: return "protocol"
			case .other(let value): return value
			}
		}

		static func createFrom(string: String) -> Kind {
			switch string.lowercased() {
			case "extension": return .extension
			case "enum": return .enum
			case "class": return .class
			case "struct": return .struct
			case "protocol": return .protocol
			default: return .other(string.lowercased())
			}
		}
	}

	enum Accessibility: Int, Hashable, Comparable {

		case `private`
		case `fileprivate`
		case `internal`
		case `public`
		case `open`

		static func < (lhs: SwiftDocItem.Accessibility, rhs: SwiftDocItem.Accessibility) -> Bool {
			return lhs.rawValue < rhs.rawValue
		}

		var stringValue: String {
			switch self {
			case .private: return "private"
			case .fileprivate: return "fileprivate"
			case .internal: return "internal"
			case .public: return "public"
			case .open: return "open"
			}
		}

		static func createFrom(string: String) -> Accessibility {
			switch string.lowercased() {
			case "private": return .private
			case "fileprivate": return .fileprivate
			case "internal": return .internal
			case "public": return .public
			case "open": return .open
			default: return .internal
			}
		}
	}

	let title: String
	let accessibility: Accessibility
	let comment: String?
	let sourceFile: String
	let kind: Kind
	let properties: [SwiftDocItem]?
	let declaration: String

	var description: String {
		return """
			\(title) (\(accessibility.stringValue))
			\(kind.stringValue)
			\(declaration)
			\(comment ?? "no description")
			sourced from \(sourceFile)

			\(properties ?? [])

			"""
	}
}

extension SwiftDocItem {
	init(title: String, accessibility: String, comment: String?, sourceFile: String, kind: Kind, properties: [SwiftDocItem]?, declaration: String) {
		let accessibility = Accessibility.createFrom(string: accessibility)
		self.init(title: title, accessibility: accessibility, comment: comment, sourceFile: sourceFile, kind: kind, properties: properties, declaration: declaration)
	}
}
