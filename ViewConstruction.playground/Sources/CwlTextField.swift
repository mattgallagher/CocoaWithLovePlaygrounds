//
//  CwlTextField.swift
//  CwlViews
//
//  Created by Matt Gallagher on 2017/04/18.
//  Copyright © 2017 Matt Gallagher ( http://cocoawithlove.com ). All rights reserved.
//
//  Permission to use, copy, modify, and/or distribute this software for any purpose with or without
//  fee is hereby granted, provided that the above copyright notice and this permission notice
//  appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS
//  SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
//  AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
//  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
//  NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
//  OF THIS SOFTWARE.
//

import UIKit

extension UITextField {
	public convenience init(_ bindings: TextField.Binding...) {
		self.init()
		TextField(bindings: bindings).applyBindings(to: self)
	}
}

public struct TextField: DerivedBinder, TextFieldConstructor {
	public typealias Instance = UITextField
	public typealias inheritedBinding = Control
	
	public let subclass: Instance.Type
	public let bindings: [Binding]
	
	public init(subclass: Instance.Type = Instance.self, bindings: [Binding]) {
		self.subclass = subclass
		self.bindings = bindings
	}
	public init(subclass: Instance.Type = Instance.self, _ bindings: Binding...) {
		self.init(subclass: subclass, bindings: bindings)
	}
	public func applyBindings(to instance: Instance) {
		var preparer = Preparer()
		preparer.prepareBindings(bindings)
		preparer.applyBindings(bindings, instance: instance, storage: Storage(), combine: embedStorageIfInUse)
	}
	public static func bindingToinheritedBinding(_ binding: Binding) -> inheritedBinding.Binding? {
		if case .inheritedBinding(let s) = binding { return s } else { return nil }
	}
	public func constructTextField() -> UITextField {
		let x = subclass.init()
		applyBindings(to: x)
		return x
	}
	
	public enum Binding: TextFieldBinding {
		public typealias Binder = TextField
		public static func textFieldBinding(_ binding: Binding) -> Binding { return binding }
		case inheritedBinding(inheritedBinding.Binding)
		
		case text(DynamicValue<String>)
		case borderStyle(DynamicValue<UITextBorderStyle>)
		case didChange(SignalInput<String>)
	}

	public struct Preparer: BinderPreparer {
		public typealias Binder = TextField
		public var linkedPreparer = inheritedBinding.Preparer()

		public init() {
		}

		public func applyBinding(_ binding: Binding, instance: Instance, storage: Storage) -> Cancellable? {
			switch binding {
			case .text(let x): return x.apply(instance, storage) { i, s, v in i.text = v }
			case .borderStyle(let x): return x.apply(instance, storage) { i, s, v in i.borderStyle = v }
			case .didChange(let x): return signalFromNotifications(name: NSNotification.Name.UITextFieldTextDidChange, object: instance).filterMap { n in (n.object as? UITextField)?.text }.cancellableBind(to: x)
			case .inheritedBinding(let s): return linkedPreparer.applyBinding(s, instance: instance, storage: storage)
			}
		}
	}

	open class Storage: Control.Storage, UITextFieldDelegate {}
}

extension BindingName where Binding: TextFieldBinding {
	// You can easily convert the `Binding` cases to `BindingName` using the following Xcode-style regex:
	// Replace: case ([^\(]+)\((.+)\)$
	// With:    public static var $1: BindingName<$2, Binding> { return BindingName<$2, Binding>({ v in .textFieldBinding(TextField.Binding.$1(v)) }) }
	public static var text: BindingName<DynamicValue<String>, Binding> { return BindingName<DynamicValue<String>, Binding>({ v in .textFieldBinding(TextField.Binding.text(v)) }) }
	public static var borderStyle: BindingName<DynamicValue<UITextBorderStyle>, Binding> { return BindingName<DynamicValue<UITextBorderStyle>, Binding>({ v in .textFieldBinding(TextField.Binding.borderStyle(v)) }) }
	public static var didChange: BindingName<SignalInput<String>, Binding> { return BindingName<SignalInput<String>, Binding>({ v in .textFieldBinding(TextField.Binding.didChange(v)) }) }
}

public protocol TextFieldConstructor: ControlConstructor {
	func constructTextField() -> UITextField
}
extension TextFieldConstructor {
	public func constructControl() -> UIControl { return constructTextField() }
}
extension UITextField: TextFieldConstructor {
	public func constructTextField() -> UITextField {
		return self
	}
}

public protocol TextFieldBinding: ControlBinding {
	static func textFieldBinding(_ binding: TextField.Binding) -> Self
}
extension TextFieldBinding {
	public static func controlBinding(_ binding: Control.Binding) -> Self {
		return Self.textFieldBinding(.inheritedBinding(binding))
	}
}
