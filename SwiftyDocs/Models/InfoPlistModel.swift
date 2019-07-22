//
//  InfoPlistModel.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/18/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation

/**
InfoPlistModel is a `Codable` struct to simplify generating the Info.plist for docset generation.
*/
struct InfoPlistModel: Codable {
	let bundleID: String
	let bundleName: String
	let platformFamily: String
	let isDashDocset = true
	let isJavaScriptEnabled = true
	let dashIndexFilePath: String
	let dashDocSetFamily: String

	enum CodingKeys: String, CodingKey {
		case bundleID = "CFBundleIdentifier"
		case bundleName = "CFBundleName"
		case platformFamily = "DocSetPlatformFamily"
		case isDashDocset
		case isJavaScriptEnabled
		case dashIndexFilePath
		case dashDocSetFamily = "DashDocSetFamily"
	}
}
