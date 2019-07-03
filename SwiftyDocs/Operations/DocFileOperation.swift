//
//
//  Created by Michael Redig on 6/6/19.
//

import Foundation
import SourceKittenFramework

class DocFileOperation: ConcurrentOperation {
	let data: Data?
	var docFiles: [DocFile]?

	init(data: Data) {
		self.data = data
	}

	override func start() {
		state = .isExecuting



		state = .isFinished
	}
}
