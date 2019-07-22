//
//  String+Ranges.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/6/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation

extension String {
	/// Builds on `range(of value:...)` to match more than just the first match and return all matching ranges.
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

	/// appends `self` to `self` `count` times and returns the result. Useful for repeating tabs or newlines.
	func repeated(count: Int) -> String {
		let count = max(0, count)
		return (0..<count).reduce("") { previousValue, _ in previousValue + self }
	}

	/// Replaces all non word characters (using regex rules) with "-". This is for making both anchor links and file names usable.
	func replacingNonWordCharacters(lowercased: Bool = true) -> String {
		var rVal = self
		if lowercased {
			rVal = rVal.lowercased()
		}
		return rVal.replacingOccurrences(of: ##"\W+"##, with: "-", options: .regularExpression, range: nil)
	}

	///	Percent escapes all non url host allowed characters in a string and returns the result.
	var percentEscaped: String {
		return self.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
	}
}
