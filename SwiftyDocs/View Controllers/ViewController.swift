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
				self.docController.getDocs(fromPath: projectDir.path, completion: self.getSourceDocs)
			}
		}
	}

	func getSourceDocs() {
		let text = docController.docs.description
		DispatchQueue.main.async {
			self.outputText.string = text
		}
		print("Finished!")
	}
}

