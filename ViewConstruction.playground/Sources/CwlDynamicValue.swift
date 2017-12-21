//
//  CwlDynamicValue.swift
//  CwlViews
//
//  Created by Matt Gallagher on 2017/03/23.
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

public protocol StyleFromConstant {
	associatedtype ValueType
	static func fromConstant(_ value: ValueType) -> Self
}

public protocol StyleFromDynamic {
	associatedtype ValueType
	static func fromDynamic(_ value: Signal<ValueType>) -> Self
}

public struct StaticValue<Value>: StyleFromConstant {
	public typealias ValueType = Value
	public let value: Value
	public init(_ value: Value) {
		self.value = value
	}
	public static func constant(_ value: Value) -> StaticValue<Value> {
		return StaticValue<Value>(value)
	}
	public static func fromConstant(_ value: Value) -> StaticValue<Value> {
		return StaticValue<Value>(value)
	}
}

public enum DynamicValue<Value>: StyleFromConstant, StyleFromDynamic {
	public typealias ValueType = Value
	case constant(Value)
	case dynamic(Signal<Value>)
	
	public static func fromConstant(_ value: Value) -> DynamicValue<Value> {
		return DynamicValue<Value>.constant(value)
	}
	public static func fromDynamic(_ value: Signal<Value>) -> DynamicValue<Value> {
		return DynamicValue<Value>.dynamic(value)
	}

	/// Gets the initial (i.e. used in the constructor) value from the `DynamicValue`
	public func capture() -> Captured<Value> {
		switch self {
		case .constant(let v):
			return Captured<Value>(initial: v)
		case .dynamic(let signal):
			let sc = signal.capture()
			return Captured<Value>(initial: sc.activation().0.last, subsequent: sc)
		}
	}
	
	// Gets the subsequent (i.e. after construction) values from the `DynamicValue`
	public func apply<I: AnyObject, B: BinderStorage>(_ instance: I, _ storage: B, _ onError: Value? = nil, handler: @escaping (I, B, Value) -> Void) -> Cancellable? {
		switch self {
		case .constant(let v):
			handler(instance, storage, v)
			return nil
		case .dynamic(let signal):
			return signal.subscribe(context: .main) { [weak instance, weak storage] r in
				guard let i = instance, let s = storage else { return }
				switch (r, onError) {
				case (.success(let v), _): handler(i, s, v)
				case (.failure, .some(let v)): handler(i, s, v)
				case (.failure, .none): break
				}
			}
		}
	}
}

public struct Captured<Value> {
	private var capturedValue: Value?
	var shouldResend: Bool
	let subsequent: SignalCapture<Value>?
	
	init(initial: Value? = nil, shouldResend: Bool = true, subsequent: SignalCapture<Value>? = nil) {
		self.capturedValue = initial
		self.shouldResend = shouldResend
		self.subsequent = subsequent
	}
	
	mutating func initial() -> Value? {
		let c = capturedValue
		capturedValue = nil
		shouldResend = false
		return c
	}

	func resume() -> Signal<Value>? {
		if let s = subsequent {
			return s.resume(resend: shouldResend)
		} else if shouldResend, let i = capturedValue {
			return Signal<Value>.preclosed(i)
		}
		return nil
	}
}

extension Signal {
	public func apply<I: AnyObject, B: BinderStorage>(_ instance: I, _ storage: B, handler: @escaping (I, B, OutputValue) -> Void) -> Cancellable? {
		return subscribeValues(context: .main) { [weak instance, weak storage] v in
			guard let i = instance, let s = storage else { return }
			handler(i, s, v)
		}
	}
}

extension SignalCapture {
	public func apply<I: AnyObject, B: BinderStorage>(_ instance: I, _ storage: B, handler: @escaping (I, B, OutputValue) -> Void) -> Cancellable? {
		return subscribeValues(context: .main) { [weak instance, weak storage] v in
			guard let i = instance, let s = storage else { return }
			handler(i, s, v)
		}
	}
}

