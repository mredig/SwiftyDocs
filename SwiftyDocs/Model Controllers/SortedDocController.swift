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
	var projectLandingPageURL: URL? {
		guard let directoryURL = projectDirectoryURL else { return nil }
		do {
			let contents = try FileManager.default.contentsOfDirectory(atPath: directoryURL.path)
			let lcContents: [(original: String, lowercase: String)] = contents.map { ($0, $0.lowercased()) }
			let landingPage = lcContents.first { (original: String, lowercase: String) -> Bool in
				let exists = lowercase == "doclandingpage.md"
				return exists
			}
			let readmeMarkdown = lcContents.first { (original: String, lowercase: String) -> Bool in
				let exists = lowercase == "readme.md"
				return exists
			}
			let readmeNoMarkdown = lcContents.first { (original: String, lowercase: String) -> Bool in
				let exists = lowercase == "readme"
				return exists
			}

			if let landingPage = landingPage {
				return directoryURL.appendingPathComponent(landingPage.original)
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
	private let htmlWrapper = HTMLWrapper()

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

			let newTitle: String
			switch kind {
			case .other(_):
				newTitle = name
			default:
				newTitle = parentName.isEmpty ? name : parentName + "." + name
			}

			let strAttributes = container.attributes?.map { $0.name } ?? []

			let newItem = SwiftDocItem(title: newTitle,
									   accessControl: accessControl,
									   comment: container.comment,
									   sourceFile: sourceFile,
									   kind: kind,
									   properties: children,
									   attributes: strAttributes,
									   docDeclaration: container.docDeclaration,
									   parsedDeclaration: container.parsedDeclaration)
			items.append(newItem)
		}
		return items
	}

	func getDocs(from projectDirectory: URL, completion: @escaping () -> Void) {

		let buildPath = projectDirectory.appendingPathComponent("build")
		let buildDirAlreadyExists = FileManager.default.fileExists(atPath: buildPath.path)
		let docScrapeOp = DocScrapeOperation(path: projectDirectory.path)
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
		let cleanupOp = BlockOperation {
			if !buildDirAlreadyExists {
				do {
					try FileManager.default.removeItem(at: buildPath)
				} catch {
					NSLog("Error deleting temp build directory: \(error)")
				}
			}
		}

		docFilesOp.addDependency(docScrapeOp)
		cleanupOp.addDependency(docScrapeOp)
		scrapeQueue.addOperations([docScrapeOp, docFilesOp, cleanupOp], waitUntilFinished: false)
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

	func save(with style: OutputStyle, to path: URL, in format: SaveFormat) {
		switch style {
		case .multiPage:
			saveMultifile(to: path, format: format)
		case .singlePage:
			saveSingleFile(to: path, format: format)
		}
	}

	func saveSingleFile(to path: URL, format: SaveFormat) {
		guard format != .docset else {
			saveDocset(to: path)
			return
		}

		let index = markdownContents(with: .singlePage, in: format)
		var text = toplevelIndexMinAccess.map { markdownPage(for: $0) }.joined(separator: "\n\n\n")
		text = index + "\n\n" + text
		if format == .html {
			text = text.replacingOccurrences(of: ##"</div>"##, with: ##"<\/div>"##)
			text = htmlWrapper.wrapInHTML(markdownString: text, withTitle: projectTitle, cssFile: "stylesDocs", dependenciesUpDir: false)
		}

		var outPath = path
		switch format {
		case .html:
			saveDependencyPackage(to: outPath, linkStyle: .singlePage)
			outPath.appendPathComponent("index")
			outPath.appendPathExtension("html")
		case .markdown:
			outPath.appendPathExtension("md")
		case .docset:
			// not possible to happen, but switch needs to be exhaustive
			break
		}

		do {
			try text.write(to: outPath, atomically: true, encoding: .utf8)
		} catch {
			NSLog("Failed to save file: \(error)")
		}
	}

	func saveMultifile(to path: URL, format: SaveFormat) {
		var contents = markdownContents(with: .multiPage, in: format)
		var landingPageContents = getLandingPageContents()

		saveDependencyPackage(to: path, linkStyle: .multiPage)

		let fileExt = format == .html ? "html" : "md"

		// save all doc files
		toplevelIndexMinAccess.forEach {
			var markdown = markdownPage(for: $0)
			if format == .html {
				markdown = sanitizeForHTMLEmbedding(string: markdown)
				markdown = htmlWrapper.wrapInHTML(markdownString: markdown, withTitle: $0.title, cssFile: "stylesDocs", dependenciesUpDir: true)
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
			let landingPageURL = path
				.appendingPathComponent("doclandingpage")
				.appendingPathExtension(fileExt)
			let indexURL = path
				.appendingPathComponent("index")
				.appendingPathExtension(fileExt)
			let contentsURL = path
				.appendingPathComponent("contents")
				.appendingPathExtension(fileExt)
			if format == .html {
				contents = sanitizeForHTMLEmbedding(string: contents)
				contents = htmlWrapper.wrapInHTML(markdownString: contents, withTitle: projectTitle, cssFile: "stylesContents", dependenciesUpDir: false)
				landingPageContents = sanitizeForHTMLEmbedding(string: landingPageContents)
				landingPageContents = htmlWrapper.wrapInHTML(markdownString: landingPageContents, withTitle: projectTitle, cssFile: "stylesDocs", dependenciesUpDir: false)
				let index = htmlWrapper.generateIndexPage(titled: projectTitle)
				try index.write(to: indexURL, atomically: true, encoding: .utf8)
			}
			try contents.write(to: contentsURL, atomically: true, encoding: .utf8)
			try landingPageContents.write(to: landingPageURL, atomically: true, encoding: .utf8)

		} catch {
			NSLog("Failed writing file: \(error)")
		}
	}

	func saveDocset(to path: URL) {
		let packageDir = path.appendingPathExtension("docset")
		let contentsDir = packageDir.appendingPathComponent("Contents")
		let infoPlistURL = contentsDir.appendingPathComponent("Info.plist")
		let resourcesDir = contentsDir.appendingPathComponent("Resources")
		let sqlIndex = resourcesDir.appendingPathComponent("docSet.dsidx")
		let docsDir = resourcesDir.appendingPathComponent("Documents")

		do {
			try fm.createDirectory(atPath: docsDir.path, withIntermediateDirectories: true, attributes: nil)
		} catch {
			NSLog("There was an error creating the docset directories: \(error)")
		}
		saveMultifile(to: docsDir, format: .html)

		let infoPlistData = createInfoPlist()
		do {
			try infoPlistData.write(to: infoPlistURL)
		} catch {
			NSLog("There was an error writing the Info.plist: \(error)")
		}

		do {
			let sqlController = try SQLController(at: sqlIndex)
			sqlController.initialzeTable()

			let rows = getSQLInfoForRows()
			for row in rows {
				sqlController.addRow(with: row.name, type: row.type, path: row.path)
			}
		} catch {
			NSLog("There was an error creating the SQL Index: \(error)")
		}
	}

	func getLandingPageContents() -> String {
		guard let landingPageURL = projectLandingPageURL else { return "" }
		let contents = (try? String(contentsOf: landingPageURL)) ?? ""
		return contents
	}

	private let fm = FileManager.default
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

		do {
			if fm.fileExists(atPath: path.path) {
				try fm.removeItem(at: path)
			}
		} catch {
			NSLog("Error overwriting previous export: \(error)")
		}
		create(subdirectories: subdirURLs)
		copy(urls: jsURLs, to: path.appendingPathComponent("js"))
		copy(urls: cssURLs, to: path.appendingPathComponent("css"))

		let otherFiles = "localhost.webloc startLocalServer.command Instructions.md"
			.split(separator: " ")
			.map { String($0) }
			.map { Bundle.main.url(forResource: $0, withExtension: nil) }
			.compactMap { $0 }
		copy(urls: otherFiles, to: path)
	}

	private func create(subdirectories: [URL]) {
		for subdirURL in subdirectories {
			do {
				try fm.createDirectory(atPath: subdirURL.path, withIntermediateDirectories: true, attributes: nil)
			} catch {
				NSLog("Error creating subdirectory: \(error)")
			}
		}
	}
	private func copy(urls: [URL], to destination: URL) {
		for url in urls {
			do {
				try fm.copyItem(at: url, to: destination.appendingPathComponent(url.lastPathComponent))
			} catch {
				NSLog("Error copying package file: \(error)")
			}
		}
	}

	private func getSQLInfoForRows() -> [(name: String, type: String, path: String)] {
		var rows: [(name: String, type: String, path: String)] = []

		var currentTitle = ""

		for item in (topLevelIndex.sorted { $0.kind.stringValue < $1.kind.stringValue }) {
			guard item.accessControl >= minimumAccessControl else { continue }
			if currentTitle != item.kind.stringValue.capitalized {
				currentTitle = item.kind.stringValue.capitalized
			}
			let folderValue = currentTitle.replacingNonWordCharacters()
			let linkValue = item.title.replacingNonWordCharacters(lowercased: false) + ".html"

			let name = item.title
			let type = item.kind.docSetType
			let path = "\(folderValue)/\(linkValue)"
			rows.append((name, type, path))
		}

		return rows
	}

	// MARK: - info plist generation

	private func createInfoPlist() -> Data {
		let cleanProjectTitle = projectTitle.replacingNonWordCharacters()

		let infoPlist = InfoPlistModel(bundleID: "com.swiftdocs.\(cleanProjectTitle)",
									bundleName: projectTitle,
									platformFamily: cleanProjectTitle.lowercased(),
									dashIndexFilePath: "doclandingpage.html",
									dashDocSetFamily: "dashtoc")

		let encoder = PropertyListEncoder()
		do {
			let data = try encoder.encode(infoPlist)
			return data
		} catch {
			NSLog("Error creating info.plist: \(error)")
		}

		return Data()
	}

	// MARK: - Markdown Generation

	func markdownPage(for doc: SwiftDocItem) -> String {
		return markdownGenerator.generateMarkdownDocumentString(fromRootDocItem: doc, minimumAccessControl: minimumAccessControl)
	}

	func markdownContents(with linkStyle: OutputStyle, in format: SaveFormat) -> String {
		return markdownGenerator.generateMarkdownContents(fromTopLevelIndex: topLevelIndex,
													   minimumAccessControl: minimumAccessControl,
													   linkStyle: linkStyle,
													   format: format)
	}

	private func sanitizeForHTMLEmbedding(string: String) -> String {
		var rVal = string.replacingOccurrences(of: ##"</div>"##, with: ##"<\/div>"##)

		let ranges = rVal.ranges(of: ##"`.*?`"##, options: .regularExpression, range: nil, locale: nil)
		let allowedSet = CharacterSet(charactersIn: "<>").inverted
		for range in ranges.reversed() {
			guard let newValue = rVal[range].addingPercentEncoding(withAllowedCharacters: allowedSet) else { continue }
			rVal.replaceSubrange(range, with: newValue)
		}

		return rVal
	}
}
