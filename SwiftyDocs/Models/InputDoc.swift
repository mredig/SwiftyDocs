//
//  DocFile.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/2/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation

struct DocFile: Codable, CustomStringConvertible {
	enum DeCodingKeys: String, CodingKey {
		case topLevelContainers = "key.substructure"
	}
	var filePath: URL?
	var topLevelContainers: [TopLevelContainer]


	struct TopLevelContainer: Codable {
		enum DeCodingKeys: String, CodingKey {
			case accessibility = "key.accessibility"
			case docDeclaration = "key.doc.declaration"
			case parsedDeclaration = "key.parsed_declaration"
			case comment = "key.doc.comment"
			case name = "key.name"
			case kind = "key.kind"
			case inheritedTypes = "key.inheritedtypes"
			case attributes = "key.attributes"
			case nestedContainers = "key.substructure"
		}
		let accessibility: String?
		let docDeclaration: String?
		let parsedDeclaration: String?
		let comment: String?
		let name: String?
		let kind: String?
		let inheritedTypes: [InheritedType]?
		let attributes: [Attribute]?
		let nestedContainers: [NestedContainer]?

		init(from aDecoder: Decoder) throws {
			let container = try aDecoder.container(keyedBy: DeCodingKeys.self)

			self.accessibility = try container.decodeIfPresent(String.self, forKey: .accessibility)?.shortenSwiftDocClassificationString()
			self.docDeclaration = try container.decodeIfPresent(String.self, forKey: .docDeclaration)
			self.parsedDeclaration = try container.decodeIfPresent(String.self, forKey: .parsedDeclaration)
			self.comment = try container.decodeIfPresent(String.self, forKey: .comment)
			self.name = try container.decodeIfPresent(String.self, forKey: .name)
			self.kind = try container.decodeIfPresent(String.self, forKey: .kind)?.shortenSwiftDocClassificationString()
			self.inheritedTypes = try container.decodeIfPresent([InheritedType].self, forKey: .inheritedTypes)
			self.attributes = try container.decodeIfPresent([Attribute].self, forKey: .attributes)
			self.nestedContainers = try container.decodeIfPresent([NestedContainer].self, forKey: .nestedContainers)
		}

		typealias NestedContainer = TopLevelContainer

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

		self.topLevelContainers = try container.decode([TopLevelContainer].self, forKey: .topLevelContainers)
	}

	var description: String {
		var tStr: String = ""
		for structure in topLevelContainers {
			tStr += "\(structure.name)\n"
		}
		return tStr
	}
}
