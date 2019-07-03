//
//  SortedDocController.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/3/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation

class SwiftDocItemController {
	var docs: [SwiftDocItem] = []

	init() {}

	init(docs: [DocFile]) {
		add(docs: docs)
	}

	func add(docs: [DocFile]) {
		for doc in docs {
			add(doc: doc)
		}
	}

	func add(doc: DocFile) {
		guard let items = getDocItemsFrom(containers: doc.topLevelContainers,
										  sourceFile: doc.filePath?.path ?? "")
																else { return }
		docs.append(contentsOf: items)
	}

	func getDocItemsFrom(containers: [DocFile.TopLevelContainer]?, sourceFile: String, parentName: String = "") -> [SwiftDocItem]? {
		guard let containers = containers else { return nil }

		var items = [SwiftDocItem]()
		for container in containers {
			guard let title = container.name,
				let accessibility = container.accessibility
				else { continue }
			let children = getDocItemsFrom(containers: container.nestedContainers, sourceFile: sourceFile, parentName: title)

			let kind: SwiftDocItem.Kind
			switch container.kind {
			case "class":
				kind = .class
			case "extension":
				kind = .extension
			case "struct":
				kind = .struct
			case "enum":
				kind = .enum
			case "protocol":
				kind = .protocol
			default:
				kind = .other(container.kind)
			}

			let newIem = SwiftDocItem(title: parentName.isEmpty ? title : parentName + "." + title,
									  accessibility: accessibility,
									  comment: container.comment,
									  sourceFile: sourceFile,
									  kind: kind,
									  properties: children)
			items.append(newIem)
		}
		return items
	}
}
