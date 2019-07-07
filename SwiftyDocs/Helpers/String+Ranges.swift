//
//  String+Ranges.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/6/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation

extension String {
	func ranges<T: StringProtocol>(of value: T, options: String.CompareOptions, range: Range<String.Index>?, locale: Locale?) -> [Range<String.Index>]{
		guard let endRange = range?.upperBound ?? self.indices.last else { return [] }
		guard var lowRange = range?.lowerBound ?? self.indices.first else { return [] }
		var ranges = [Range<String.Index>]()

		while lowRange < endRange {
			if let newRange = self.range(of: value, options: options, range: lowRange..<endRange, locale: locale) {
				ranges.append(newRange)
				lowRange = newRange.upperBound
			} else {
				break
			}
		}
		return ranges
	}

	func repeated(count: Int) -> String {
		let count = max(0, count)
		return (0..<count).reduce("") { previousValue, _ in previousValue + self }
	}
}
