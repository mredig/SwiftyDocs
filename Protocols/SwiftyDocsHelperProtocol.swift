//
//  SourceKittenDocs.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/27/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation
import SourceKittenFramework

@objc protocol SwiftyDocsHelperProtocol {
	func getDocs(from url: URL, completion: @escaping (Data?) -> Void)
}
