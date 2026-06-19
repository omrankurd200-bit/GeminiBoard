// KeyboardView.swift
// Full programmatic QWERTY keyboard view

import UIKit

// MARK: - Delegate
protocol KeyboardViewDelegate: AnyObject {
    func keyboardView(_ view: KeyboardView, didTapKey key: String)
    func keyboardViewDidTapDelete(_ view: KeyboardView)
    func keyboardViewDidTapReturn(_ view: KeyboardView)
    func keyboardViewDidTapSpace(_ view: KeyboardView)
    func keyboardViewDidTapNextKeyboard(_ view: KeyboardView)
    func keyboardViewDidTapShift(_ view: KeyboardView)
    func keyboardViewDidTapNumbers(_ view: KeyboardView)
}

// MARK: - KeyboardView

final class KeyboardView: UIView {
    
    weak var delegate: KeyboardViewDelegate?
    
    // MARK: - State
    enum ShiftState { case off, on, locked }
    private(set) var shiftState: ShiftState = .off
    private(set) var isShowingNumbers = false
    
    var inputText: String = "" {
        didSet { inputPreviewLabel.text = inputText.isEmpty ? "Start typing…" : inputText }
    }
    
    // MARK: - Layout Rows
    private let qwertyRows: [[String]] = [
        ["q","w","e","r","t","y","u","i","o","p"],
        ["a","s","d","f","g","h","j","k","l"],
        ["z","x","c","v","b","n","m"]
    ]
    private let numberRows: [[String]] = [
        ["1","2","3","4","5","6","7","8","9","0"],
        ["-","/",":",";","(",")","$","&","@","\""],
        [".",",","?","!","'"]
    ]
    private let symbolRows: [[String]] = [
        ["[","]","{","}","#","%","^","*","+","="],
        ["_","\\","|","~","<",">","€","£","¥","•"],
        [".",",","?","!","'"]
    ]
    
    // MARK: - UI
    private let mainStack       = UIStackView()
    private let inputPreviewLabel = UILabel()
    private var keyButtons: [UIButton] = []
    private var shiftButton: UIButton?
    private var numbersButton: UIButton?
    private var symbolsButton: UIButton?
    private var deleteButton: UIButton?
    private var isShowingSymbols = false
    
    // MARK: - Colors
    let darkBG        = UIColor(red: 0.07, green: 0.07, blue: 0.12, alpha: 1)
    let keyBG         = UIColor(red: 0.18, green: 0.18, blue: 0.25, alpha: 1)
    let specialKeyBG  = UIColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1)
    let keyText       = UIColor(white: 0.92, alpha: 1)
    let accentColor   = UIColor(red: 0.45, green: 0.30, blue: 1.00, alpha: 1)
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Setup
    
    private func setup() {
        backgroundColor = darkBG
        
        setupInputPreview()
        setupMainStack()
        buildQwertyLayout()
    }
    
    private func setupInputPreview() {
        inputPreviewLabel.text          = "Start typing…"
        inputPreviewLabel.font          = .systemFont(ofSize: 13, weight: .regular)
        inputPreviewLabel.textColor     = UIColor(white: 0.45, alpha: 1)
        inputPreviewLabel.textAlignment = .left
        inputPreviewLabel.numberOfLines = 1
        inputPreviewLabel.lineBreakMode = .byTruncatingHead
        inputPreviewLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let container = UIView()
        container.backgroundColor = UIColor(white: 1, alpha: 0.04)
        container.layer.cornerRadius = 8
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(inputPreviewLabel)
        
        NSLayoutConstraint.activate([
            inputPreviewLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            inputPreviewLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6),
            inputPreviewLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            inputPreviewLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            container.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ])
    }
    
    private func setupMainStack() {
        mainStack.axis         = .vertical
        mainStack.spacing      = 8
        mainStack.distribution = .fillEqually
        mainStack.alignment    = .fill
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 46),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
    }
    
    // MARK: - Build Layouts
    
    private func buildQwertyLayout() {
        mainStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        keyButtons.removeAll()
        let rows = isShowingNumbers ? (isShowingSymbols ? symbolRows : numberRows) : qwertyRows
        
        for (i, row) in rows.enumerated() {
            let rowStack = makeRowStack()
            
            // Shift on last row (only QWERTY mode)
            if !isShowingNumbers && i == 2 {
                let shiftBtn = makeSpecialButton(title: "⇧", width: 42)
                shiftBtn.addTarget(self, action: #selector(shiftTapped(_:)), for: .touchUpInside)
                self.shiftButton = shiftBtn
                rowStack.addArrangedSubview(shiftBtn)
            }
            
            // Number toggle on last row (only QWERTY mode)
            if isShowingNumbers && i == 2 {
                let symBtn = makeSpecialButton(title: isShowingSymbols ? "ABC" : "#+=", width: 42)
                symBtn.titleLabel?.font = .systemFont(ofSize: 10, weight: .semibold)
                symBtn.addTarget(self, action: #selector(symbolsTapped(_:)), for: .touchUpInside)
                self.symbolsButton = symBtn
                rowStack.addArrangedSubview(symBtn)
            }
            
            for char in row {
                let btn = makeKeyButton(title: char)
                btn.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
                rowStack.addArrangedSubview(btn)
                keyButtons.append(btn)
            }
            
            // Delete on last row
            if i == 2 {
                let delBtn = makeSpecialButton(title: "⌫", width: 42)
                delBtn.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
                // Long press for continuous delete
                let lp = UILongPressGestureRecognizer(target: self, action: #selector(deleteLongPress(_:)))
                lp.minimumPressDuration = 0.4
                delBtn.addGestureRecognizer(lp)
                self.deleteButton = delBtn
                rowStack.addArrangedSubview(delBtn)
            }
            
            mainStack.addArrangedSubview(rowStack)
        }
        
        // Bottom row: Globe | Numbers | Space | Return
        mainStack.addArrangedSubview(makeBottomRow())
    }
    
    private func makeBottomRow() -> UIStackView {
        let row = makeRowStack()
        
        // Globe (next keyboard)
        let globeBtn = makeSpecialButton(title: "🌐", width: 42)
        globeBtn.addTarget(self, action: #selector(globeTapped), for: .touchUpInside)
        
        // Numbers toggle
        let numBtn = makeSpecialButton(title: isShowingNumbers ? "ABC" : "123", width: 42)
        numBtn.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
        numBtn.addTarget(self, action: #selector(numbersTapped(_:)), for: .touchUpInside)
        self.numbersButton = numBtn
        
        // Space bar
        let spaceBtn = UIButton(type: .system)
        spaceBtn.setTitle("space", for: .normal)
        spaceBtn.titleLabel?.font  = .systemFont(ofSize: 14, weight: .regular)
        spaceBtn.setTitleColor(keyText, for: .normal)
        spaceBtn.backgroundColor   = keyBG
        spaceBtn.layer.cornerRadius = 8
        spaceBtn.addTarget(self, action: #selector(spaceTapped), for: .touchUpInside)
        
        // Return key
        let returnBtn = makeSpecialButton(title: "return", width: 80)
        returnBtn.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
        returnBtn.addTarget(self, action: #selector(returnTapped), for: .touchUpInside)
        
        row.addArrangedSubview(globeBtn)
        row.addArrangedSubview(numBtn)
        row.addArrangedSubview(spaceBtn)
        row.addArrangedSubview(returnBtn)
        return row
    }
    
    // MARK: - Factory Helpers
    
    private func makeRowStack() -> UIStackView {
        let stack = UIStackView()
        stack.axis         = .horizontal
        stack.spacing      = 6
        stack.distribution = .fillEqually
        stack.alignment    = .fill
        return stack
    }
    
    private func makeKeyButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font  = .systemFont(ofSize: 17, weight: .regular)
        btn.setTitleColor(keyText, for: .normal)
        btn.backgroundColor   = keyBG
        btn.layer.cornerRadius = 8
        btn.layer.shadowColor  = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.3
        btn.layer.shadowOffset  = CGSize(width: 0, height: 1)
        btn.layer.shadowRadius  = 1
        addTouchAnimation(to: btn)
        return btn
    }
    
    private func makeSpecialButton(title: String, width: CGFloat) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font  = .systemFont(ofSize: 14, weight: .medium)
        btn.setTitleColor(keyText, for: .normal)
        btn.backgroundColor   = specialKeyBG
        btn.layer.cornerRadius = 8
        btn.layer.shadowColor  = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.3
        btn.layer.shadowOffset  = CGSize(width: 0, height: 1)
        btn.layer.shadowRadius  = 1
        btn.widthAnchor.constraint(equalToConstant: width).isActive = true
        addTouchAnimation(to: btn)
        return btn
    }
    
    private func addTouchAnimation(to btn: UIButton) {
        btn.addTarget(self, action: #selector(btnTouchDown(_:)), for: .touchDown)
        btn.addTarget(self, action: #selector(btnTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    // MARK: - Key Actions
    
    @objc private func keyTapped(_ sender: UIButton) {
        guard var title = sender.currentTitle else { return }
        if !isShowingNumbers {
            switch shiftState {
            case .on, .locked: title = title.uppercased()
            case .off: break
            }
            if shiftState == .on {
                setShift(.off)
            }
        }
        UIDevice.current.playInputClick()
        delegate?.keyboardView(self, didTapKey: title)
    }
    
    @objc private func deleteTapped() {
        UIDevice.current.playInputClick()
        delegate?.keyboardViewDidTapDelete(self)
    }
    
    private var deleteTimer: Timer?
    @objc private func deleteLongPress(_ gr: UILongPressGestureRecognizer) {
        switch gr.state {
        case .began:
            deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
                guard let self else { return }
                self.delegate?.keyboardViewDidTapDelete(self)
            }
        case .ended, .cancelled, .failed:
            deleteTimer?.invalidate()
            deleteTimer = nil
        default: break
        }
    }
    
    @objc private func returnTapped() {
        UIDevice.current.playInputClick()
        delegate?.keyboardViewDidTapReturn(self)
    }
    
    @objc private func spaceTapped() {
        UIDevice.current.playInputClick()
        delegate?.keyboardViewDidTapSpace(self)
    }
    
    @objc private func globeTapped() {
        delegate?.keyboardViewDidTapNextKeyboard(self)
    }
    
    @objc private func shiftTapped(_ sender: UIButton) {
        switch shiftState {
        case .off:    setShift(.on)
        case .on:     setShift(.locked)
        case .locked: setShift(.off)
        }
    }
    
    @objc private func numbersTapped(_ sender: UIButton) {
        isShowingNumbers.toggle()
        isShowingSymbols = false
        buildQwertyLayout()
    }
    
    @objc private func symbolsTapped(_ sender: UIButton) {
        isShowingSymbols.toggle()
        buildQwertyLayout()
    }
    
    // MARK: - Shift
    
    private func setShift(_ state: ShiftState) {
        shiftState = state
        switch state {
        case .off:
            shiftButton?.setTitle("⇧", for: .normal)
            shiftButton?.backgroundColor = specialKeyBG
            shiftButton?.setTitleColor(keyText, for: .normal)
        case .on:
            shiftButton?.setTitle("⬆", for: .normal)
            shiftButton?.backgroundColor = accentColor.withAlphaComponent(0.7)
            shiftButton?.setTitleColor(.white, for: .normal)
        case .locked:
            shiftButton?.setTitle("⇪", for: .normal)
            shiftButton?.backgroundColor = accentColor
            shiftButton?.setTitleColor(.white, for: .normal)
        }
        // Update key labels
        for btn in keyButtons {
            guard let t = btn.currentTitle, t.count == 1 else { continue }
            switch state {
            case .on, .locked: btn.setTitle(t.uppercased(), for: .normal)
            case .off:         btn.setTitle(t.lowercased(), for: .normal)
            }
        }
    }
    
    // MARK: - Touch Animations
    
    @objc private func btnTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.08) {
            sender.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
            sender.alpha = 0.8
        }
    }
    
    @objc private func btnTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 5) {
            sender.transform = .identity
            sender.alpha = 1
        }
    }
}
