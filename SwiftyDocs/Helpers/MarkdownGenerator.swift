//
//  MarkdownGenerator.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/3/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation

class MarkdownGenerator {

	func generateMarkdownDocumentString(fromRootDocItem swiftDocItem: SwiftDocItem) -> String {
		let docHeader = "# \(swiftDocItem.title)"
		let type = "*\(swiftDocItem.kind.stringValue)*"
		let declaration = """
						```swift
						\(swiftDocItem.declaration)
						```
						"""
		let discussion = swiftDocItem.comment ?? "No documentation"

		var children = [String]()
		if let properties = swiftDocItem.properties {
			for property in properties {
				let propTitle = "* **\(property.title)**"
				let propType = "*\(property.kind.stringValue)*"
				let propInfo = (property.comment ?? "No documentation")
				let propDeclaration =  """
							```swift
							\(property.declaration)
							```
							"""

				let outDown = "\(propTitle)\n\(propType)\n\n\(propDeclaration)\n\n\(propInfo)"

				children.append(outDown)
			}
		}

		var markdownOut = "\(docHeader)\n\(type)\n\(declaration)\n\n\(discussion)\n\n\((children.isEmpty ? "" : "___\n### Members\n\n"))"

		for child in children {
			markdownOut += "\(child.replacingOccurrences(of: "\n", with: "\n\t"))\n\n"
		}

		return markdownOut
	}
}
