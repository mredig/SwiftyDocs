//
//  DocFile.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/2/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation

/**
This is only used temporarily to read in the JSON from SourceKitten. This JSON is a bit of a mess and therefore this struct has gotten a bit messy. For that reason, I have decided to only make use of it temporarily to generated a slightly friendlier struct format that is nicer to work with.

The process effectively goes like this:
1. SourceKitten compiles the input project and extracts the documentation data
1. SourceKitten outputs JSON data, that is then decoded by this struct.
1. The data is then converted to `SwiftDocItem`s
1. (this reaches beyond the scope of this file here, but as long as I'm detailing the information, here goes:) The data spends most of its time residing in the SwiftDocItem format. This format is recursive to contain child properties, methods, and other types.
1. `SwiftDocItemController` handles the collection of `SwiftDocItems` and many other related tasks, including managing the export of said items.
1. When exporting, SwiftDocItemController facilitates the conversion to Markdown (which happens regardless of output format), collects all files (including dependencies), and outputs them to the desired directory.
*/
struct DocFile: Codable, CustomStringConvertible {
	enum DeCodingKeys: String, CodingKey {
		case topLevelContainers = "key.substructure"
	}
	var filePath: URL?
	var topLevelContainers: [TopLevelContainer]

	typealias TopLevelContainer = DocContainer
	typealias NestedContainer = DocContainer

	struct DocContainer: Codable {
		enum DeCodingKeys: String, CodingKey {
			case accessControl = "key.accessibility"
			case docDeclaration = "key.doc.declaration"
			case parsedDeclaration = "key.parsed_declaration"
			case comment = "key.doc.comment"
			case name = "key.name"
			case kind = "key.kind"
			case inheritedTypes = "key.inheritedtypes"
			case attributes = "key.attributes"
			case nestedContainers = "key.substructure"
		}
		let accessControl: String?
		let docDeclaration: String?
		let parsedDeclaration: String?
		let comment: String?
		let name: String?
		let kind: String
		let inheritedTypes: [InheritedType]?
		let attributes: [Attribute]?
		let nestedContainers: [NestedContainer]?

		init(from aDecoder: Decoder) throws {
			let container = try aDecoder.container(keyedBy: DeCodingKeys.self)

			self.accessControl = try container.decodeIfPresent(String.self, forKey: .accessControl)?.shortenSwiftDocClassificationString()
			self.docDeclaration = try container.decodeIfPresent(String.self, forKey: .docDeclaration)
			self.parsedDeclaration = try container.decodeIfPresent(String.self, forKey: .parsedDeclaration)
			self.comment = try container.decodeIfPresent(String.self, forKey: .comment)
			self.name = try container.decodeIfPresent(String.self, forKey: .name)
			self.kind = try container.decode(String.self, forKey: .kind).shortenSwiftDocClassificationString()
			self.inheritedTypes = try container.decodeIfPresent([InheritedType].self, forKey: .inheritedTypes)
			self.attributes = try container.decodeIfPresent([Attribute].self, forKey: .attributes)
			self.nestedContainers = try container.decodeIfPresent([NestedContainer].self, forKey: .nestedContainers)
		}


		struct InheritedType: Codable {
			let name: String
			enum DeCodingKeys: String, CodingKey {
				case name = "key.name"
			}
			init(from aDecoder: Decoder) throws {
				let container = try aDecoder.container(keyedBy: DeCodingKeys.self)
				self.name = try container.decode(String.self, forKey: .name)
			}
		}

		struct Attribute: Codable {
			let name: String
			enum DeCodingKeys: String, CodingKey {
				case name = "key.attribute"
			}
			init(from aDecoder: Decoder) throws {
				let container = try aDecoder.container(keyedBy: DeCodingKeys.self)
				self.name = try container.decode(String.self, forKey: .name).shortenSwiftDocClassificationString()
			}
		}
	}

	init(from aDecoder: Decoder) throws {
		let container = try aDecoder.container(keyedBy: DeCodingKeys.self)

		self.topLevelContainers = try container.decode([DocContainer].self, forKey: .topLevelContainers)
	}

	var description: String {
		var tStr: String = ""
		for structure in topLevelContainers {
			tStr += "\(structure.name as Any)\n"
		}
		return tStr
	}
}
