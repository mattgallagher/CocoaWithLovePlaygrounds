import UIKit

public func newLabel(_ string: String) -> UILabel {
	let label = UILabel()
	label.frame = CGRect(x: 150, y: 100, width: 400, height: 20)
	label.text = string
	label.numberOfLines = 0
	label.textAlignment = .center
	label.baselineAdjustment = .alignBaselines
	label.textColor = .white
	label.backgroundColor = UIColor(displayP3Red: 0.2, green: 0.4, blue: 0.6, alpha: 1)
	return label
}
public func newView() -> UIView {
	let view = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 150))
	view.backgroundColor = .lightGray
	return view
}

public let longLabel = "The text of this label is long enough that it forces the aligned bottom edge of the labels downwards."
public let shortLabel = "This label text is significantly shorter."

public func runExample(reversed: Bool, example: (UIView, UILabel, UILabel) -> ()) -> UIView {
	let left = newLabel(reversed ? shortLabel : longLabel)
	let right = newLabel(reversed ? longLabel : shortLabel)
	let view = newView()
	example(view, left, right)
	view.layoutIfNeeded()
	return view
}
