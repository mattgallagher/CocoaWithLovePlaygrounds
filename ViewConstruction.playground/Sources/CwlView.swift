//
//  CwlView.swift
//  CwlViews
//
//  Created by Matt Gallagher on 19/10/2015.
//  Copyright © 2015 Matt Gallagher ( http://cocoawithlove.com ). All rights reserved.
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

public struct View: DerivedBinder, ViewConstructor {
	public typealias Instance = UIView
	public typealias inheritedBinding = BaseBinder
	
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
	public func constructView() -> UIView {
		let x = subclass.init()
		applyBindings(to: x)
		return x
	}

	public enum Binding: ViewBinding {
		public typealias Binder = View
		public static func viewBinding(_ binding: Binding) -> Binding { return binding }
      case inheritedBinding(inheritedBinding.Binding)
		
		case backgroundColor(DynamicValue<(UIColor?)>)
	}

	public struct Preparer: BinderPreparer {
		public typealias Binder = View
		public var linkedPreparer = inheritedBinding.Preparer()
		
		public init() {}
		
		public func applyBinding(_ binding: Binding, instance: Instance, storage: Storage) -> Cancellable? {
			switch binding {
			case .backgroundColor(let x): return x.apply(instance, storage) { i, s, v in i.backgroundColor = v }
			case .inheritedBinding(let s): return linkedPreparer.applyBinding(s, instance: (), storage: ())
			}
		}
	}

	public typealias Storage = ObjectBinderStorage
}

extension BindingName where Binding: ViewBinding {
	// You can easily convert the `Binding` cases to `BindingName` using the following Xcode-style regex:
	// Replace: case ([^\(]+)\((.+)\)$
	// With:    public static var $1: BindingName<$2, Binding> { return BindingName<$2, Binding>({ v in .viewBinding(View.Binding.$1(v)) }) }
	public static var backgroundColor: BindingName<DynamicValue<(UIColor?)>, Binding> { return BindingName<DynamicValue<(UIColor?)>, Binding>({ v in .viewBinding(View.Binding.backgroundColor(v)) }) }
}

public protocol ViewBinding: BaseBinding {
	static func viewBinding(_ binding: View.Binding) -> Self
}
extension ViewBinding {
	public static func baseBinderBinding(_ binding: BaseBinder.Binding) -> Self {
		return Self.viewBinding(.inheritedBinding(binding))
	}
}


