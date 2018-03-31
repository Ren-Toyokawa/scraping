/// A row where the user can enter an integer number.
public final class IntRow: _IntRow, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

open class _IntRow: FieldRow<IntCell> {
    public required init(tag: String?) {
        super.init(tag: tag)
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale.current
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 0
        formatter = numberFormatter
    }
}


open class IntCell: _FieldCell<Int>, CellType {

    required public init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    open override func setup() {
        super.setup()
        textField.autocorrectionType = .default
        textField.autocapitalizationType = .none
        textField.keyboardType = .numberPad
    }
}

open class _FieldCell<T> : Cell<T>, UITextFieldDelegate, TextFieldCell where T: Equatable, T: InputTypeInitiable {

    // フィールド
    @IBOutlet public weak var textField: UITextField!
    @IBOutlet public weak var titleLabel: UILabel?

    // flag?
    fileprivate var observingTitleText = false
    private var awakeFromNibCalled = false

    // ?
    open var dynamicConstraints = [NSLayoutConstraint]()
	// titleの比率？
	private var calculatedTitlePercentage: CGFloat = 0.7
	// required ... サブクラスのオーバーライドを強制している(https://qiita.com/cotrpepe/items/3931c0c20ef43f4a18ac)
    public required init(style: UITableViewCellStyle, reuseIdentifier: String?) {

    	// インスタンスを生成している
        let textField = UITextField()
        self.textField = textField
        // これをTrueにすると だいたい自分の追加したAuto Layout制約とコンフリクトするため、falseとしている(https://qiita.com/shindooo/items/f0259f1be59591503dc1)
        textField.translatesAutoresizingMaskIntoConstraints = false

        //　Cell.swift　のイニシャライザ
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        // 
        titleLabel = self.textLabel
        titleLabel?.translatesAutoresizingMaskIntoConstraints = false
        titleLabel?.setContentHuggingPriority(UILayoutPriority(500), for: .horizontal)
        titleLabel?.setContentCompressionResistancePriority(UILayoutPriority(1000), for: .horizontal)\

        // UIViewv
        // Storybord -> View -> cell -> contentView
        contentView.addSubview(titleLabel!)
        contentView.addSubview(textField)

        // 通知を送る設定らしい
        // この通知は普通の通知なのか？それともプログラミング的な通知なのか？
        NotificationCenter.default.addObserver(forName: Notification.Name.UIApplicationWillResignActive, object: nil, queue: nil) { [weak self] _ in
            

            guard let me = self else { return }
            guard me.observingTitleText else { return }
            me.titleLabel?.removeObserver(me, forKeyPath: "text")
            me.observingTitleText = false
        }
        NotificationCenter.default.addObserver(forName: Notification.Name.UIApplicationDidBecomeActive, object: nil, queue: nil) { [weak self] _ in
            guard let me = self else { return }
            guard !me.observingTitleText else { return }
            me.titleLabel?.addObserver(me, forKeyPath: "text", options: NSKeyValueObservingOptions.old.union(.new), context: nil)
            me.observingTitleText = true
        }

        NotificationCenter.default.addObserver(forName: Notification.Name.UIContentSizeCategoryDidChange, object: nil, queue: nil) { [weak self] _ in
            self?.titleLabel = self?.textLabel
            self?.setNeedsUpdateConstraints()
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        awakeFromNibCalled = true
    }

    deinit {
        textField?.delegate = nil
        textField?.removeTarget(self, action: nil, for: .allEvents)
        guard !awakeFromNibCalled else { return }
        if observingTitleText {
            titleLabel?.removeObserver(self, forKeyPath: "text")
        }
        imageView?.removeObserver(self, forKeyPath: "image")
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIContentSizeCategoryDidChange, object: nil)
    }

    open override func setup() {
        super.setup()
        selectionStyle = .none

        if !awakeFromNibCalled {
            titleLabel?.addObserver(self, forKeyPath: "text", options: NSKeyValueObservingOptions.old.union(.new), context: nil)
            observingTitleText = true
            imageView?.addObserver(self, forKeyPath: "image", options: NSKeyValueObservingOptions.old.union(.new), context: nil)
        }
        textField.addTarget(self, action: #selector(_FieldCell.textFieldDidChange(_:)), for: .editingChanged)

    }

    open override func update() {
        super.update()
        detailTextLabel?.text = nil

        if !awakeFromNibCalled {
            if let title = row.title {
                textField.textAlignment = title.isEmpty ? .left : .right
                textField.clearButtonMode = title.isEmpty ? .whileEditing : .never
            } else {
                textField.textAlignment =  .left
                textField.clearButtonMode =  .whileEditing
            }
        }
        textField.delegate = self
        textField.text = row.displayValueFor?(row.value)
        textField.isEnabled = !row.isDisabled
        textField.textColor = row.isDisabled ? .gray : .black
        textField.font = .preferredFont(forTextStyle: .body)
        if let placeholder = (row as? FieldRowConformance)?.placeholder {
            if let color = (row as? FieldRowConformance)?.placeholderColor {
                textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedStringKey.foregroundColor: color])
            } else {
                textField.placeholder = (row as? FieldRowConformance)?.placeholder
            }
        }
        if row.isHighlighted {
            textLabel?.textColor = tintColor
        }
    }

    open override func cellCanBecomeFirstResponder() -> Bool {
        return !row.isDisabled && textField?.canBecomeFirstResponder == true
    }

    open override func cellBecomeFirstResponder(withDirection: Direction) -> Bool {
        return textField?.becomeFirstResponder() ?? false
    }

    open override func cellResignFirstResponder() -> Bool {
        return textField?.resignFirstResponder() ?? true
    }

    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let obj = object as AnyObject?

        if let keyPathValue = keyPath, let changeType = change?[NSKeyValueChangeKey.kindKey],
            ((obj === titleLabel && keyPathValue == "text") || (obj === imageView && keyPathValue == "image")) &&
                (changeType as? NSNumber)?.uintValue == NSKeyValueChange.setting.rawValue {
            setNeedsUpdateConstraints()
            updateConstraintsIfNeeded()
        }
    }

    // MARK: Helpers

    open func customConstraints() {

        guard !awakeFromNibCalled else { return }
        contentView.removeConstraints(dynamicConstraints)
        dynamicConstraints = []
        var views: [String: AnyObject] =  ["textField": textField]
        dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-11-[textField]-11-|", options: .alignAllLastBaseline, metrics: nil, views: views)

        if let label = titleLabel, let text = label.text, !text.isEmpty {
            dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-11-[titleLabel]-11-|", options: .alignAllLastBaseline, metrics: nil, views: ["titleLabel": label])
            dynamicConstraints.append(NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: textField, attribute: .centerY, multiplier: 1, constant: 0))
        }
        if let imageView = imageView, let _ = imageView.image {
            views["imageView"] = imageView
            if let titleLabel = titleLabel, let text = titleLabel.text, !text.isEmpty {
                views["label"] = titleLabel
                dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:[imageView]-(15)-[label]-[textField]-|", options: NSLayoutFormatOptions(), metrics: nil, views: views)
				dynamicConstraints.append(NSLayoutConstraint(item: titleLabel,
				                                             attribute: .width,
				                                             relatedBy: (row as? FieldRowConformance)?.titlePercentage != nil ? .equal : .lessThanOrEqual,
				                                             toItem: contentView,
				                                             attribute: .width,
				                                             multiplier: calculatedTitlePercentage,
				                                             constant: 0.0))
            }
            else{
                dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:[imageView]-(15)-[textField]-|", options: [], metrics: nil, views: views)
            }
        }
        else{
			if let titleLabel = titleLabel, let text = titleLabel.text, !text.isEmpty {
                views["label"] = titleLabel
                dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[label]-[textField]-|", options: [], metrics: nil, views: views)
				dynamicConstraints.append(NSLayoutConstraint(item: titleLabel,
				                                             attribute: .width,
				                                             relatedBy: (row as? FieldRowConformance)?.titlePercentage != nil ? .equal : .lessThanOrEqual,
				                                             toItem: contentView,
				                                             attribute: .width,
				                                             multiplier: calculatedTitlePercentage,
				                                             constant: 0.0))
            }
            else{
                dynamicConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[textField]-|", options: .alignAllLeft, metrics: nil, views: views)
            }
        }
        contentView.addConstraints(dynamicConstraints)
    }

    open override func updateConstraints() {
        customConstraints()
        super.updateConstraints()
    }

    @objc open func textFieldDidChange(_ textField: UITextField) {

        guard let textValue = textField.text else {
            row.value = nil
            return
        }
        guard let fieldRow = row as? FieldRowConformance, let formatter = fieldRow.formatter else {
            row.value = textValue.isEmpty ? nil : (T.init(string: textValue) ?? row.value)
            return
        }
        if fieldRow.useFormatterDuringInput {
            let value: AutoreleasingUnsafeMutablePointer<AnyObject?> = AutoreleasingUnsafeMutablePointer<AnyObject?>.init(UnsafeMutablePointer<T>.allocate(capacity: 1))
            let errorDesc: AutoreleasingUnsafeMutablePointer<NSString?>? = nil
            if formatter.getObjectValue(value, for: textValue, errorDescription: errorDesc) {
                row.value = value.pointee as? T
                guard var selStartPos = textField.selectedTextRange?.start else { return }
                let oldVal = textField.text
                textField.text = row.displayValueFor?(row.value)
                selStartPos = (formatter as? FormatterProtocol)?.getNewPosition(forPosition: selStartPos, inTextInput: textField, oldValue: oldVal, newValue: textField.text) ?? selStartPos
                textField.selectedTextRange = textField.textRange(from: selStartPos, to: selStartPos)
                return
            }
        } else {
            let value: AutoreleasingUnsafeMutablePointer<AnyObject?> = AutoreleasingUnsafeMutablePointer<AnyObject?>.init(UnsafeMutablePointer<T>.allocate(capacity: 1))
            let errorDesc: AutoreleasingUnsafeMutablePointer<NSString?>? = nil
            if formatter.getObjectValue(value, for: textValue, errorDescription: errorDesc) {
                row.value = value.pointee as? T
            } else {
                row.value = textValue.isEmpty ? nil : (T.init(string: textValue) ?? row.value)
            }
        }
    }

    // MARK: Helpers

    private func displayValue(useFormatter: Bool) -> String? {
        guard let v = row.value else { return nil }
        if let formatter = (row as? FormatterConformance)?.formatter, useFormatter {
            return textField?.isFirstResponder == true ? formatter.editingString(for: v) : formatter.string(for: v)
        }
        return String(describing: v)
    }

    // MARK: TextFieldDelegate

    open func textFieldDidBeginEditing(_ textField: UITextField) {
        formViewController()?.beginEditing(of: self)
        formViewController()?.textInputDidBeginEditing(textField, cell: self)
        if let fieldRowConformance = row as? FormatterConformance, let _ = fieldRowConformance.formatter, fieldRowConformance.useFormatterOnDidBeginEditing ?? fieldRowConformance.useFormatterDuringInput {
            textField.text = displayValue(useFormatter: true)
        } else {
            textField.text = displayValue(useFormatter: false)
        }
    }

    open func textFieldDidEndEditing(_ textField: UITextField) {
        formViewController()?.endEditing(of: self)
        formViewController()?.textInputDidEndEditing(textField, cell: self)
        textFieldDidChange(textField)
        textField.text = displayValue(useFormatter: (row as? FormatterConformance)?.formatter != nil)
    }

    open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return formViewController()?.textInputShouldReturn(textField, cell: self) ?? true
    }

    open func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return formViewController()?.textInput(textField, shouldChangeCharactersInRange:range, replacementString:string, cell: self) ?? true
    }

    open func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return formViewController()?.textInputShouldBeginEditing(textField, cell: self) ?? true
    }

    open func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return formViewController()?.textInputShouldClear(textField, cell: self) ?? true
    }

    open func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return formViewController()?.textInputShouldEndEditing(textField, cell: self) ?? true
	}
	
	open override func layoutSubviews() {
		super.layoutSubviews()
		guard let row = (row as? FieldRowConformance) else { return }
		guard let titlePercentage = row.titlePercentage else  { return }
		var targetTitleWidth = bounds.size.width * titlePercentage
		if let imageView = imageView, let _ = imageView.image, let titleLabel = titleLabel {
			var extraWidthToSubtract = titleLabel.frame.minX - imageView.frame.minX // Left-to-right interface layout
			if #available(iOS 9.0, *) {
				if UIView.userInterfaceLayoutDirection(for: self.semanticContentAttribute) == .rightToLeft {
					extraWidthToSubtract = imageView.frame.maxX - titleLabel.frame.maxX
				}
			}
			targetTitleWidth -= extraWidthToSubtract
		}
		let targetTitlePercentage = targetTitleWidth / contentView.bounds.size.width
		if calculatedTitlePercentage != targetTitlePercentage {
			calculatedTitlePercentage = targetTitlePercentage
			setNeedsUpdateConstraints()
			updateConstraintsIfNeeded()
		}
	}
}
