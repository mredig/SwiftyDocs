//
//  SQLController.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/18/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import SQLite

class SQLController {

	let dbConnection: Connection
	var searchIndex: Table?

	init(at path: URL) throws {
		dbConnection = try Connection(path.path)
		initialzeTable()
	}

	func initialzeTable() {
		searchIndex = Table("searchIndex")
		guard let searchIndex = searchIndex else { return }
		let idExpression = Expression<Int64>("id")
		let nameExpression = Expression<String>("name")
		let typeExpression = Expression<String>("type")
		let pathExpression = Expression<String>("path")

		do {
			try dbConnection.run(searchIndex.create { table in
				table.column(idExpression, primaryKey: true)
				table.column(nameExpression)
				table.column(typeExpression)
				table.column(pathExpression)
			})

			let dupPrevention = try dbConnection.prepare("CREATE UNIQUE INDEX anchor ON searchIndex (name, type, path);")
			try dupPrevention.run()
		} catch {
			NSLog("Error creating SQLite table: \(error)")
		}
	}

	func addRow(with name: String, type: String, path: String) {
//		guard let searchIndex = searchIndex else { return }
		do {
			let addRowStatement = try dbConnection.prepare("INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES (?, ?, ?);")
			try addRowStatement.run(name, type, path)
		} catch {
			NSLog("Error adding SQLite row: \(error)")
		}
	}
}
