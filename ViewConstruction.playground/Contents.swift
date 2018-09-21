/*:

This code accompanies the [Cocoa with Love](https://www.cocoawithlove.com) article [A view construction syntax](https://www.cocoawithlove.com/blog/a-view-construction-syntax.html). Please read that article for more information.

Copyright © 2017 Matt Gallagher. All rights reserved. Code samples may be used in accordance with the ISC-style license at the bottom of this page.

---

# View Construction

This playground shows three different approaches for constructing a `UITextField` with a common set of behaviors. The approach include typical Cocoa, a reactive programming approach and a novel declarative syntax taken from the upcoming "CwlViews" library.

### Using the Assistant View

To display the "view" for this playgrounds page, you should enable the Playgrounds "Live View". To do this,

1. Make sure you can see Assistant Editor (from the menubar: "View" → "Assistant Editor" → "Show Assistant Editor").
2. Use the toolbar at the top of the Assistant Editor to select "Live View" (the popup you need is to the right of the "< >" arrows but to the left of the filename/filepath.

In the Xcode 9.2 version I'm using, editing text is tricky – the keyboard doesn't appear properly and only the q, w, e, r, t keys of an iPad keyboard are fully visible – but that should be enough to make some basic changes.

*/
import UIKit
import PlaygroundSupport


class PersonViewController: BaseViewController {
	enum Approach { case cocoaViews, reactiveViews, cwlViews }

//: **Edit the next line to swift between the different implementations...**
	let approach = Approach.cwlViews
	
	override func constructNameField() {
		switch approach {
		case .cocoaViews: cocoaViews()
		case .reactiveViews: reactiveViews()
		case .cwlViews: cwlViews()
		}
	}
	
//: **CwlViews**
	func cwlViews() {
		self.nameField = UITextField(
			.borderStyle -- .roundedRect,
			.enabled -- ViewState.shared.personSignal
				.map { $0.isEditing },
			.backgroundColor -- ViewState.shared.personSignal
				.map { $0.isEditing ? .white : .lightGray },
			.text -- ViewState.shared.personSignal
				.flatMapLatest { Document.shared.signalForPerson(withId: $0.id) }
				.map { $0.name },
			.didChange -- Input()
				.triggerCombine(ViewState.shared.personSignal)
				.map { .setName($0.trigger, $0.sample.id) }
				.bind(to: Document.shared)
		)
	}
	
//: **Reactive Views**
	var endpoints: [Cancellable] = []
	func reactiveViews() {
		let field = UITextField()
		self.nameField = field

		// Constant properties
		field.borderStyle = .roundedRect
		
		// Dynamic properties
		self.endpoints += ViewState.shared.personSignal.subscribeValues { state in
			field.isEnabled = state.isEditing
			field.backgroundColor = state.isEditing ? .white : .lightGray
		}
		self.endpoints += ViewState.shared.personSignal
			.flatMapLatest { Document.shared.signalForPerson(withId: $0.id) }
			.map { $0.name }
			.subscribeValues { field.text = $0 }

		// Actions
		signalFromNotifications(name: UITextField.textDidChangeNotification, object: field)
			.filterMap { ($0.object as? UITextField)?.text }
			.triggerCombine(ViewState.shared.personSignal)
			.map { .setName($0.trigger, $0.sample.id) }
			.bind(to: Document.shared)
	}
	
//: **Cocoa Views**
	public var personViewState: PersonViewState?
	public var person: Person?
	public var observations: [NSObjectProtocol] = []
	func updatePerson(_ person: Person) {
		self.person = person
		nameField?.text = person.name
	}
	func cocoaViews() {
		let field = UITextField()
		self.nameField = field

		// Constant properties
		field.borderStyle = .roundedRect
		
		// Dynamic properties
		observations += ViewState.shared.addObserver { [weak self] state in
			guard let s = self else { return }
			s.personViewState = state.personViewState
			s.nameField?.isEnabled = state.personViewState.isEditing
			s.nameField?.backgroundColor = state.personViewState.isEditing ? .white : .lightGray
			if s.person?.id != state.personViewState.id,
			let person = Document.shared.person(forId: state.personViewState.id) {
				s.updatePerson(person)
			}
		}
		observations += Document.shared.addObserver { [weak self] document in
			guard let s = self, let id = s.personViewState?.id, let person = document.person(forId: id) else { return }
			s.updatePerson(person)
		}

		// Actions
		let o = NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: field, queue: nil) { [weak self] n in
			guard let s = self, let text = (n.object as? UITextField)?.text, let pvs = s.personViewState else { return }
			Document.shared.setName(text, forPersonId: pvs.id)
		}
		observations.append(o)
	}
}

// Present the view controller in the Live View window
PlaygroundPage.current.liveView = PersonViewController()


/*:
## Code license

Copyright © 2017 Matt Gallagher ( [http://cocoawithlove.com](http://cocoawithlove.com) ). All rights reserved.

Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED “AS IS” AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

*/

