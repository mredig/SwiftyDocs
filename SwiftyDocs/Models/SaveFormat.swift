//
//  SaveFormat.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/4/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation

/**
Used to determine the output format that's exported.
*/
enum SaveFormat: String, CaseIterable {
	case html
	case markdown
	case docset
}
