//
//  DefaultsManager.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/23/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation

/**
Easy interface to access `UserDefaults`
*/
class DefaultsManager {
	/// Singleton instance of Defaults manager.
	static let `default` = DefaultsManager()
	private init() {}

	private let defaults = UserDefaults()

	/// Stores the last used directory when opening a file
	var defaultOpenDir: URL? {
		get {
			return defaults.url(forKey: .defaultOpenDirKey)
		}
		set {
			defaults.set(newValue, forKey: .defaultOpenDirKey)
		}
	}

	/// Stores the last used directory when saving an export
	var defaultSaveDir: URL? {
		get {
			return defaults.url(forKey: .defaultSaveDirKey)
		}
		set {
			defaults.set(newValue, forKey: .defaultSaveDirKey)
		}
	}
}

fileprivate extension String {
	static let defaultOpenDirKey = "defaultOpenDir"
	static let defaultSaveDirKey = "defaultSaveDir"
}
