//
//  CwlBinderPreparer.swift
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

/// A definition of construct lifecycle events.
public protocol BinderPreparer {
	associatedtype Binder: DerivedBinder

	var linkedPreparer: Binder.inheritedBinding.Preparer { get set }
	
	init()
	
	mutating func prepareBinding(_ binding: Binder.Binding)
	mutating func prepareInstance(_ instance: Binder.Instance, storage: Binder.Storage)
	func applyBinding(_ binding: Binder.Binding, instance: Binder.Instance, storage: Binder.Storage) -> Cancellable?
	mutating func finalizeInstance(_ instance: Binder.Instance, storage: Binder.Storage) -> Cancellable?
}

extension BinderPreparer {
	public mutating func prepareBindings<C: RangeReplaceableCollection>( _ bindings: C) where C.Iterator.Element == Binder.Binding {
		for b in bindings {
			prepareBinding(b)
		}
	}
	
	public mutating func applyBindings<C: RangeReplaceableCollection>(_ bindings: C, instance: Binder.Instance, storage: Binder.Storage, combine: (Binder.Instance, Binder.Storage, [Cancellable]) -> ()) where C.Iterator.Element == Binder.Binding {
		// Prepare.
		prepareInstance(instance, storage: storage)
		
		// Apply styles that need to be applied after construction
		var cancellables = [Cancellable]()
		for b in bindings {
			if let c = applyBinding(b, instance: instance, storage: storage) {
				cancellables.append(c)
			}
		}
		
		// Finalize the instance
		if let c = finalizeInstance(instance, storage: storage) {
			cancellables.append(c)
		}
		
		// Combine the instance and binder
		combine(instance, storage, cancellables)
	}
}

extension BinderPreparer where Binder.inheritedBinding.Preparer: BinderPreparer, Binder.inheritedBinding.Preparer.Binder == Binder.inheritedBinding, Binder.inheritedBinding.Binding: BaseBinding, Binder.inheritedBinding.Binding.Binder == Binder.inheritedBinding {
	public mutating func prepareInstance(_ instance: Binder.Instance, storage: Binder.Storage) {
		if let i = instance as? Binder.inheritedBinding.Instance, let s = storage as? Binder.inheritedBinding.Storage {
			linkedPreparer.prepareInstance(i, storage: s)
		}
	}
	
	public mutating func finalizeInstance(_ instance: Binder.Instance, storage: Binder.Storage) -> Cancellable? {
		if let i = instance as? Binder.inheritedBinding.Instance, let s = storage as? Binder.inheritedBinding.Storage {
			return linkedPreparer.finalizeInstance(i, storage: s)
		}
		return nil
	}


	public func applyBinding(_ binding: Binder.Binding, instance: Binder.Instance, storage: Binder.Storage) -> Cancellable? {
		if let ls = Binder.bindingToinheritedBinding(binding), let i = instance as? Binder.inheritedBinding.Instance, let s = storage as? Binder.inheritedBinding.Storage {
			return linkedPreparer.applyBinding(ls, instance: i, storage: s)
		}
		return nil
	}

	public mutating func prepareBinding(_ binding: Binder.Binding) {
		if let ls = Binder.bindingToinheritedBinding(binding) {
			linkedPreparer.prepareBinding(ls)
		}
	}
}

