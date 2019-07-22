//
//  AccessControl.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/3/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation

/**
Enum cases for each level of access control within Swift.
*/
enum AccessControl: Int, Hashable, Comparable, CaseIterable {

	case `private`
	case `fileprivate`
	case `internal`
	case `public`
	case `open`

	/**
	Compares two access levels to see which is greater.
	*/
	static func < (lhs: AccessControl, rhs: AccessControl) -> Bool {
		return lhs.rawValue < rhs.rawValue
	}

	/**
	The string value associated with the AccessControl. (necessary because it cannot conform to multiple raw types)
	*/
	var stringValue: String {
		switch self {
		case .private: return "private"
		case .fileprivate: return "fileprivate"
		case .internal: return "internal"
		case .public: return "public"
		case .open: return "open"
		}
	}

	/**
	Creates and returns a new `AccessControl` item based on an input string. The string should match exactly as it's written within Swift, but defaults to `internal` when the string isn't properly formatted.
	*/
	static func createFrom(string: String) -> AccessControl {
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
