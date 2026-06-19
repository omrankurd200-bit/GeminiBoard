// TranslateToolbar.swift
// Top toolbar shown above the keyboard with translation controls

import UIKit

// MARK: - Delegate
protocol TranslateToolbarDelegate: AnyObject {
    func toolbarDidTapTranslate(_ toolbar: TranslateToolbar)
    func toolbarDidTapInsert(_ toolbar: TranslateToolbar, text: String)
    func toolbarDidTapClear(_ toolbar: TranslateToolbar)
    func toolbarDidTapSwapLanguages(_ toolbar: TranslateToolbar)
}

// MARK: - TranslateToolbar

final class TranslateToolbar: UIView {
    
    weak var delegate: TranslateToolbarDelegate?
    
    // MARK: - State
    enum State {
        case idle
        case translating
        case done(String)
        case error(String)
    }
    
    private(set) var translationResult: String?
    
    // MARK: - UI Elements
    
    private let containerStack  = UIStackView()
    private let topRow          = UIStackView()
    private let bottomRow       = UIStackView()
    
    // Top row
    private let sourceLangLabel = UILabel()
    private let arrowLabel      = UILabel()
    private let targetLangLabel = UILabel()
    private let swapButton      = UIButton(type: .system)
    private let translateButton = UIButton(type: .system)
    
    // Bottom row
    private let statusLabel     = UILabel()
    private let insertButton    = UIButton(type: .system)
    private let clearButton     = UIButton(type: .system)
    
    // MARK: - Colors / Gradient
    private let accentStart  = UIColor(red: 0.45, green: 0.30, blue: 1.00, alpha: 1)
    private let accentEnd    = UIColor(red: 0.20, green: 0.60, blue: 1.00, alpha: 1)
    private let surfaceColor = UIColor(white: 0.10, alpha: 0.95)
    private let borderColor  = UIColor(white: 1.0, alpha: 0.08)
    
    private var gradientLayer: CAGradientLayer?
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = translateButton.bounds
    }
    
    // MARK: - Public
    
    func configure(sourceLang: String, targetLang: String) {
        sourceLangLabel.text = (sourceLang == "Auto-Detect") ? "🌐 Auto" : "🌐 \(sourceLang)"
        targetLangLabel.text = "🎯 \(targetLang)"
    }
    
    func setState(_ state: State) {
        switch state {
        case .idle:
            statusLabel.text  = "Type text, then tap Translate ✨"
            statusLabel.textColor = UIColor(white: 0.6, alpha: 1)
            insertButton.isEnabled  = false
            insertButton.alpha      = 0.4
            clearButton.isEnabled   = false
            clearButton.alpha       = 0.4
            translateButton.isEnabled = true
            setTranslateButtonLoading(false)
            translationResult = nil
            
        case .translating:
            statusLabel.text  = "⏳ Translating with Gemini…"
            statusLabel.textColor = UIColor(red: 0.6, green: 0.8, blue: 1, alpha: 1)
            insertButton.isEnabled  = false
            insertButton.alpha      = 0.4
            clearButton.isEnabled   = true
            clearButton.alpha       = 1.0
            translateButton.isEnabled = false
            setTranslateButtonLoading(true)
            
        case .done(let result):
            translationResult = result
            let preview = result.count > 50 ? String(result.prefix(50)) + "…" : result
            statusLabel.text  = "✅ \(preview)"
            statusLabel.textColor = UIColor(red: 0.4, green: 1.0, blue: 0.6, alpha: 1)
            insertButton.isEnabled  = true
            insertButton.alpha      = 1.0
            clearButton.isEnabled   = true
            clearButton.alpha       = 1.0
            translateButton.isEnabled = true
            setTranslateButtonLoading(false)
            
        case .error(let message):
            statusLabel.text  = "❌ \(message)"
            statusLabel.textColor = UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1)
            insertButton.isEnabled  = false
            insertButton.alpha      = 0.4
            clearButton.isEnabled   = true
            clearButton.alpha       = 1.0
            translateButton.isEnabled = true
            setTranslateButtonLoading(false)
            translationResult = nil
        }
    }
    
    // MARK: - Setup
    
    private func setup() {
        backgroundColor = surfaceColor
        layer.borderWidth  = 0.5
        layer.borderColor  = borderColor.cgColor
        
        setupTopRow()
        setupBottomRow()
        setupContainerStack()
        setupShadow()
    }
    
    private func setupContainerStack() {
        containerStack.axis         = .vertical
        containerStack.spacing      = 6
        containerStack.distribution = .fill
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        
        containerStack.addArrangedSubview(topRow)
        containerStack.addArrangedSubview(bottomRow)
        addSubview(containerStack)
        
        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            containerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            containerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            containerStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    private func setupTopRow() {
        topRow.axis         = .horizontal
        topRow.spacing      = 6
        topRow.alignment    = .center
        topRow.distribution = .fill
        
        // Source lang label
        sourceLangLabel.text      = "🌐 Auto"
        sourceLangLabel.font      = .systemFont(ofSize: 12, weight: .medium)
        sourceLangLabel.textColor = UIColor(white: 0.85, alpha: 1)
        sourceLangLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        // Arrow
        arrowLabel.text      = "→"
        arrowLabel.font      = .systemFont(ofSize: 12, weight: .bold)
        arrowLabel.textColor = accentStart
        arrowLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        // Target lang label
        targetLangLabel.text      = "🎯 English"
        targetLangLabel.font      = .systemFont(ofSize: 12, weight: .medium)
        targetLangLabel.textColor = UIColor(white: 0.85, alpha: 1)
        targetLangLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        // Swap button
        swapButton.setTitle("⇄", for: .normal)
        swapButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        swapButton.tintColor = UIColor(white: 0.7, alpha: 1)
        swapButton.addTarget(self, action: #selector(swapTapped), for: .touchUpInside)
        swapButton.setContentHuggingPriority(.required, for: .horizontal)
        
        // Spacer
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        // Translate button
        setupTranslateButton()
        
        topRow.addArrangedSubview(sourceLangLabel)
        topRow.addArrangedSubview(arrowLabel)
        topRow.addArrangedSubview(targetLangLabel)
        topRow.addArrangedSubview(swapButton)
        topRow.addArrangedSubview(spacer)
        topRow.addArrangedSubview(translateButton)
    }
    
    private func setupTranslateButton() {
        translateButton.setTitle("✨ Translate", for: .normal)
        translateButton.titleLabel?.font  = .systemFont(ofSize: 12, weight: .bold)
        translateButton.tintColor         = .white
        translateButton.setTitleColor(.white, for: .normal)
        translateButton.setTitleColor(UIColor(white: 1, alpha: 0.5), for: .disabled)
        translateButton.layer.cornerRadius = 10
        translateButton.clipsToBounds      = true
        // Use layer padding instead of deprecated contentEdgeInsets
        translateButton.titleEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        translateButton.imageEdgeInsets = .zero
        
        // Gradient background
        let gl = CAGradientLayer()
        gl.colors     = [accentStart.cgColor, accentEnd.cgColor]
        gl.startPoint = CGPoint(x: 0, y: 0.5)
        gl.endPoint   = CGPoint(x: 1, y: 0.5)
        gl.cornerRadius = 10
        translateButton.layer.insertSublayer(gl, at: 0)
        gradientLayer = gl
        
        translateButton.addTarget(self, action: #selector(translateTapped), for: .touchUpInside)
        translateButton.setContentHuggingPriority(.required, for: .horizontal)
        
        // Size the gradient properly after layout
        translateButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            translateButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupBottomRow() {
        bottomRow.axis         = .horizontal
        bottomRow.spacing      = 8
        bottomRow.alignment    = .center
        bottomRow.distribution = .fill
        
        // Status label
        statusLabel.text          = "Type text, then tap Translate ✨"
        statusLabel.font          = .systemFont(ofSize: 11, weight: .regular)
        statusLabel.textColor     = UIColor(white: 0.6, alpha: 1)
        statusLabel.numberOfLines = 1
        statusLabel.lineBreakMode = .byTruncatingTail
        statusLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        // Clear button
        clearButton.setTitle("✕", for: .normal)
        clearButton.titleLabel?.font  = .systemFont(ofSize: 11, weight: .medium)
        clearButton.setTitleColor(UIColor(white: 0.5, alpha: 1), for: .normal)
        clearButton.setTitleColor(UIColor(white: 0.3, alpha: 1), for: .disabled)
        clearButton.isEnabled    = false
        clearButton.alpha        = 0.4
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        clearButton.setContentHuggingPriority(.required, for: .horizontal)
        
        // Insert button
        insertButton.setTitle("↩ Insert", for: .normal)
        insertButton.titleLabel?.font  = .systemFont(ofSize: 11, weight: .semibold)
        insertButton.setTitleColor(UIColor(red: 0.4, green: 1.0, blue: 0.6, alpha: 1), for: .normal)
        insertButton.setTitleColor(UIColor(white: 0.3, alpha: 1), for: .disabled)
        insertButton.layer.cornerRadius = 8
        insertButton.layer.borderWidth  = 1
        insertButton.layer.borderColor  = UIColor(red: 0.4, green: 1.0, blue: 0.6, alpha: 0.5).cgColor
        // Use layer padding instead of deprecated contentEdgeInsets
        insertButton.titleEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        insertButton.imageEdgeInsets = .zero
        insertButton.isEnabled    = false
        insertButton.alpha        = 0.4
        insertButton.addTarget(self, action: #selector(insertTapped), for: .touchUpInside)
        insertButton.setContentHuggingPriority(.required, for: .horizontal)
        
        bottomRow.addArrangedSubview(statusLabel)
        bottomRow.addArrangedSubview(clearButton)
        bottomRow.addArrangedSubview(insertButton)
    }
    
    private func setupShadow() {
        layer.shadowColor   = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset  = CGSize(width: 0, height: 2)
        layer.shadowRadius  = 4
    }
    
    private func setTranslateButtonLoading(_ loading: Bool) {
        if loading {
            translateButton.setTitle("⏳ …", for: .normal)
        } else {
            translateButton.setTitle("✨ Translate", for: .normal)
        }
    }
    
    // MARK: - Actions
    
    @objc private func translateTapped() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        UIView.animate(withDuration: 0.1, animations: {
            self.translateButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.translateButton.transform = .identity
            }
        }
        delegate?.toolbarDidTapTranslate(self)
    }
    
    @objc private func insertTapped() {
        guard let result = translationResult else { return }
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        delegate?.toolbarDidTapInsert(self, text: result)
    }
    
    @objc private func clearTapped() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        delegate?.toolbarDidTapClear(self)
    }
    
    @objc private func swapTapped() {
        let impact = UISelectionFeedbackGenerator()
        impact.selectionChanged()
        delegate?.toolbarDidTapSwapLanguages(self)
    }
}
