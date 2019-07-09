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

	@IBOutlet var masterStackView: NSStackView!
	@IBOutlet var formatPopUp: NSPopUpButton!
	@IBOutlet var selectedItemsPopUp: NSPopUpButton!
	@IBOutlet var accessLevelPopUp: NSPopUpButton!
	@IBOutlet var projectTitleLabel: NSTextField!
	@IBOutlet var projectTitleTextField: NSTextField!
	@IBOutlet var loadProjectButton: NSButton!
	@IBOutlet var exportButton: NSButton!
	@IBOutlet var progressIndicator: NSProgressIndicator!

	@IBOutlet var fileCountPopUp: NSPopUpButton!
	@IBOutlet var outputIWantLabel: NSTextField!
	@IBOutlet var outputFileLabel: NSTextField!

	let docController = SwiftDocItemController()
	private var isLoadingFile = false

	// MARK: - initing
	override func viewDidLoad() {
		setupMinAccessLevelPopUp()
		setupOutputOptionsMenus()
	}

	override func viewWillAppear() {
		updateViews()
		projectTitleTextField.isHidden = true
	}

	// MARK: - menu items
	@IBAction func openMenuItemPressed(_ sender: NSMenuItem) {
		openProjectDialog()
	}

	@IBAction func loadButtonPressed(_ sender: NSButton) {
		openProjectDialog()
	}

	@IBAction func exportButtonPressed(_ sender: NSButton) {
		saveProjectDialog()
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
				self.docController.getDocs(from: projectDir, completion: self.openProjectFinished)
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

				guard let format = self.getSaveFormat(),
					let style = self.getOutputStyle()
					else { return }

				self.docController.save(with: style, to: saveURL, in: format)
			}
		}
	}

	// MARK: - update views etc
	func updateViews() {
		setItemsEnabled(to: !docController.docs.isEmpty)
		updateWindowTitle()
		updateTitleField()
		setupSelectedItems()
		view.window?.setContentSize(NSSize(width: 480, height: 1))
	}

	func setItemsEnabled(to enabled: Bool) {
		formatPopUp.isEnabled = enabled
		fileCountPopUp.isEnabled = enabled
		selectedItemsPopUp.isEnabled = enabled
		accessLevelPopUp.isEnabled = enabled
		projectTitleTextField.isEnabled = enabled
		exportButton.isEnabled = enabled
	}

	func openProjectFinished() {
		isLoadingFile = false
		DispatchQueue.main.async { [weak self] in
			guard let self = self else { return }
			self.progressIndicator.stopAnimation(nil)
			self.loadProjectButton.isEnabled = true
			self.updateViews()
		}
	}

	private func updateTitleField() {
		projectTitleTextField.stringValue = docController.projectTitle
		projectTitleLabel.stringValue = docController.projectTitle
	}

	private func updateWindowTitle() {
		view.window?.title = "\(docController.projectTitle)-SwiftyDocs"
	}
}

extension SwiftDocViewController: NSMenuItemValidation {
	func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
		// note to self: this also affects the popup menus in the window
		guard let action = menuItem.action else { return true }
		switch action {
		case #selector(openMenuItemPressed):
			return !isLoadingFile
		case #selector(saveDocument):
			return docController.projectDirectoryURL != nil && !isLoadingFile
		default:
			return true
		}
	}
}

// MARK: - IB customization Stuff
extension SwiftDocViewController {
	@IBAction func renameDocsPressed(_ sender: NSButton) {
		projectTitleTextField.isHidden.toggle()
	}

	@IBAction func projectTitleUpdated(_ sender: NSTextField) {
		docController.projectTitle = sender.stringValue
		sender.stringValue = docController.projectTitle
		updateViews()
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
		updateViews()
		print(accessLevel)
	}

	// only needs to occurr once
	private func setupOutputOptionsMenus() {
		fileCountPopUp.removeAllItems()
		formatPopUp.removeAllItems()

		for format in SaveFormat.allCases {
			formatPopUp.addItem(withTitle: format.rawValue)
		}

		for style in OutputStyle.allCases {
			fileCountPopUp.addItem(withTitle: style.rawValue)
		}
		fileCountSelectorChanged(fileCountPopUp)
	}

	@IBAction func fileCountSelectorChanged(_ sender: NSPopUpButton) {
		guard let selectedText = sender.selectedItem?.title else { return }
		guard let output = OutputStyle(rawValue: selectedText) else { return }

		updateOutputLabels(context: output)
	}

	private func updateOutputLabels(context: OutputStyle) {
		switch context {
		case .multiPage:
			outputIWantLabel.stringValue = "I want"
			outputFileLabel.stringValue = "files"
		case .singlePage:
			outputIWantLabel.stringValue = "I want a"
			outputFileLabel.stringValue = "file"
		}
	}

	private func getOutputStyle() -> OutputStyle? {
		guard let selectedText = fileCountPopUp.selectedItem?.title else { return nil }
		guard let output = OutputStyle(rawValue: selectedText) else { return nil }
		return output
	}

	private func getSaveFormat() -> SaveFormat? {
		guard let selectedText = formatPopUp.selectedItem?.title else { return nil }
		guard let saveStyle = SaveFormat(rawValue: selectedText) else { return nil }
		return saveStyle
	}
}
