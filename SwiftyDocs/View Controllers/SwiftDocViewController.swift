//
//  SwiftDocViewController.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/2/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Cocoa
import SourceKittenFramework

class SwiftDocViewController: NSViewController {

	@IBOutlet var loadProjectButton: NSButton!
	@IBOutlet var progressIndicator: NSProgressIndicator!

	var directoryURL: URL?
	let docController = SwiftDocItemController()

	@IBAction func openMenuItemPressed(_ sender: NSMenuItem) {
		openProjectDialog()
	}

	@IBAction func buttonPressed(_ sender: NSButton) {
		openProjectDialog()
	}

	@IBAction func saveDocument(_ sender: NSMenuItem) {
		saveProjectDialog()
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
				self.progressIndicator.startAnimation(nil)
				self.loadProjectButton.isEnabled = false
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
			self.progressIndicator.stopAnimation(nil)
			self.loadProjectButton.isEnabled = true
		}
		print("Finished!")
	}
}

