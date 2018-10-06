//: [Previous](@previous) – [Next](@next)
//:
//: This playground contains the comparison (non-reactive) versions of three scenarios presented in the Cocoa with Love article [What is reactive programming and why should I use it?](http://localhost:1313/blog/reactive-programming-what-and-why.html)

import Cocoa
import PlaygroundSupport

class Server: NSObject {
	@objc dynamic let name: String
	init(name: String) {
		self.name = name
		super.init()
	}
}

class CurrentServer: NSObject {
	@objc dynamic var currentServer: Server? = Server(name: "Pear")
	var v = 0
	var timer: Timer!
	
	override init() {
		super.init()
		timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
			guard let self = self else { return }
			self.currentServer = self.v % 3 == 0 ? nil : Server(name: self.v % 3 == 1 ? "Peach" : "Pear")
			self.v += 1
		}
	}
}

let sharedServer = CurrentServer()

class FileSelection: NSObject {
	@objc dynamic var selection: [Int] = []
	var t: Timer!
	var iteration = 0
	
	override init() {
		super.init()
		t = Timer.scheduledTimer(withTimeInterval: 0.65, repeats: true, block: { [weak self] _ in
			guard let self = self else { return }
			self.selection = Array<Int>(repeating: 0, count: self.iteration % 3)
			self.iteration += 1
		})
	}
}

class CurrentFileSelection: NSObject {
	@objc dynamic var currentSelection: FileSelection? = FileSelection()
	var v = 0
	var timer: Timer!
	
	override init() {
		super.init()
		timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
			guard let self = self else { return }
			self.currentSelection = self.v % 2 == 0 ? FileSelection() : nil
			self.v += 1
		}
	}
}

let sharedSelection = CurrentFileSelection()

class ViewController : NSViewController {
	// Child controls
	let uploadButton = NSButton(title: "Upload selection", target: nil, action: nil)
	let serverStatusButton = NSButton(checkboxWithTitle: "", target: nil, action: nil)
	let filesSelectedLabel = NSTextField(labelWithString: "")
	
	// Lifetimes of observations
	var serverObs: NSKeyValueObservation?
	var selectionObs: NSKeyValueObservation?
	var selectionNameObs: NSKeyValueObservation?
	
	override func loadView() {
		// The view is an NSStackView (for layout convenience)
		let view = NSStackView(frame: NSRect(x: 0, y: 0, width: 150, height: 100))
		
		// Set static properties
		view.orientation = .vertical
		view.setHuggingPriority(.required, for: .horizontal)
		
		// Construct the view tree
		view.addView(uploadButton, in: .center)
		view.addView(serverStatusButton, in: .center)
		view.addView(filesSelectedLabel, in: .center)
		view.layoutSubtreeIfNeeded()

		// Set the view
		self.view = view
	}
	
	override func viewDidLoad() {
		serverObs = sharedServer.observe(\.currentServer, options: .initial) { [uploadButton, serverStatusButton] object, change in
			serverStatusButton.state = object.currentServer == nil ? .off : .on
			serverStatusButton.title = object.currentServer.map { s in "Server name: \(s.name)" } ?? "None"
			uploadButton.isEnabled = object.currentServer != nil && sharedSelection.currentSelection?.selection.isEmpty == false
		}
		
		selectionObs = sharedSelection.observe(\.currentSelection, options: .initial) { [filesSelectedLabel, uploadButton, weak self] object, change in
			if let s = object.currentSelection {
				self?.selectionNameObs = s.observe(\.selection, options: .initial) { [filesSelectedLabel, uploadButton] object, change in
					filesSelectedLabel.stringValue = "Selected file count: \(object.selection.count)"
					uploadButton.isEnabled = sharedServer.currentServer != nil && object.selection.isEmpty == false
				}
			} else {
				filesSelectedLabel.stringValue = "No selection"
				uploadButton.isEnabled = false
			}
		}
	}
}
// Present the view controller in the Live View window
PlaygroundPage.current.liveView = ViewController()

//: [Previous](@previous) – [Next](@next)
