//
//  OrganizedDocs.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/2/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation
import QuickOrderedSet

struct SortedDoc {
//	extension
//	enum
//	class
//	struct
//	protocol

	var extensions = QuickOrderedSet<Extensions>()
	var enums = QuickOrderedSet<Enums>()
	var classes = QuickOrderedSet<Classes>()
	var structs = QuickOrderedSet<Structs>()

}

protocol SwiftDocProtocol {
	var title: String { get }
	var accesibility: String { get }
	var description: String? { get }
	var properties: [SwiftDocProtocol] { get }
}

struct Extensions: SwiftDocProtocol {
	var title: String
	var accesibility: String
	var description: String?
	var properties: [SwiftDocProtocol]
}

struct Enums: SwiftDocProtocol {
	var title: String
	var accesibility: String
	var description: String?
	var properties: [SwiftDocProtocol]
}

struct Classes: SwiftDocProtocol {
	var title: String
	var accesibility: String
	var description: String?
	var properties: [SwiftDocProtocol]
}

struct Structs: SwiftDocProtocol {
	var title: String
	var accesibility: String
	var description: String?
	var properties: [SwiftDocProtocol]
}

struct Protocols: SwiftDocProtocol {
	var title: String
	var accesibility: String
	var description: String?
	var properties: [SwiftDocProtocol]
}
