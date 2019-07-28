//
//  OMGAlrt.swift
//  eggBW
//
//  Created by Michael Redig on 12/9/18.
//  Copyright © 2018 Michael Redig. All rights reserved.
//

import Cocoa


enum OMGSimpleAlrt {
	static func showAlert(withTitle title: String, andMessage message: String, andConfirmButtonText confirmText: String = "Okay") {
		let alertVC = NSAlert()
		alertVC.messageText = title
		alertVC.informativeText = message
		alertVC.addButton(withTitle: confirmText)
		alertVC.runModal()
	}
}
