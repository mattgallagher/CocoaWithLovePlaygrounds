//
//  CwlStyle.swift
//  CwlViews
//
//  Created by Matt Gallagher on 2017/06/04.
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

#if os(macOS)
	import Cocoa
#elseif os(iOS)
	import UIKit
#endif

public protocol BaseBinding {
	associatedtype Binder = DerivedBinder
	static func baseBinderBinding(_ binding: BaseBinder.Binding) -> Self
}

public protocol BinderChain {
	associatedtype inheritedBinding
	associatedtype Instance
	associatedtype Storage
	associatedtype Binding
	associatedtype Preparer
}

public protocol DerivedBinder: BinderChain where inheritedBinding: BinderChain {
	static func bindingToinheritedBinding(_ binding: Binding) -> inheritedBinding.Binding?
}

public struct BinderChainEnd: BinderChain {
	public typealias Instance = ()
	public typealias Storage = ()
	public typealias inheritedBinding = ()
	public typealias Binding = ()
	public typealias Preparer = ()
}

public struct BaseBinder: DerivedBinder {
	public typealias Instance = Any
	public typealias Storage = Any
	public typealias inheritedBinding = BinderChainEnd
	public static func bindingToinheritedBinding(_ binding: Binding) -> inheritedBinding.Binding? { return nil }

	public enum Binding: BaseBinding {
		public typealias Binder = BaseBinder
		public static func baseBinderBinding(_ binding: Binding) -> Binding { return binding }

		/// Each value in the cancelOnClose will be cancelled when the `Storage` is released. This is guaranteed to be invoked on the main thread (if `Storage` is released on a non-main thread, the effect will occur asynchronously on the main thread).
		case cancelOnClose(DynamicValue<[Cancellable]>)
	}

	public struct Preparer: BinderPreparer {
		public typealias Binder = BaseBinder

		public init() {}
		public func linkedParameters(_ instance: Instance, storage: Storage) -> (instance: inheritedBinding.Instance, storage: inheritedBinding.Storage)? {
			return nil
		}
		public var linkedPreparer: () {
			get { return () }
			set { }
		}
		public mutating func prepareBinding(_ binding: Binding) {}
		public mutating func prepareInstance(_ instance: Instance, storage: Storage) {}
		public mutating func finalizeInstance(_ instance: Instance, storage: Storage) -> Cancellable? { return nil }
		public func applyBinding(_ binding: Binding, instance: Instance, storage: Storage) -> Cancellable? {
			switch binding {
			case .cancelOnClose(let x):
				switch x {
				case .constant(let array): return ArrayOfCancellables(array)
				case .dynamic(let signal): return signal.continuous().subscribe { r in }
				}
			}
		}
	}
}

public struct StateDependentValue<State, Value> {
	public let bindings: [(State, Value)]
	public init(_ bindings: (State, Value)...) {
		self.bindings = bindings
	}
	public init(_ bindings: [(State, Value)]) {
		self.bindings = bindings
	}
	public init(state: State, value: Value) {
		self.bindings = [(state, value)]
	}
	public static func value(_ value: Value, for state: State) -> StateDependentValue<State, Value> {
		return StateDependentValue(state: state, value: value)
	}
}

extension BindingName where Binding: BaseBinding {
	// You can easily convert the `Binding` cases to `BindingName` using the following Xcode-style regex:
	// Replace: case ([^\(]+)\((.+)\)$
	// With:    public static var $1: BindingName<$2, Binding> { return BindingName<$2, Binding>({ v in .baseBinderBinding(BaseBinder.Binding.$1(v)) }) }
	public static var cancelOnClose: BindingName<DynamicValue<[Cancellable]>, Binding> { return BindingName<DynamicValue<[Cancellable]>, Binding>({ v in .baseBinderBinding(BaseBinder.Binding.cancelOnClose(v)) }) }
}

public protocol BinderStorage: class, Cancellable {
	/// The `BinderStorage` needs to maintain the lifetime of all the self-managing objects, the most common of which are `Signal` and `SignalInput` instances but others may include `DispatchSourceTimer`. Most of these objects implement `Cancellable` so maintaining their lifetime is as simple as retaining these `Cancellable` instances in an array.
	/// The `bindings` array should be set precisely once, at the end of construction and an assertion may be raised if subsequent mutations are attempted.
	func setCancellables(_ cancellables: [Cancellable])
	
	/// Since the `BinderStorage` object is a supporting instance for the stateful object and exists to manage interactions but it is possible that the stateful object is constructed without the intention of mutation or interaction – in which case, the `BinderStorage` is not needed. The `inUse` getter is provided to ask if the `BinderStorage` is really necessary (a result of `true` may result in the `BinderStorage` being immediately discarded).
	var inUse: Bool { get }
}

infix operator --: AssignmentPrecedence

public struct BindingName<Value, Binding> {
	public var constructor: (Value) -> Binding
	public init(_ constructor: @escaping (Value) -> Binding) {
		self.constructor = constructor
	}

	public static func --<Interface: SignalInterface>(name: BindingName<Value, Binding>, value: Interface) -> Binding where Signal<Interface.OutputValue> == Value {
		return name.constructor(value.signal)
	}

	public static func --<InputInterface: SignalInputInterface>(name: BindingName<Value, Binding>, value: InputInterface) -> Binding where SignalInput<InputInterface.InputValue> == Value {
		return name.constructor(value.input)
	}

	public static func --(name: BindingName<Value, Binding>, value: Value) -> Binding {
		return name.constructor(value)
	}
}

extension BindingName where Value: StyleFromDynamic {
	public static func --<Interface: SignalInterface>(name: BindingName<Value, Binding>, value: Interface) -> Binding where Interface.OutputValue == Value.ValueType {
		return name.constructor(Value.fromDynamic(value.signal))
	}
}

extension BindingName where Value: StyleFromConstant {
	public static func --(name: BindingName<Value, Binding>, value: Value.ValueType) -> Binding {
		return name.constructor(Value.fromConstant(value))
	}
}
