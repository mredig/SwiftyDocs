//
//  MenuManager.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/3/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Cocoa

class MenuManager: NSObject {

	static let shared = MenuManager()

	private override init() {}
	
	@IBAction func openMenuItemPressed(_ sender: NSMenuItem) {
		NotificationCenter.default.post(name: .openMenuItemSelected, object: nil, userInfo: nil)
	}
}

extension NSNotification.Name {
	static let openMenuItemSelected = NSNotification.Name("com.redeggproductions.swiftydocs.openMenuItemPressed")
}
