//
//  SwiftDocViewController.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/2/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Cocoa
import SourceKittenFramework

/**
The view controller for the primary GUI window.
*/
class SwiftDocViewController: NSViewController {

	@IBOutlet var masterStackView: NSStackView!
	/// The popup button where you can select the destination format.
	@IBOutlet var saveFormatPopUp: NSPopUpButton!
	/// The popup button that shows the result of the selected access control level.
	@IBOutlet var selectedItemsPopUp: NSPopUpButton!
	/// Popup that allows selecting the access control level.
	@IBOutlet var accessLevelPopUp: NSPopUpButton!
	/// Read only label that displays the project title.
	@IBOutlet var projectTitleLabel: NSTextField!
	/// Editable text field that allows changing the project title.
	@IBOutlet var projectTitleTextField: NSTextField!
	/// Button that loads a project for exporting. Equivalent to File->Open
	@IBOutlet var loadProjectButton: NSButton!
	/// Button that initiates the export. Equivalent to File->Save
	@IBOutlet var exportButton: NSButton!
	/// Indicator showing that work is in progress.
	@IBOutlet var progressIndicator: NSProgressIndicator!
	/// Button that toggles showing the field that allows renaming the project.
	@IBOutlet var renameButton: NSButton!
	/// Popup that allows you to choose if you multiple files or a single file for output.
	@IBOutlet var pageCountPopUp: NSPopUpButton!
	/// Label that changes contextually.
	@IBOutlet var outputIWantLabel: NSTextField!
	/// Label that changes contextually.
	@IBOutlet var outputFileLabel: NSTextField!

	/// and instance of SwiftDocItemController
	let docController = SwiftDocItemController()
	/// Tracks the state of whether a file is loading or not to determine the enabling of UI widgets.
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
		openPanel.directoryURL = DefaultsManager.default.defaultOpenDir

		openPanel.begin { [weak self] (result) in
			guard let self = self else { return }
			if result == NSApplication.ModalResponse.OK {
				guard let fileURL = openPanel.url else { fatalError("Open dialog didn't include a file URL") }

				let projectDir = fileURL.deletingLastPathComponent()
				DefaultsManager.default.defaultOpenDir = projectDir
				self.docController.projectURL = fileURL
				self.docController.clear()
				self.updateViews()
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
		savePanel.message = "SwiftyDocs will create a folder in your destination containing all generated documentation files."
		savePanel.nameFieldStringValue = docController.projectTitle + "-Documentation"
		savePanel.directoryURL = DefaultsManager.default.defaultSaveDir

		if saveFormatPopUp.selectedItem?.title == SaveFormat.docset.rawValue {
			savePanel.isExtensionHidden = false
			savePanel.allowedFileTypes = ["docset"]
			savePanel.nameFieldStringValue = docController.projectTitle
			savePanel.message = "SwiftyDocs will create a docset in your destination containing all generated documentation."
		} else {
			savePanel.isExtensionHidden = true
			savePanel.message = "SwiftyDocs will create a folder in your destination containing all generated documentation files."
			savePanel.nameFieldStringValue = docController.projectTitle + "-Documentation"
		}

		savePanel.begin { [weak self] (result) in
			guard let self = self else { return }
			if result == NSApplication.ModalResponse.OK {
				guard let saveURL = savePanel.url else { return }
				DefaultsManager.default.defaultSaveDir = saveURL.deletingLastPathComponent()

				guard let format = self.getSaveFormat(),
					let style = self.getOutputStyle()
					else { return }

				self.docController.save(with: style, to: saveURL, in: format)
			}
		}
	}

	// MARK: - update views etc
	/// simple function to update UI state based on current state.
	func updateViews() {
		setItemsEnabled(to: !docController.docs.isEmpty)
		updateWindowTitle()
		updateTitleField()
		setupSelectedItems()
	}

	/// toggles ui elements' enabled state
	private func setItemsEnabled(to enabled: Bool) {
		renameButton.isEnabled = enabled
		saveFormatPopUp.isEnabled = enabled
		pageCountPopUp.isEnabled = enabled
		selectedItemsPopUp.isEnabled = enabled
		accessLevelPopUp.isEnabled = enabled
		projectTitleTextField.isEnabled = enabled
		exportButton.isEnabled = enabled
	}

	/// What runs upon completion of opening the selected project.
	private func openProjectFinished() {
		isLoadingFile = false
		DispatchQueue.main.async { [weak self] in
			guard let self = self else { return }
			self.progressIndicator.stopAnimation(nil)
			self.loadProjectButton.isEnabled = true
			self.updateViews()
		}
	}

	/// updates the title field from the current project title
	private func updateTitleField() {
		projectTitleTextField.stringValue = docController.projectTitle
		projectTitleLabel.stringValue = docController.projectTitle
	}

	/// updates the window title
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
	/// toggles the hidden state of the renaming text field
	@IBAction func renameDocsPressed(_ sender: NSButton) {
		NSAnimationContext.runAnimationGroup { (context) in
			context.duration = 1
			context.allowsImplicitAnimation = true

			projectTitleTextField.isHidden.toggle()
			view.layoutSubtreeIfNeeded()
		}
	}

	/// runs when the project title changes
	@IBAction func projectTitleUpdated(_ sender: NSTextField) {
		docController.projectTitle = sender.stringValue
		sender.stringValue = docController.projectTitle
		updateViews()
	}

	/// populates and selects the minimum access level popup
	private func setupMinAccessLevelPopUp() {
		accessLevelPopUp.removeAllItems()
		for level in AccessControl.allCases {
			accessLevelPopUp.addItem(withTitle: level.stringValue)
		}
		accessLevelPopUp.selectItem(withTitle: AccessControl.internal.stringValue)
	}

	/// populates and checks the items that are selected for export as a result of the chosen minimum access level
	private func setupSelectedItems() {
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

	/// when setting up the selected items popup, this assists in generating a string for each entry
	private func getMenuTitle(for docItem: SwiftDocItem, indendation: Int = 0) -> String {
		let indentationStr = (0..<indendation).map { _ in "\t" }.joined()
		return "\(indentationStr)\(docItem.title) (\(docItem.kind.stringValue))"
	}

	/// updates the selected items popup based on the minimum access level when the minimum access level pop changes (also saves that value to the `docController`)
	@IBAction func minimumAccessLevelPopUpChanged(_ sender: NSPopUpButton) {
		guard let str = sender.selectedItem?.title else { return }
		let accessLevel = AccessControl.createFrom(string: str)
		docController.minimumAccessControl = accessLevel
		updateViews()
		print(accessLevel)
	}

	// only needs to occurr once
	/// populates and selects the default output options popups
	private func setupOutputOptionsMenus() {
		pageCountPopUp.removeAllItems()
		saveFormatPopUp.removeAllItems()

		for format in SaveFormat.allCases {
			saveFormatPopUp.addItem(withTitle: format.rawValue)
		}

		for style in PageCount.allCases {
			pageCountPopUp.addItem(withTitle: style.rawValue)
		}
		pageCountSelectorChanged(pageCountPopUp)
	}

	/// runs when the popup is toggled between multiple or single file output
	@IBAction func pageCountSelectorChanged(_ sender: NSPopUpButton) {
		guard let selectedText = sender.selectedItem?.title else { return }
		guard let output = PageCount(rawValue: selectedText) else { return }

		updateOutputLabels(context: output)
	}

	/// runs when the pop is toggled between markdown, html, or docset outputs
	@IBAction func saveFormatPopupChanged(_ sender: NSPopUpButton) {
		guard let selectedItem = sender.selectedItem else { return }
		switch selectedItem.title {
		case SaveFormat.docset.rawValue:
			pageCountPopUp.selectItem(withTitle: PageCount.singlePage.rawValue)
			pageCountPopUp.item(withTitle: PageCount.multiPage.rawValue)?.isHidden = true
		default:
			pageCountPopUp.item(withTitle: PageCount.multiPage.rawValue)?.isHidden = false
		}
		pageCountSelectorChanged(pageCountPopUp)
	}

	/// updates the output labels next to the popups to read more like correct english, depending on whether the output is plural or not.
	private func updateOutputLabels(context: PageCount) {
		switch context {
		case .multiPage:
			outputIWantLabel.stringValue = "I want"
			outputFileLabel.stringValue = "files"
		case .singlePage:
			outputIWantLabel.stringValue = "I want a"
			outputFileLabel.stringValue = "file"
		}
	}

	/// getter for getting the PageCount from the page count popup
	private func getOutputStyle() -> PageCount? {
		guard let selectedText = pageCountPopUp.selectedItem?.title else { return nil }
		guard let output = PageCount(rawValue: selectedText) else { return nil }
		return output
	}

	/// getter for getting the SaveFormat from the save format count popup
	private func getSaveFormat() -> SaveFormat? {
		guard let selectedText = saveFormatPopUp.selectedItem?.title else { return nil }
		guard let saveStyle = SaveFormat(rawValue: selectedText) else { return nil }
		return saveStyle
	}
}

extension SwiftDocViewController: NSControlTextEditingDelegate {
	/// fires when the text field changes any characters
	func controlTextDidChange(_ obj: Notification) {
		if let textField = obj.object as? NSTextField {
			if textField == projectTitleTextField {
				projectTitleUpdated(textField)
			}
		}
	}
}
