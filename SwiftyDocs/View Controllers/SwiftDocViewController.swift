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
	private var isLoadingFile = false

	override func viewDidLoad() {
		setupMinAccessLevelPopUp()
		setupSelectedItems()
	}

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
				self.isLoadingFile = true
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
//				self.docController.saveSingleFile(to: saveURL, format: .html)
				self.docController.saveMultifile(to: saveURL, format: .html)
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
		isLoadingFile = false
		DispatchQueue.main.async { [weak self] in
			guard let self = self else { return }
			self.progressIndicator.stopAnimation(nil)
			self.loadProjectButton.isEnabled = true
			self.updateViews()
			self.updateTitleField()
			self.setupSelectedItems()

		}
	}

	func updateTitleField() {
		projectTitleTextField.stringValue = docController.projectTitle
	}
}

extension SwiftDocViewController: NSMenuItemValidation {
	func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
		switch menuItem.title.lowercased() {
		case "open…":
			return !isLoadingFile
		case "save…":
			return docController.projectDirectoryURL != nil
		default:
			// note to self: this also affects the popup menus in the window
			return true
		}
	}
}

// MARK: - IB Stuff
extension SwiftDocViewController {
	@IBAction func projectTitleUpdated(_ sender: NSTextField) {
		docController.projectTitle = sender.stringValue
		sender.stringValue = docController.projectTitle
	}

	func setupMinAccessLevelPopUp() {
		accessLevelPopUp.removeAllItems()
		for level in AccessControl.allCases {
			accessLevelPopUp.addItem(withTitle: level.stringValue)
		}
		accessLevelPopUp.selectItem(withTitle: AccessControl.internal.stringValue)
	}

	func setupSelectedItems() {
		selectedItemsPopUp.removeAllItems()
		if !docController.classesIndex.isEmpty {
			let header = selectedItemsPopUp.menu?.addItem(withTitle: "Exported Items", action: nil, keyEquivalent: "")
			header?.isEnabled = false
		}
		var currentCategory = ""
		for item in docController.topLevelIndex {
			if item.kind.stringValue != currentCategory {
				currentCategory = item.kind.stringValue.capitalized
				let categoryHeader = selectedItemsPopUp.menu?.addItem(withTitle: currentCategory, action: nil, keyEquivalent: "")
				categoryHeader?.isEnabled = false
			}
			let menuItem = NSMenuItem(title: getMenuTitle(for: item), action: nil, keyEquivalent: "")
			menuItem.tag = item.hashValue
			menuItem.state = item.accessControl >= docController.minimumAccessControl ? .on : .off
			selectedItemsPopUp.menu?.addItem(menuItem)

			for property in item.properties ?? [] {
				let propMenuItem = NSMenuItem(title: getMenuTitle(for: property, indendation: 1), action: nil, keyEquivalent: "")
				propMenuItem.tag = property.hashValue
				propMenuItem.state = property.accessControl >= docController.minimumAccessControl ? .on : .off
				selectedItemsPopUp.menu?.addItem(propMenuItem)
			}
		}

		selectedItemsPopUp.selectItem(at: 1)
	}

	private func getMenuTitle(for docItem: SwiftDocItem, indendation: Int = 0) -> String {
		let indentationStr = (0..<indendation).map { _ in "\t" }.joined()
		return "\(indentationStr)\(docItem.title) (\(docItem.kind.stringValue))"
	}

	@IBAction func minimumAccessLevelPopUpChanged(_ sender: NSPopUpButton) {
		guard let str = sender.selectedItem?.title else { return }
		let accessLevel = AccessControl.createFrom(string: str)
		docController.minimumAccessControl = accessLevel
		setupSelectedItems()
		print(accessLevel)
	}
}
