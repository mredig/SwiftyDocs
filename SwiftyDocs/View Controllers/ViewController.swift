//
//  ViewController.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/2/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Cocoa
import SourceKittenFramework

class ViewController: NSViewController {

	var directoryURL: URL?

	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view.
	}

	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}

	@IBAction func buttonPressed(_ sender: NSButton) {
		openProjectDialog()
	}

	func openProjectDialog() {
		let openPanel = NSOpenPanel()
		openPanel.canChooseFiles = true
		openPanel.canChooseDirectories = false
		openPanel.allowsMultipleSelection = false
		openPanel.allowedFileTypes = ["xcodeproj"]

		openPanel.begin { [weak self] (result) in
			if result == NSApplication.ModalResponse.OK {
				guard let fileURL = openPanel.url else { fatalError("Open dialog didn't include a file URL") }

				let projectDir = fileURL.deletingLastPathComponent()
				self?.directoryURL = projectDir
				let module = Module(xcodeBuildArguments: [], inPath: projectDir.path)

				if let docs = module?.docs {
					let docString = docs.description

					guard let data = docString.data(using: .utf8) else { return }

					do {
						let rootDocs = try JSONDecoder().decode([[String: DocFile]].self, from: data)
						let docs = rootDocs.flatMap { dict -> [DocFile] in
							var returnArray = [DocFile]()
							for (key, doc) in dict {
								var doc = doc
								doc.filePath = URL(fileURLWithPath: key)
								returnArray.append(doc)
							}
							return returnArray
						}

//						let encoder = JSONEncoder()
//						encoder.outputFormatting = .prettyPrinted
//						let encoded = try encoder.encode(docs)
//						let test = String(data: encoded, encoding: .utf8)!
//						print(test)

						let controller = SwiftDocItemController(docs: docs)
						for item in controller.docs {
							print(item)
						}
//
//						for theExt in newDocs.extensions {
//							print(theExt)
//						}
//
//						for theStruct in newDocs.structs {
//							print(theStruct)
//						}
					} catch {
						NSLog("error decoding: \(error)")
					}
				}
			}
		}
	}

	func getSourceDocs() {

	}
}

