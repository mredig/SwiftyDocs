//
//  AccessControl.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/3/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation

enum AccessControl: Int, Hashable, Comparable, CaseIterable {

	case `private`
	case `fileprivate`
	case `internal`
	case `public`
	case `open`

	static func < (lhs: AccessControl, rhs: AccessControl) -> Bool {
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
