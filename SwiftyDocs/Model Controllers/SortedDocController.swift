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

	var classesIndex: [SwiftDocItem] {
		return search(forTitle: nil, ofKind: .class, withMinimumAccessibility: minimumAccessibility)
	}
	var structsIndex: [SwiftDocItem] {
		return search(forTitle: nil, ofKind: .struct, withMinimumAccessibility: minimumAccessibility)
	}
	var enumsIndex: [SwiftDocItem] {
		return search(forTitle: nil, ofKind: .enum, withMinimumAccessibility: minimumAccessibility)
	}
	var protocolsIndex: [SwiftDocItem] {
		return search(forTitle: nil, ofKind: .protocol, withMinimumAccessibility: minimumAccessibility)
	}
	var extensionsIndex: [SwiftDocItem] {
		return search(forTitle: nil, ofKind: .extension, withMinimumAccessibility: minimumAccessibility)
	}
	var globalFuncsIndex: [SwiftDocItem] {
		return search(forTitle: nil, ofKind: .globalFunc, withMinimumAccessibility: minimumAccessibility)
	}
	var typealiasIndex: [SwiftDocItem] {
		return search(forTitle: nil, ofKind: .typealias, withMinimumAccessibility: minimumAccessibility)
	}
	

	var minimumAccessibility = Accessibility.internal


	private let scrapeQueue: OperationQueue = {
		let queue = OperationQueue()
		queue.name = UUID().uuidString
		return queue
	}()

	init() {}

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

	func clear() {
		docs.removeAll()
	}

	func getDocItemsFrom(containers: [DocFile.DocContainer]?, sourceFile: String, parentName: String = "") -> [SwiftDocItem]? {
		guard let containers = containers else { return nil }

		var items = [SwiftDocItem]()
		for container in containers {
			let kind = SwiftDocItem.Kind.createFrom(string: container.kind)

			// special case for enum cases
			if case .other(let value) = kind, value == "enum case" {
				guard let newArrayWrappedItem = getDocItemsFrom(containers: container.nestedContainers,
																sourceFile: sourceFile,
																parentName: parentName)
																else { continue }
				items += newArrayWrappedItem
				continue
			}

			guard let name = container.name,
				let accessibility = container.accessibility
				else { continue }

			// recursively get all children
			let children = getDocItemsFrom(containers: container.nestedContainers, sourceFile: sourceFile, parentName: name)
			
			// prefer parsed declaration over doc declaration
			let declaration = container.parsedDeclaration ?? (container.docDeclaration ?? "no declaration")


			let newTitle: String
			switch kind {
			case .other(_):
				newTitle = name
			default:
				newTitle = parentName.isEmpty ? name : parentName + "." + name
			}

			let newIem = SwiftDocItem(title: newTitle,
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

	func search(forTitle title: String?, ofKind kind: SwiftDocItem.Kind?, withMinimumAccessibility minimumAccessibility: Accessibility = .internal) -> [SwiftDocItem] {
		var output = docs.enumeratedChildren().filter { $0.accessibility >= minimumAccessibility }

		if let title = title {
			let titleLC = title.lowercased()
			output = output.filter { $0.title.lowercased().contains(titleLC) }
		}

		if let kind = kind {
			output = output.filter { $0.kind == kind }
		}

		return output
	}
}
