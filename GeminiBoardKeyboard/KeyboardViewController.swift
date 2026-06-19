// KeyboardViewController.swift
// Main entry point for the keyboard extension

import UIKit

final class KeyboardViewController: UIInputViewController {
    
    // MARK: - Properties
    private let toolbar    = TranslateToolbar()
    private let keyboard   = KeyboardView()
    
    private var sourceLang = SharedConstants.defaultSourceLanguage
    private var targetLang = SharedConstants.defaultTargetLanguage
    
    // Buffer of text typed in THIS keyboard session
    // (textDocumentProxy.documentContextBeforeInput shows all text, not just what we typed)
    private var sessionText: String = "" {
        didSet { keyboard.inputText = sessionText }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        loadSettings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSettings()
        sessionText = ""
        toolbar.setState(.idle)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        view.backgroundColor = keyboard.darkBG
        
        // Delegates
        toolbar.delegate  = self
        keyboard.delegate = self
        
        // Layout: toolbar on top, keyboard fills rest
        toolbar.translatesAutoresizingMaskIntoConstraints  = false
        keyboard.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(toolbar)
        view.addSubview(keyboard)
        
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: view.topAnchor),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 72),
            
            keyboard.topAnchor.constraint(equalTo: toolbar.bottomAnchor),
            keyboard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboard.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboard.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadSettings() {
        let defaults = SharedConstants.sharedDefaults
        sourceLang = defaults?.string(forKey: SharedConstants.sourceLanguageKey) ?? SharedConstants.defaultSourceLanguage
        targetLang = defaults?.string(forKey: SharedConstants.targetLanguageKey) ?? SharedConstants.defaultTargetLanguage
        toolbar.configure(sourceLang: sourceLang, targetLang: targetLang)
    }
    
    // MARK: - Full Access Check
    
    private func checkFullAccess() -> Bool {
        return hasFullAccess
    }
    
    // MARK: - Translate
    
    private func performTranslation() {
        // Check full access for network
        guard checkFullAccess() else {
            toolbar.setState(.error("Enable 'Allow Full Access' in Settings → General → Keyboard → GeminiBoard"))
            return
        }
        
        // Use session text, or fall back to text before cursor
        var textToTranslate = sessionText
        if textToTranslate.isEmpty {
            textToTranslate = textDocumentProxy.documentContextBeforeInput ?? ""
        }
        textToTranslate = textToTranslate.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !textToTranslate.isEmpty else {
            toolbar.setState(.error("Type something first!"))
            return
        }
        
        toolbar.setState(.translating)
        
        GeminiService.shared.translate(
            text: textToTranslate,
            from: sourceLang,
            to: targetLang
        ) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let translated):
                self.toolbar.setState(.done(translated))
            case .failure(let error):
                self.toolbar.setState(.error(error.localizedDescription))
            }
        }
    }
    
    // MARK: - Insert Translation
    
    private func insertTranslation(_ text: String) {
        // Delete what was typed in this session
        if !sessionText.isEmpty {
            for _ in sessionText {
                textDocumentProxy.deleteBackward()
            }
        }
        // Insert translation
        textDocumentProxy.insertText(text)
        sessionText = text
        
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
    }
    
    // MARK: - Clear Session
    
    private func clearSession() {
        GeminiService.shared.cancelCurrentTask()
        sessionText = ""
        toolbar.setState(.idle)
    }
    
    // MARK: - Swap Languages
    
    private func swapLanguages() {
        // Cannot swap if source is Auto-Detect
        guard sourceLang != "Auto-Detect" else { return }
        swap(&sourceLang, &targetLang)
        let defaults = SharedConstants.sharedDefaults
        defaults?.set(sourceLang, forKey: SharedConstants.sourceLanguageKey)
        defaults?.set(targetLang, forKey: SharedConstants.targetLanguageKey)
        toolbar.configure(sourceLang: sourceLang, targetLang: targetLang)
    }
}

// MARK: - TranslateToolbarDelegate

extension KeyboardViewController: TranslateToolbarDelegate {
    
    func toolbarDidTapTranslate(_ toolbar: TranslateToolbar) {
        performTranslation()
    }
    
    func toolbarDidTapInsert(_ toolbar: TranslateToolbar, text: String) {
        insertTranslation(text)
    }
    
    func toolbarDidTapClear(_ toolbar: TranslateToolbar) {
        clearSession()
    }
    
    func toolbarDidTapSwapLanguages(_ toolbar: TranslateToolbar) {
        swapLanguages()
    }
}

// MARK: - KeyboardViewDelegate

extension KeyboardViewController: KeyboardViewDelegate {
    
    func keyboardView(_ view: KeyboardView, didTapKey key: String) {
        textDocumentProxy.insertText(key)
        sessionText.append(contentsOf: key)
        // Reset translation state since text changed
        if toolbar.translationResult != nil {
            toolbar.setState(.idle)
        }
    }
    
    func keyboardViewDidTapDelete(_ view: KeyboardView) {
        textDocumentProxy.deleteBackward()
        if !sessionText.isEmpty {
            sessionText.removeLast()
        }
    }
    
    func keyboardViewDidTapReturn(_ view: KeyboardView) {
        textDocumentProxy.insertText("\n")
        sessionText.append("\n")
    }
    
    func keyboardViewDidTapSpace(_ view: KeyboardView) {
        textDocumentProxy.insertText(" ")
        sessionText.append(" ")
    }
    
    func keyboardViewDidTapNextKeyboard(_ view: KeyboardView) {
        advanceToNextInputMode()
    }
}
