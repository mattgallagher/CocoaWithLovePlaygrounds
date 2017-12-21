//
//  Model.swift
//
//  Created by Matt Gallagher on 17/12/2017.
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

import Foundation

let viewStateNotification = Notification.Name("ViewStateNotification")
let documentNotification = Notification.Name("DocumentNotification")

public class ViewState {
	public static var shared = ViewState()
	public var personViewState = PersonViewState()

	private var personChannel = Signal<PersonViewState>.channel().continuous(initialValue: PersonViewState())
	public var personSignal: Signal<PersonViewState> { return personChannel.signal }
	
	public func toggleEditing() {
		personViewState.isEditing = !personViewState.isEditing
		NotificationCenter.default.post(name: viewStateNotification, object: self)
		personChannel.input.send(value: personViewState)
	}
	
	public func togglePerson() {
		personViewState.id = personViewState.id == 0 ? 1 : 0
		NotificationCenter.default.post(name: viewStateNotification, object: self)
		personChannel.input.send(value: personViewState)
	}
	
	public func addObserver(_ callback: @escaping (ViewState) -> ()) -> [NSObjectProtocol] {
		let first = NotificationCenter.default.addObserver(forName: viewStateNotification, object: self, queue: nil) { [weak self] n in
			if let s = self {
				callback(s)
			}
		}
		callback(self)
		return [first]
	}
}

public struct PersonViewState {
	public var id: Int = 0
	public var isEditing: Bool = false
}

public struct Person {
	public var id: Int = 0
	public var name: String = "DefaultName"
}

public class Document: SignalInputInterface {
	public static var shared = Document()
	
	var firstPerson = Person(id: 0, name: "First person")
	var secondPerson = Person(id: 1, name: "Second person")
	
	public enum Message {
		case setName(String, Int)
	}
	
	private var documentChannel = Signal<Document>.channel().continuous()
	
	public var input: SignalInput<Message> {
		return Input<Message>().subscribeValuesUntilEnd { [weak self] (message: Message) -> () in
			switch message {
			case .setName(let name, let id):
				self?.setName(name, forPersonId: id)
			}
		}
	}
	public func signalForPerson(withId id: Int) -> Signal<Person> {
		switch id {
		case 0: return documentChannel.signal.map { $0.firstPerson }.startWith(firstPerson)
		case 1: return documentChannel.signal.map { $0.secondPerson }.startWith(secondPerson)
		default: return Signal.preclosed()
		}
	}
	
	public func setName(_ name: String, forPersonId id: Int) {
		switch id {
		case 0: firstPerson.name = name
		case 1: secondPerson.name = name
		default: fatalError("Unknown person id")
		}
		NotificationCenter.default.post(name: documentNotification, object: self)
		documentChannel.input.send(value: self)
	}
	
	public func resetName(forPersonId id: Int) {
		switch id {
		case 0: firstPerson.name = "First person"
		case 1: secondPerson.name = "Second person"
		default: fatalError("Unknown person id")
		}
		NotificationCenter.default.post(name: documentNotification, object: self)
		documentChannel.input.send(value: self)
	}
	
	public func person(forId id: Int) -> Person? {
		switch id {
		case 0: return firstPerson
		case 1: return secondPerson
		default: return nil
		}
	}
	
	public func addObserver(_ callback: @escaping (Document) -> ()) -> [NSObjectProtocol] {
		let first = NotificationCenter.default.addObserver(forName: documentNotification, object: self, queue: nil) { [weak self] n in
			if let s = self {
				callback(s)
			}
		}
		callback(self)
		return [first]
	}
}
