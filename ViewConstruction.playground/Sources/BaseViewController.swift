//
//  BaseViewController.swift
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
import UIKit

open class BaseViewController:UIViewController {
	public var nameField: UITextField?
	
	open func constructNameField() {
		nameField = UITextField()
	}

	open override func loadView() {
		self.view = UIView()
		self.view.backgroundColor = .white
		
		let nameFieldLabel = UILabel()
		nameFieldLabel.text = "Name Field:"
		
		let resetButton = UIButton(type: .roundedRect)
		resetButton.setTitle("Reset name for current person", for: .normal)
		resetButton.addTarget(self, action: #selector(buttonAction2), for: .primaryActionTriggered)
		resetButton.backgroundColor = UIColor(white: 0.92, alpha: 1)
		resetButton.layer.cornerRadius = 8
		
		let toggleLabel = UILabel()
		toggleLabel.text = "Toggle isEditable:"
		toggleLabel.textAlignment = .right
		let editToggle = UISwitch()
		editToggle.addTarget(self, action: #selector(toggleSwitch), for: .valueChanged)
		
		let switchLabel = UILabel()
		switchLabel.text = "Switch between Person 1/2:"
		switchLabel.textAlignment = .right
		let personSwitch = UISwitch()
		personSwitch.addTarget(self, action: #selector(togglePerson), for: .valueChanged)
		
		constructNameField()
		guard let field = nameField else {
			preconditionFailure("Name field was not constructed.")
		}
		
		self.view.applyLayout(.vertical(
			marginEdges: .allLayout,
			.space(40),
			.view(nameFieldLabel),
			.space(),
			.view(field),
			.space(20),
			.horizontal(align: .center,
				.view(toggleLabel),
				.space(),
				.view(length: .equalTo(ratio: 0.25), editToggle)
			),
			.space(20),
			.horizontal(align: .center,
				.view(switchLabel),
				.space(),
				.view(length: .equalTo(ratio: 0.25), personSwitch)
			),
			.space(20),
			.view(resetButton),
			.space(.fillRemaining)
		))
	}
	
	@objc public func buttonAction2() {
		Document.shared.resetName(forPersonId: ViewState.shared.personViewState.id)
	}
	
	@objc public func toggleSwitch() {
		ViewState.shared.toggleEditing()
	}
	
	@objc public func togglePerson() {
		ViewState.shared.togglePerson()
	}
}
