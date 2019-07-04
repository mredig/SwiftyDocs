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

	@IBOutlet var outputText: NSTextView!
	var directoryURL: URL?
	let docController = SwiftDocItemController()

	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view.
	}

	@IBAction func openMenuItemPressed(_ sender: NSMenuItem) {
		openProjectDialog()
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
			guard let self = self else { return }
			if result == NSApplication.ModalResponse.OK {
				guard let fileURL = openPanel.url else { fatalError("Open dialog didn't include a file URL") }

				let projectDir = fileURL.deletingLastPathComponent()
				self.directoryURL = projectDir
				self.docController.clear()
				self.docController.getDocs(fromPath: projectDir.path, completion: self.getSourceDocs)
			}
		}
	}

	func getSourceDocs() {
//		var text = "## Classes\n" + docController.classesIndex.reduce("") { $0 + "\($1.title)\n" }//.description//docs.description
//		text += "\n## Structs\n" + docController.structsIndex.reduce("") { $0 + "\($1.title)\n" }
//		text += "\n## Enums\n" + docController.enumsIndex.reduce("") { $0 + "\($1.title)\n" }
//		text += "\n## Protocols\n" + docController.protocolsIndex.reduce("") { $0 + "\($1.title)\n" }
//		text += "\n## Extensions\n" + docController.extensionsIndex.reduce("") { $0 + "\($1.title)\n" }
//		text += "\n## Global Funcs\n" + docController.globalFuncsIndex.reduce("") { $0 + "\($1.title)\n" }
//		text += "\n## Type Aliases\n" + docController.typealiasIndex.reduce("") { $0 + "\($1.title)\n" }
		let index = docController.markdownIndex()
		let text = docController.topLevelIndex.map { docController.markdownPage(for: $0) }.joined(separator: "\n\n\n")
//		let text = markdownGen.generateMarkdownDocumentString(fromRootDocItem: docController.classesIndex[0])
		DispatchQueue.main.async {
			self.outputText.string = index + "\n\n" + text
		}
		print("Finished!")
	}
}

