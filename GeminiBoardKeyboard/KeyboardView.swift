// KeyboardView.swift
// Full programmatic QWERTY & Arabic keyboard view with native iOS design

import UIKit

// MARK: - Delegate
protocol KeyboardViewDelegate: AnyObject {
    func keyboardView(_ view: KeyboardView, didTapKey key: String)
    func keyboardViewDidTapDelete(_ view: KeyboardView)
    func keyboardViewDidTapReturn(_ view: KeyboardView)
    func keyboardViewDidTapSpace(_ view: KeyboardView)
    func keyboardViewDidTapNextKeyboard(_ view: KeyboardView)
}

// MARK: - KeyboardView

final class KeyboardView: UIView {
    
    weak var delegate: KeyboardViewDelegate?
    
    // MARK: - State
    enum ShiftState { case off, on, locked }
    private(set) var shiftState: ShiftState = .off
    private(set) var isShowingNumbers = false
    private var isShowingSymbols = false
    
    enum KeyboardLanguage { case english, arabic }
    private(set) var currentLanguage: KeyboardLanguage = .english
    
    // Kept for compatibility with controller
    var inputText: String = ""
    
    // MARK: - Layout Rows
    private let qwertyRows: [[String]] = [
        ["q","w","e","r","t","y","u","i","o","p"],
        ["a","s","d","f","g","h","j","k","l"],
        ["z","x","c","v","b","n","m"]
    ]
    private let arabicRows: [[String]] = [
        ["ض","ص","ث","ق","ف","غ","ع","ه","خ","ح","ج","د"],
        ["ش","س","ي","ب","ل","ا","ت","ن","م","ك","ط"],
        ["ئ","ء","ؤ","ر","لا","ى","ة","و","ز","ظ"]
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
    private var keyButtons: [UIButton] = []
    private var shiftButton: UIButton?
    private var numbersButton: UIButton?
    private var symbolsButton: UIButton?
    private var deleteButton: UIButton?
    
    // MARK: - Native iOS Keyboard Colors (Dark Mode)
    let darkBG        = UIColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1.0)
    let keyBG         = UIColor(red: 0.24, green: 0.24, blue: 0.25, alpha: 1.0)
    let specialKeyBG  = UIColor(red: 0.16, green: 0.16, blue: 0.17, alpha: 1.0)
    let keyText       = UIColor.white
    let accentColor   = UIColor(red: 0.20, green: 0.50, blue: 1.00, alpha: 1.0) // Native iOS blue Return key
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Setup
    
    private func setup() {
        backgroundColor = darkBG
        setupMainStack()
        buildQwertyLayout()
    }
    
    private func setupMainStack() {
        mainStack.axis         = .vertical
        mainStack.spacing      = 8
        mainStack.distribution = .fillEqually
        mainStack.alignment    = .fill
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
    }
    
    // MARK: - Build Layouts
    
    private func buildQwertyLayout() {
        mainStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        keyButtons.removeAll()
        let rows = isShowingNumbers ? (isShowingSymbols ? symbolRows : numberRows) : (currentLanguage == .arabic ? arabicRows : qwertyRows)
        
        for (i, row) in rows.enumerated() {
            let rowStack = UIStackView()
            rowStack.axis         = .horizontal
            rowStack.spacing      = 6
            rowStack.alignment    = .fill
            
            if i == 0 {
                // Row 1: QWERTY (10 keys) or Arabic (12 keys). Fills equally.
                rowStack.distribution = .fillEqually
                for char in row {
                    let btn = makeKeyButton(title: char)
                    btn.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
                    rowStack.addArrangedSubview(btn)
                    keyButtons.append(btn)
                }
            } else if i == 1 {
                // Row 2: English (9 keys) or Arabic (11 keys).
                rowStack.distribution = .fillEqually
                if !isShowingNumbers {
                    rowStack.isLayoutMarginsRelativeArrangement = true
                    if currentLanguage == .english {
                        rowStack.layoutMargins = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)
                    } else {
                        rowStack.layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
                    }
                }
                for char in row {
                    let btn = makeKeyButton(title: char)
                    btn.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
                    rowStack.addArrangedSubview(btn)
                    keyButtons.append(btn)
                }
            } else if i == 2 {
                // Row 3: Special keys at sides, nested stack in middle for letters
                rowStack.distribution = .fill
                
                let specialWidth: CGFloat = (currentLanguage == .arabic && !isShowingNumbers) ? 36 : 44
                
                // 1. Left Special Button
                let leftSpecialBtn: UIButton
                if !isShowingNumbers {
                    if currentLanguage == .english {
                        let shiftBtn = makeSpecialButton(title: "⇧", width: specialWidth)
                        shiftBtn.addTarget(self, action: #selector(shiftTapped(_:)), for: .touchUpInside)
                        self.shiftButton = shiftBtn
                        leftSpecialBtn = shiftBtn
                    } else {
                        // Arabic layout left key: types Arabic comma "،"
                        let commaBtn = makeSpecialButton(title: "،", width: specialWidth)
                        commaBtn.addTarget(self, action: #selector(arabicCommaTapped), for: .touchUpInside)
                        leftSpecialBtn = commaBtn
                    }
                } else {
                    let symBtn = makeSpecialButton(title: isShowingSymbols ? "ABC" : "#+=", width: specialWidth)
                    symBtn.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
                    symBtn.addTarget(self, action: #selector(symbolsTapped(_:)), for: .touchUpInside)
                    self.symbolsButton = symBtn
                    leftSpecialBtn = symBtn
                }
                rowStack.addArrangedSubview(leftSpecialBtn)
                
                // 2. Nested Middle Stack (distributed equally)
                let middleStack = UIStackView()
                middleStack.axis         = .horizontal
                middleStack.spacing      = 6
                middleStack.distribution = .fillEqually
                middleStack.alignment    = .fill
                for char in row {
                    let btn = makeKeyButton(title: char)
                    btn.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
                    middleStack.addArrangedSubview(btn)
                    keyButtons.append(btn)
                }
                rowStack.addArrangedSubview(middleStack)
                
                // 3. Right Special Button (Delete)
                let delBtn = makeSpecialButton(title: "⌫", width: specialWidth)
                delBtn.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
                let lp = UILongPressGestureRecognizer(target: self, action: #selector(deleteLongPress(_:)))
                lp.minimumPressDuration = 0.4
                delBtn.addGestureRecognizer(lp)
                self.deleteButton = delBtn
                rowStack.addArrangedSubview(delBtn)
            }
            
            mainStack.addArrangedSubview(rowStack)
        }
        
        // Add Bottom Row
        mainStack.addArrangedSubview(makeBottomRow())
    }
    
    private func makeBottomRow() -> UIStackView {
        let row = UIStackView()
        row.axis         = .horizontal
        row.spacing      = 6
        row.distribution = .fill
        row.alignment    = .fill
        
        // Globe (next keyboard)
        let globeBtn = makeSpecialButton(title: "🌐", width: 40)
        globeBtn.addTarget(self, action: #selector(globeTapped), for: .touchUpInside)
        
        // Numbers toggle
        let numBtn = makeSpecialButton(title: isShowingNumbers ? "ABC" : "123", width: 40)
        numBtn.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        numBtn.addTarget(self, action: #selector(numbersTapped(_:)), for: .touchUpInside)
        self.numbersButton = numBtn
        
        // Language switcher (EN/AR layout toggle)
        let langBtn = makeSpecialButton(title: currentLanguage == .english ? "عربي" : "EN", width: 40)
        langBtn.titleLabel?.font = .systemFont(ofSize: 12, weight: .bold)
        langBtn.setTitleColor(UIColor(red: 0.7, green: 0.6, blue: 1.0, alpha: 1), for: .normal)
        langBtn.addTarget(self, action: #selector(toggleLanguage), for: .touchUpInside)
        
        // Space bar (fills remaining space)
        let spaceBtn = UIButton(type: .system)
        spaceBtn.setTitle(currentLanguage == .english ? "space" : "مسافة", for: .normal)
        spaceBtn.titleLabel?.font  = .systemFont(ofSize: 15, weight: .regular)
        spaceBtn.setTitleColor(keyText, for: .normal)
        spaceBtn.backgroundColor   = keyBG
        spaceBtn.layer.cornerRadius = 5
        spaceBtn.layer.shadowColor  = UIColor.black.cgColor
        spaceBtn.layer.shadowOpacity = 0.25
        spaceBtn.layer.shadowOffset  = CGSize(width: 0, height: 1.5)
        spaceBtn.layer.shadowRadius  = 1
        addTouchAnimation(to: spaceBtn)
        spaceBtn.addTarget(self, action: #selector(spaceTapped), for: .touchUpInside)
        
        // Return key (blue action button style)
        let returnBtn = makeSpecialButton(title: currentLanguage == .english ? "return" : "إدخال", width: 76)
        returnBtn.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        returnBtn.backgroundColor  = accentColor
        returnBtn.setTitleColor(.white, for: .normal)
        returnBtn.addTarget(self, action: #selector(returnTapped), for: .touchUpInside)
        
        row.addArrangedSubview(globeBtn)
        row.addArrangedSubview(numBtn)
        row.addArrangedSubview(langBtn)
        row.addArrangedSubview(spaceBtn)
        row.addArrangedSubview(returnBtn)
        return row
    }
    
    // MARK: - Factory Helpers
    
    private func makeKeyButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font  = .systemFont(ofSize: 22, weight: .regular)
        btn.setTitleColor(keyText, for: .normal)
        btn.backgroundColor   = keyBG
        btn.layer.cornerRadius = 5
        btn.layer.shadowColor  = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.25
        btn.layer.shadowOffset  = CGSize(width: 0, height: 1.5)
        btn.layer.shadowRadius  = 1
        addTouchAnimation(to: btn)
        return btn
    }
    
    private func makeSpecialButton(title: String, width: CGFloat) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font  = .systemFont(ofSize: 16, weight: .regular)
        btn.setTitleColor(keyText, for: .normal)
        btn.backgroundColor   = specialKeyBG
        btn.layer.cornerRadius = 5
        btn.layer.shadowColor  = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.25
        btn.layer.shadowOffset  = CGSize(width: 0, height: 1.5)
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
    
    @objc private func arabicCommaTapped() {
        UIDevice.current.playInputClick()
        delegate?.keyboardView(self, didTapKey: "،")
    }
    
    @objc private func toggleLanguage() {
        currentLanguage = (currentLanguage == .english) ? .arabic : .english
        isShowingNumbers = false
        isShowingSymbols = false
        buildQwertyLayout()
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
            sender.transform = CGAffineTransform(scaleX: 0.90, y: 0.90)
            sender.alpha = 0.85
        }
    }
    
    @objc private func btnTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.12, delay: 0, options: .curveEaseOut, animations: {
            sender.transform = .identity
            sender.alpha = 1.0
        })
    }
    
    // MARK: - Public Helper
    
    func setKeyboardLanguage(_ lang: KeyboardLanguage) {
        currentLanguage = lang
        isShowingNumbers = false
        isShowingSymbols = false
        buildQwertyLayout()
    }
}
