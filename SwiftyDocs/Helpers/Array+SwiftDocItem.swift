//
//  Array+SwiftDocItem.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/3/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation

extension Array where Element == SwiftDocItem {
	func enumeratedChildren() -> [SwiftDocItem] {
		var enumerated = [SwiftDocItem]()
		for item in self {
			enumerated.append(item)
			guard let itemChildren = getChildren(from: item) else { continue }
			enumerated.append(contentsOf: itemChildren)
		}

		return enumerated
	}

	private func getChildren(from item: SwiftDocItem) -> [SwiftDocItem]? {
		guard let children = item.properties else {
			return nil
		}
		var newChilds = [SwiftDocItem]()
		for child in children {
			newChilds.append(child)
			guard let unwrappedNewChildren = getChildren(from: child) else {
				continue
			}
			newChilds += unwrappedNewChildren
		}
		return newChilds
	}
}
