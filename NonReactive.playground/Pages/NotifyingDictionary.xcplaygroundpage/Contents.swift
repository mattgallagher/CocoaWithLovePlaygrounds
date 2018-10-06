//: [Previous](@previous)
//:
//: This playground contains the comparison (non-reactive) versions of three scenarios presented in the Cocoa with Love article [What is reactive programming and why should I use it?](http://localhost:1313/blog/reactive-programming-what-and-why.html)

import Foundation

class DocumentValues {
	typealias Dict = Dictionary<AnyHashable, Any>
	typealias Tuple = (AnyHashable, Any?)
	
	static let changed = Notification.Name("com.mycompany.mymodule.documentvalues.changed")
	
	// Underlying storage protected by a `DispatchQueue` mutex
	private var storage = Dict()
	private let mutex = DispatchQueue(label: "")
	
	init() {}
	
	// Access to the storage involves copying out of the mutex
	var values: Dict {
		return mutex.sync {
			return storage
		}
	}
	
	// Remove a value and send a change notification
	func removeValue(forKey key: AnyHashable) {
		let latest = mutex.sync { () -> Dict in
			storage.removeValue(forKey: key)
			return storage
		}
		NotificationCenter.default.post(name: DocumentValues.changed, object: self,
												  userInfo: latest)
	}
	
	// Create/change a value and send a change notification
	func setValue(_ value: Any, forKey key: AnyHashable) {
		let latest = mutex.sync { () -> Dict in
			storage[key] = value
			return storage
		}
		NotificationCenter.default.post(name: DocumentValues.changed, object: self,
												  userInfo: latest)
	}
}

class Observer: NSObject {}

// Create the storage
let dv = DocumentValues()

// Watch the contents
let lifetime = NotificationCenter.default.addObserver(forName: DocumentValues.changed, object: nil, queue: nil) { notification in
	print("Latest: \(notification.userInfo!)")
}
	
// Change the contents
dv.setValue("Hi, there.", forKey: "Oh!")
dv.removeValue(forKey: "Oh!")
dv.setValue("World", forKey: "Hello")

// We normally store outputs in a parent. Without a parent, this `cancel` lets Swift consider the variable "used".
withExtendedLifetime(lifetime) {}

//: [Previous](@previous)
