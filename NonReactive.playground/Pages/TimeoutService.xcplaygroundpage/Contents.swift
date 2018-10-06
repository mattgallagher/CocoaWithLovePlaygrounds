//: [Next](@next)
//:
//: This playground contains the comparison (non-reactive) versions of three scenarios presented in the Cocoa with Love article [What is reactive programming and why should I use it?](http://localhost:1313/blog/reactive-programming-what-and-why.html)

import Foundation

class TimeoutService {
	struct Timeout: Error {}
	
	var currentAction: Lifetime? = nil
	
	// Define the interface for the underlying connection
	typealias ResultHandler = (Result<String>) -> Void
	typealias WorkFunction = (DispatchQueue, @escaping ResultHandler) -> Lifetime
	
	// This is the configurable connection to the underlying service
	let work: WorkFunction
	
	// Every action for this service should occur in in this queue
	let queue = DispatchQueue(label: "\(TimeoutService.self)")
	
	// Construction of the Service lets us specify the underlying service
	init(work: @escaping WorkFunction) {
		self.work = work
	}
	
	// This `TimeoutService` invokes the `underlyingConnect` and starts a timer
	func start(timeout seconds: Double, handler: @escaping ResultHandler) {
		var previousAction: Lifetime? = nil
		queue.sync {
			previousAction = self.currentAction
			
			let current = AggregateLifetime()
			
			// Run the underlying connection
			let underlyingAction = self.work(self.queue) { [weak current] result in
				// Cancel the timer if the success occurs first
				current?.cancel()
				handler(result)
			}
			
			// Run the timeout timer
			let timer = DispatchSource.singleTimer(interval: .interval(seconds), queue: self.queue) { [weak current] in
				// Cancel the connection if the timer fires first
				current?.cancel()
				handler(.failure(Timeout()))
			} as! DispatchSource
			
			current += timer
			current += underlyingAction
			self.currentAction = current
		}
		
		// Good rule of thumb: never release lifetime objects inside a mutex
		withExtendedLifetime(previousAction) {}
	}
}

// Our fake connection just waits 2 seconds and sends "Hello, world!"
func dummyAsyncWork(dispatchQueue: DispatchQueue, handler: @escaping TimeoutService.ResultHandler) -> Lifetime {
	return DispatchSource.singleTimer(interval: .interval(2), queue: dispatchQueue) {
		handler(.success("Hello, world!"))
	} as! DispatchSource
}

// Our use of the service connects, and prints the results
let service = TimeoutService(work: dummyAsyncWork)

// Start the connection
service.start(timeout: 3.0) { result in
	switch result {
	case .success(let message): print("Connected with message: \(message)")
	case .failure(let error): print("Connection failed: \(error)")
	}
}

// Let everything run for 10 seconds.
RunLoop.current.run(until: Date(timeIntervalSinceNow: 10.0))

//: [Next](@next)
