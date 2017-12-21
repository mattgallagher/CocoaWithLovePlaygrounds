//
//  CwlControl.swift
//  CwlViews
//
//  Created by Matt Gallagher on 2017/03/22.
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

public struct Control: DerivedBinder, ControlConstructor {
	public typealias Instance = UIControl
	public typealias inheritedBinding = View
	
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
	public func constructControl() -> UIControl {
		let x = subclass.init()
		applyBindings(to: x)
		return x
	}
	
	public enum Binding: ControlBinding {
		public typealias Binder = Control
		public static func controlBinding(_ binding: Binding) -> Binding { return binding }
      case inheritedBinding(inheritedBinding.Binding)
		
		case enabled(DynamicValue<Bool>)
	}

	public struct Preparer: BinderPreparer {
		public typealias Binder = Control
		public var linkedPreparer = inheritedBinding.Preparer()
		
		public init() {}
		
		public func applyBinding(_ binding: Binding, instance: Instance, storage: Storage) -> Cancellable? {
			switch binding {
			case .enabled(let x): return x.apply(instance, storage) { i, s, v in i.isEnabled = v }
			case .inheritedBinding(let s): return linkedPreparer.applyBinding(s, instance: instance, storage: storage)
			}
		}
	}

	public typealias Storage = View.Storage
}

extension BindingName where Binding: ControlBinding {
	// You can easily convert the `Binding` cases to `BindingName` using the following Xcode-style regex:
	// Replace: case ([^\(]+)\((.+)\)$
	// With:    public static var $1: BindingName<$2, Binding> { return BindingName<$2, Binding>({ v in .controlBinding(Control.Binding.$1(v)) }) }
	public static var enabled: BindingName<DynamicValue<Bool>, Binding> { return BindingName<DynamicValue<Bool>, Binding>({ v in .controlBinding(Control.Binding.enabled(v)) }) }
}

public protocol ControlConstructor: ViewConstructor {
	func constructControl() -> UIControl
}
extension ControlConstructor {
	public func constructView() -> UIView { return constructControl() }
}
extension UIControl: ControlConstructor {
	public func constructControl() -> UIControl {
		return self
	}
}

public protocol ControlBinding: ViewBinding {
	static func controlBinding(_ binding: Control.Binding) -> Self
}

extension ControlBinding {
	public static func viewBinding(_ binding: View.Binding) -> Self {
		return Self.controlBinding(.inheritedBinding(binding))
	}
}
