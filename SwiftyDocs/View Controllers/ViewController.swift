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

	@IBAction func saveDocument(_ sender: NSMenuItem) {
		saveProjectDialog()
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

	func saveProjectDialog() {
		let savePanel = NSSavePanel()
		savePanel.canCreateDirectories = true
		savePanel.title = "Save your project"
		savePanel.message = "SwiftyDocs will create a folder inside of whatever folder you choose."

		savePanel.begin { [weak self] (result) in
			guard let self = self else { return }
			if result == NSApplication.ModalResponse.OK {
				guard let saveURL = savePanel.url else { return }
//				self.docController.saveSingleFile(to: saveURL, format: .html)
				self.docController.saveMultifile(to: saveURL, format: .html)
			}
		}
	}

	func getSourceDocs() {
		let index = docController.markdownIndex(with: .singlePage)
		var text = docController.topLevelIndex.map { docController.markdownPage(for: $0) }.joined(separator: "\n\n\n")
		text = index + "\n\n" + text
		DispatchQueue.main.async {
			self.outputText.string = text
		}
		print("Finished!")
	}
}

