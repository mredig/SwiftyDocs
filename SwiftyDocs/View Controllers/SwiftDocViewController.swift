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

	@IBOutlet var formatPopUp: NSPopUpButton!
	@IBOutlet var fileCountPopUp: NSPopUpButton!
	@IBOutlet var selectedItemsPopUp: NSPopUpButton!
	@IBOutlet var accessLevelPopUp: NSPopUpButton!
	@IBOutlet var projectTitleTextField: NSTextField!
	@IBOutlet var loadProjectButton: NSButton!
	@IBOutlet var progressIndicator: NSProgressIndicator!

	let docController = SwiftDocItemController()

	override func viewWillAppear() {
		updateViews()
	}

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
				self.docController.projectURL = fileURL
				self.docController.clear()
				self.docController.getDocs(fromPath: projectDir.path, completion: self.openProjectFinished)
				self.progressIndicator.startAnimation(nil)
				self.loadProjectButton.isEnabled = false
			}
		}
	}

	func saveProjectDialog() {
		let savePanel = NSSavePanel()
		savePanel.canCreateDirectories = true
		savePanel.title = "Save your project"
		savePanel.message = "SwiftyDocs will create a folder in your destination containing all documentation files."
		savePanel.nameFieldStringValue = docController.projectTitle + "-Documentation"

		savePanel.begin { [weak self] (result) in
			guard let self = self else { return }
			if result == NSApplication.ModalResponse.OK {
				guard let saveURL = savePanel.url else { return }
				self.docController.saveSingleFile(to: saveURL, format: .html)
//				self.docController.saveMultifile(to: saveURL, format: .html)
			}
		}
	}

	func updateViews() {
		setItemsEnabled(to: !docController.docs.isEmpty)
	}

	func setItemsEnabled(to enabled: Bool) {
		formatPopUp.isEnabled = enabled
		fileCountPopUp.isEnabled = enabled
		selectedItemsPopUp.isEnabled = enabled
		accessLevelPopUp.isEnabled = enabled
		projectTitleTextField.isEnabled = enabled
	}

	func openProjectFinished() {
		DispatchQueue.main.async { [weak self] in
			guard let self = self else { return }
			self.progressIndicator.stopAnimation(nil)
			self.loadProjectButton.isEnabled = true
			self.updateViews()
			self.updateTitleField()
		}
	}

	func updateTitleField() {
		guard let title = docController.projectTitle else { return }
		projectTitleTextField.stringValue = title
	}
}

