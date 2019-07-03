//
//  Accessibility.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/3/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation

enum Accessibility: Int, Hashable, Comparable {

	case `private`
	case `fileprivate`
	case `internal`
	case `public`
	case `open`

	static func < (lhs: Accessibility, rhs: Accessibility) -> Bool {
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
