//
//  TypeKind.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/4/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation

/**
Differentiates types of Types.
*/
enum TypeKind: Hashable {
	case `extension`, `enum`, `class`, `struct`, `protocol`, globalFunc, `typealias`, other(String)

	/**
	Equatable implementation.
	*/
	static func == (lhs: TypeKind, rhs: TypeKind) -> Bool {
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
		case .globalFunc:
			if case .globalFunc = rhs { return true }
		case .typealias:
			if case .typealias = rhs { return true }
		case .other(let value):
			if case .other(let value2) = rhs, value == value2 { return true }
		}
		return false
	}

	/**
	Types that reside at the top level of the exported document.
	*/
	static let topLevelCases: [TypeKind] = [.extension, .enum, .class, .struct, .protocol, .globalFunc, .typealias]

	/**
	A string value associated with each type.
	*/
	var stringValue: String {
		switch self {
		case .extension: return "extension"
		case .enum: return "enum"
		case .class: return "class"
		case .struct: return "struct"
		case .protocol: return "protocol"
		case .globalFunc: return "global func"
		case .typealias: return "typealias"
		case .other(let value): return value
		}
	}

	/**
	docset specific strings to properly classify types in a docset.
	*/
	var docSetType: String {
		switch self {
		case .extension: return "Extension"
		case .enum: return "Enum"
		case .class: return "Class"
		case .struct: return "Struct"
		case .protocol: return "Protocol"
		case .globalFunc: return "Function"
		case .typealias: return "Alias"
		case .other(let value):
			let last = String(value.split(separator: " ").last ?? Substring(""))
			return last.capitalized
		}
	}

	/**
	Creates and returns a new `TypeKind` from a given string. These strings should match output from the String extension implementation of `shortenSwiftDocClassificationString`
	*/
	static func createFrom(string: String) -> TypeKind {
		switch string.lowercased() {
		case "extension": return .extension
		case "enum": return .enum
		case "class": return .class
		case "struct": return .struct
		case "protocol": return .protocol
		case "global func": return .globalFunc
		case "typealias": return .typealias
		default: return .other(string.lowercased())
		}
	}
}
