//
//
//  Created by Michael Redig on 6/6/19.
//

import Foundation

/// Technically this isn't necessary in this case. I'm just testing alternatives to what I'm used to for concurrency
class DocScrapeOperation: ConcurrentOperation {
	let path: URL
	var jsonData: Data?

	let remoteXPCConnection: NSXPCConnection = {
		let connection = NSXPCConnection(serviceName: "com.redeggproductions.SwiftyDocsHelper")
		connection.remoteObjectInterface = NSXPCInterface(with: SwiftyDocsHelperProtocol.self)
		connection.resume()
		return connection
	}()

	init(path: URL) {
		self.path = path
	}

	override func start() {
		state = .isExecuting

		guard let docGetter = remoteXPCConnection.remoteObjectProxyWithErrorHandler({ error in
			NSLog("remote proxy error: \(error)")
		}) as? SwiftyDocsHelperProtocol else { return }

		let semaphore = DispatchSemaphore(value: 0)
		docGetter.getDocs(from: path) { data in
			self.jsonData = data
			semaphore.signal()
		}
		semaphore.wait()

		state = .isFinished
	}
}
