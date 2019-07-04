//
//  SortedDocController.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/3/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation

class SwiftDocItemController {

	// MARK: - properties
	private(set) var docs: [SwiftDocItem] = []

	var classesIndex: [SwiftDocItem] {
		return search(forTitle: nil, ofKind: .class, withMinimumAccessControl: .private)
	}
	var structsIndex: [SwiftDocItem] {
		return search(forTitle: nil, ofKind: .struct, withMinimumAccessControl: .private)
	}
	var enumsIndex: [SwiftDocItem] {
		return search(forTitle: nil, ofKind: .enum, withMinimumAccessControl: .private)
	}
	var protocolsIndex: [SwiftDocItem] {
		return search(forTitle: nil, ofKind: .protocol, withMinimumAccessControl: .private)
	}
	var extensionsIndex: [SwiftDocItem] {
		return search(forTitle: nil, ofKind: .extension, withMinimumAccessControl: .private)
	}
	var globalFuncsIndex: [SwiftDocItem] {
		return search(forTitle: nil, ofKind: .globalFunc, withMinimumAccessControl: .private)
	}
	var typealiasIndex: [SwiftDocItem] {
		return search(forTitle: nil, ofKind: .typealias, withMinimumAccessControl: .private)
	}

	var topLevelIndex: [SwiftDocItem] {
		return classesIndex + structsIndex + enumsIndex + protocolsIndex + extensionsIndex + globalFuncsIndex + typealiasIndex
	}
	var toplevelIndexMinAccess: [SwiftDocItem] {
		return topLevelIndex.filter { $0.accessControl >= minimumAccessControl }
	}

	var minimumAccessControl = AccessControl.internal

	var projectURL: URL?
	var projectDirectoryURL: URL? {
		return projectURL?.deletingLastPathComponent()
	}
	var projectReadmeURL: URL? {
		guard let directoryURL = projectDirectoryURL else { return nil }
		do {
			let contents = try FileManager.default.contentsOfDirectory(atPath: directoryURL.path)
			let lcContents: [(original: String, lowercase: String)] = contents.map { ($0, $0.lowercased()) }
			let readmeMarkdown = lcContents.first { (original: String, lowercase: String) -> Bool in
				let exists = lowercase == "readme.md"
				return exists
			}
			let readmeNoMarkdown = lcContents.first { (original: String, lowercase: String) -> Bool in
				let exists = lowercase == "readme"
				return exists
			}

			if let readmeMarkdown = readmeMarkdown {
				return directoryURL.appendingPathComponent(readmeMarkdown.original)
			}
			if let readmeNoMarkdown = readmeNoMarkdown {
				return directoryURL.appendingPathComponent(readmeNoMarkdown.original)
			}

		} catch {
			NSLog("Error getting project directory files: \(error)")
		}
		return nil
	}
	private var _projectTitle: String?
	var projectTitle: String {
		get {
			return _projectTitle ?? (projectURL?.deletingPathExtension().lastPathComponent ?? "Documentation")
		}
		set {
			_projectTitle = newValue
			if newValue.isEmpty {
				_projectTitle = nil
			}
		}
	}

	private let markdownGenerator = MarkdownGenerator()

	private let scrapeQueue: OperationQueue = {
		let queue = OperationQueue()
		queue.name = UUID().uuidString
		return queue
	}()

	// MARK: - inits

	init() {}

	// MARK: - CRUD
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

		var sourceFile = sourceFile
		if let projectDir = projectDirectoryURL {
			let baseDir = projectDir.path
			sourceFile = sourceFile.replacingOccurrences(of: baseDir, with: "")
				.replacingOccurrences(of: ##"^\/"##, with: "", options: .regularExpression, range: nil)
		}

		var items = [SwiftDocItem]()
		for container in containers {
			let kind = TypeKind.createFrom(string: container.kind)

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
				let accessControl = container.accessControl
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
									  accessControl: accessControl,
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

	func search(forTitle title: String?, ofKind kind: TypeKind?, withMinimumAccessControl minimumAccessControl: AccessControl = .internal) -> [SwiftDocItem] {
		var output = docs.enumeratedChildren().filter { $0.accessControl >= minimumAccessControl }

		if let title = title {
			let titleLC = title.lowercased()
			output = output.filter { $0.title.lowercased().contains(titleLC) }
		}

		if let kind = kind {
			output = output.filter { $0.kind == kind }
		}

		return output
	}

	// MARK: - Saving

	func saveSingleFile(to path: URL, format: SaveFormat) {
		let index = markdownIndex(with: .singlePage)
		var text = toplevelIndexMinAccess.map { markdownPage(for: $0) }.joined(separator: "\n\n\n")
		text = index + "\n\n" + text
		if format == .html {
			text = text.replacingOccurrences(of: ##"</div>"##, with: ##"<\/div>"##)
			text = wrapInHTML(withTitle: projectTitle, string: text, dependenciesUpDir: false)
		}

		var outPath = path
		switch format {
		case .html:
			saveDependencyPackage(to: outPath, linkStyle: .singlePage)
			outPath.appendPathComponent("index")
			outPath.appendPathExtension("html")
		case .markdown:
			outPath.appendPathExtension("md")
		}

		do {
			try text.write(to: outPath, atomically: true, encoding: .utf8)
		} catch {
			NSLog("Failed to save file: \(error)")
		}
	}

	func saveMultifile(to path: URL, format: SaveFormat) {
		var index = markdownIndex(with: .multiPage)

		saveDependencyPackage(to: path, linkStyle: .multiPage)

		let fileExt = format == .html ? "html" : "md"

		// save all doc files
		toplevelIndexMinAccess.forEach {
			var markdown = markdownPage(for: $0)
			if format == .html {
				markdown = sanitizeForHTMLEmbedding(string: markdown)
				markdown = wrapInHTML(withTitle: $0.title, string: markdown, dependenciesUpDir: true)
			}
			let outPath = path
				.appendingPathComponent($0.kind.stringValue.replacingNonWordCharacters())
				.appendingPathComponent($0.title.replacingNonWordCharacters(lowercased: false))
				.appendingPathExtension(fileExt)
			do {
				try markdown.write(to: outPath, atomically: true, encoding: .utf8)
			} catch {
				NSLog("Failed writing file: \(error)")
			}
		}
		// save contents/index file
		do {
			let indexURL = path
				.appendingPathComponent("contents")
				.appendingPathExtension(fileExt)
			if format == .html {
				index = sanitizeForHTMLEmbedding(string: index)
				index = wrapInHTML(withTitle: projectTitle, string: index, dependenciesUpDir: false)
			}
			try index.write(to: indexURL, atomically: true, encoding: .utf8)
		} catch {
			NSLog("Failed writing file: \(error)")
		}
	}

	func saveDependencyPackage(to path: URL, linkStyle: OutputStyle) {
		guard var jsURLs = Bundle.main.urls(forResourcesWithExtension: "js", subdirectory: nil, localization: nil) else { return }
		guard let maps = Bundle.main.urls(forResourcesWithExtension: "map", subdirectory: nil, localization: nil) else { return }
		jsURLs += maps

		guard let cssURLs = Bundle.main.urls(forResourcesWithExtension: "css", subdirectory: nil, localization: nil) else { return }

		let subdirs: [String]
		switch linkStyle {
		case .multiPage:
			subdirs = (TypeKind.topLevelCases.map { $0.stringValue }
				.joined(separator: "-") + "-css-js")
				.split(separator: "-")
				.map { String($0).replacingNonWordCharacters() }
		case .singlePage:
			subdirs = "css js"
				.split(separator: " ")
				.map { String($0) }
		}

		let subdirURLs = [path] + subdirs.map { path.appendingPathComponent($0) }

		let fm = FileManager.default
		do {
			if fm.fileExists(atPath: path.path) {
				try fm.removeItem(at: path)
			}
			for subdirURL in subdirURLs {
				try fm.createDirectory(atPath: subdirURL.path, withIntermediateDirectories: true, attributes: nil)
			}
			for jsURL in jsURLs {
				try fm.copyItem(at: jsURL, to: path.appendingPathComponent("js").appendingPathComponent(jsURL.lastPathComponent))
			}
			for cssURL in cssURLs {
				try fm.copyItem(at: cssURL, to: path.appendingPathComponent("css").appendingPathComponent(cssURL.lastPathComponent))
			}

		} catch {
			NSLog("Error creating dependency package: \(error)")
		}
	}

	// MARK: - Markdown Generation

	func markdownPage(for doc: SwiftDocItem) -> String {
		return markdownGenerator.generateMarkdownDocumentString(fromRootDocItem: doc, minimumAccessControl: minimumAccessControl)
	}

	func markdownIndex(with linkStyle: OutputStyle) -> String {
		return markdownGenerator.generateMarkdownIndex(fromTopLevelIndex: topLevelIndex, minimumAccessControl: minimumAccessControl, linkStyle: linkStyle)
	}

	private func sanitizeForHTMLEmbedding(string: String) -> String {
		return string.replacingOccurrences(of: ##"</div>"##, with: ##"<\/div>"##)
	}

	private func wrapInHTML(withTitle title: String, string: String, dependenciesUpDir: Bool) -> String {
		return String.htmlOutputBefore(withTitle: title, dependenciesUpADir: dependenciesUpDir)
			+ string
			+ String.htmlOutputAfter(dependenciesUpADir: dependenciesUpDir)
	}
}
