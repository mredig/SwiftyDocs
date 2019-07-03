//
//  SortedDocController.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/3/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation

class SwiftDocItemController {
	private(set) var docs: [SwiftDocItem] = []

	private let scrapeQueue: OperationQueue = {
		let queue = OperationQueue()
		queue.name = UUID().uuidString
		return queue
	}()

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
//			let declaration = container.docDeclaration ?? (container.parsedDeclaration ?? "")
			let declaration = container.parsedDeclaration ?? "no declaration"

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
									  properties: children,
									  declaration: declaration)
			items.append(newIem)
		}
		return items
	}

	func getDocs(fromPath path: String, completion: @escaping () -> Void) {

		let docScrapeOp = DocScrapeOperation(path: path)
		let docFilesOp = BlockOperation { [weak self] in
			defer { completion() }
			guard let data = docScrapeOp.jsonData else { return }

			do {
				let rootDocs = try JSONDecoder().decode([[String: DocFile]].self, from: data)
				let docs = rootDocs.flatMap { dict -> [DocFile] in
					var flatArray = [DocFile]()
					for (key, doc) in dict {
						var doc = doc
						doc.filePath = URL(fileURLWithPath: key)
						flatArray.append(doc)
					}
					return flatArray
				}
				self?.add(docs: docs)
			} catch {
				NSLog("Error decoding docs: \(error)")
				return
			}
		}

		docFilesOp.addDependency(docScrapeOp)
		scrapeQueue.addOperations([docScrapeOp, docFilesOp], waitUntilFinished: false)
	}
}
