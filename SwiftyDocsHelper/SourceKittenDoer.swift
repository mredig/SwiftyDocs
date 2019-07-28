//
//  SourceKittenDoer.swift
//  SwiftyDocsHelper
//
//  Created by Michael Redig on 7/27/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation
import SourceKittenFramework

class SourceKittenDoer: SwiftyDocsHelperProtocol {
	func getDocs(from url: URL, completion: @escaping (Data?) -> Void) {
		let module = Module(xcodeBuildArguments: [], inPath: url.path)

		guard let docs = module?.docs else {
			completion(nil)
			return
		}
		let docString = docs.description
		guard let jsonData = docString.data(using: .utf8) else {
			completion(nil)
			return
		}
		completion(jsonData)
	}
}
