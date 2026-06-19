// SettingsViewController.swift
// Container App — Settings UI for GeminiBoard

import UIKit

final class SettingsViewController: UIViewController {
    
    // MARK: - UI
    private let scrollView     = UIScrollView()
    private let contentStack   = UIStackView()
    
    // API Key section
    private let apiKeyField    = UITextField()
    
    // Language pickers
    private var sourceLangPicker = UIPickerView()
    private var targetLangPicker = UIPickerView()
    private let sourceLangField  = UITextField()
    private let targetLangField  = UITextField()
    
    // Current selections
    private var selectedSourceIndex = 0
    private var selectedTargetIndex = 5   // English
    
    // MARK: - Colors
    let dark        = UIColor(red: 0.07, green: 0.07, blue: 0.12, alpha: 1)
    let cardBG      = UIColor(red: 0.12, green: 0.12, blue: 0.20, alpha: 1)
    let accentColor = UIColor(red: 0.45, green: 0.30, blue: 1.00, alpha: 1)
    let accentEnd   = UIColor(red: 0.20, green: 0.60, blue: 1.00, alpha: 1)
    let textColor   = UIColor(white: 0.90, alpha: 1)
    let subtextColor = UIColor(white: 0.55, alpha: 1)
    let borderColor = UIColor(white: 1.0, alpha: 0.08)
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "⌨️ GeminiBoard"
        view.backgroundColor = dark
        if #available(iOS 13.0, *) { overrideUserInterfaceStyle = .dark }
        
        setupScrollView()
        buildUI()
        loadSavedSettings()
    }
    
    // MARK: - Setup
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        contentStack.axis         = .vertical
        contentStack.spacing      = 20
        contentStack.alignment    = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -40),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }
    
    private func buildUI() {
        contentStack.addArrangedSubview(makeHeroCard())
        contentStack.addArrangedSubview(makeSectionCard(
            title: "🔑 Gemini API Key",
            subtitle: "Get your free key at aistudio.google.com",
            content: makeAPIKeyContent()
        ))
        contentStack.addArrangedSubview(makeSectionCard(
            title: "🌐 Source Language",
            subtitle: "Language you will type in",
            content: makeLanguageContent(field: sourceLangField, isSource: true)
        ))
        contentStack.addArrangedSubview(makeSectionCard(
            title: "🎯 Target Language",
            subtitle: "Language to translate into",
            content: makeLanguageContent(field: targetLangField, isSource: false)
        ))
        contentStack.addArrangedSubview(makeSaveButton())
        contentStack.addArrangedSubview(makeHowToCard())
        contentStack.addArrangedSubview(makeFooter())
    }
    
    // MARK: - Hero Card
    
    private func makeHeroCard() -> UIView {
        let card = makeCard()
        let stack = UIStackView()
        stack.axis      = .vertical
        stack.spacing   = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
        ])
        
        let emoji = UILabel()
        emoji.text = "✨"
        emoji.font = .systemFont(ofSize: 48)
        
        let title = UILabel()
        title.text      = "GeminiBoard"
        title.font      = .systemFont(ofSize: 26, weight: .bold)
        title.textColor = textColor
        
        let sub = UILabel()
        sub.text          = "AI-powered translator keyboard\npowered by Google Gemini"
        sub.font          = .systemFont(ofSize: 13, weight: .regular)
        sub.textColor     = subtextColor
        sub.textAlignment = .center
        sub.numberOfLines = 2
        
        // Gradient badge
        let badge = makeGradientBadge("gemini-2.5-flash ⚡")
        
        stack.addArrangedSubview(emoji)
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(sub)
        stack.setCustomSpacing(12, after: sub)
        stack.addArrangedSubview(badge)
        return card
    }
    
    // MARK: - API Key Content
    
    private func makeAPIKeyContent() -> UIView {
        let stack = UIStackView()
        stack.axis    = .vertical
        stack.spacing = 10
        
        apiKeyField.placeholder   = "AIzaSy…"
        apiKeyField.font          = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        apiKeyField.textColor     = textColor
        apiKeyField.tintColor     = accentColor
        apiKeyField.isSecureTextEntry = true
        apiKeyField.backgroundColor  = UIColor(white: 1, alpha: 0.05)
        apiKeyField.layer.cornerRadius = 10
        apiKeyField.layer.borderWidth  = 1
        apiKeyField.layer.borderColor  = borderColor.cgColor
        apiKeyField.autocorrectionType    = .no
        apiKeyField.autocapitalizationType = .none
        apiKeyField.returnKeyType         = .done
        apiKeyField.delegate              = self
        
        // Left padding
        let lp = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 40))
        apiKeyField.leftView     = lp
        apiKeyField.leftViewMode = .always
        
        // Right eye toggle
        let eyeBtn = UIButton(type: .system)
        eyeBtn.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        eyeBtn.tintColor = subtextColor
        eyeBtn.frame     = CGRect(x: 0, y: 0, width: 40, height: 40)
        eyeBtn.addTarget(self, action: #selector(toggleAPIKeyVisibility(_:)), for: .touchUpInside)
        apiKeyField.rightView     = eyeBtn
        apiKeyField.rightViewMode = .always
        apiKeyField.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        let hint = UILabel()
        hint.text      = "Your API key is stored securely on-device only."
        hint.font      = .systemFont(ofSize: 11)
        hint.textColor = subtextColor
        hint.numberOfLines = 2
        
        stack.addArrangedSubview(apiKeyField)
        stack.addArrangedSubview(hint)
        return stack
    }
    
    // MARK: - Language Content
    
    private func makeLanguageContent(field: UITextField, isSource: Bool) -> UIView {
        let picker = isSource ? sourceLangPicker : targetLangPicker
        picker.dataSource = self
        picker.delegate   = self
        picker.tag        = isSource ? 0 : 1
        
        field.font             = .systemFont(ofSize: 14, weight: .medium)
        field.textColor        = textColor
        field.tintColor        = .clear
        field.backgroundColor  = UIColor(white: 1, alpha: 0.05)
        field.layer.cornerRadius = 10
        field.layer.borderWidth  = 1
        field.layer.borderColor  = borderColor.cgColor
        field.textAlignment    = .center
        field.inputView        = picker
        field.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        // Toolbar for picker
        let bar = UIToolbar()
        bar.sizeToFit()
        bar.barStyle = .black
        let done = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissPicker))
        done.tintColor = accentColor
        bar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), done]
        field.inputAccessoryView = bar
        
        return field
    }
    
    // MARK: - Save Button
    
    private func makeSaveButton() -> UIView {
        let btn = UIButton(type: .system)
        btn.setTitle("💾  Save Settings", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 14
        btn.clipsToBounds      = true
        btn.heightAnchor.constraint(equalToConstant: 54).isActive = true
        btn.addTarget(self, action: #selector(saveSettings), for: .touchUpInside)
        
        // Gradient
        let gl = CAGradientLayer()
        gl.colors     = [accentColor.cgColor, accentEnd.cgColor]
        gl.startPoint = CGPoint(x: 0, y: 0.5)
        gl.endPoint   = CGPoint(x: 1, y: 0.5)
        gl.cornerRadius = 14
        
        btn.layoutIfNeeded()
        gl.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 40, height: 54)
        btn.layer.insertSublayer(gl, at: 0)
        return btn
    }
    
    // MARK: - How-To Card
    
    private func makeHowToCard() -> UIView {
        let steps = [
            ("1", "Open Settings → General → Keyboard"),
            ("2", "Tap Keyboards → Add New Keyboard"),
            ("3", "Find GeminiBoard and add it"),
            ("4", "Tap GeminiBoard → Allow Full Access ✓"),
            ("5", "Open any app, switch keyboard → type → ✨ Translate!")
        ]
        
        let card = makeCard()
        let outer = UIStackView()
        outer.axis    = .vertical
        outer.spacing = 14
        outer.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(outer)
        NSLayoutConstraint.activate([
            outer.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            outer.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            outer.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            outer.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
        ])
        
        let title = UILabel()
        title.text      = "📖 How to Enable"
        title.font      = .systemFont(ofSize: 15, weight: .bold)
        title.textColor = textColor
        outer.addArrangedSubview(title)
        
        for (num, text) in steps {
            let row = UIStackView()
            row.axis    = .horizontal
            row.spacing = 10
            row.alignment = .top
            
            let badge = UILabel()
            badge.text            = num
            badge.font            = .systemFont(ofSize: 11, weight: .bold)
            badge.textColor       = .white
            badge.textAlignment   = .center
            badge.backgroundColor = accentColor
            badge.layer.cornerRadius = 10
            badge.clipsToBounds   = true
            badge.widthAnchor.constraint(equalToConstant: 20).isActive = true
            badge.heightAnchor.constraint(equalToConstant: 20).isActive = true
            
            let label = UILabel()
            label.text          = text
            label.font          = .systemFont(ofSize: 13, weight: .regular)
            label.textColor     = subtextColor
            label.numberOfLines = 2
            
            row.addArrangedSubview(badge)
            row.addArrangedSubview(label)
            outer.addArrangedSubview(row)
        }
        return card
    }
    
    // MARK: - Footer
    
    private func makeFooter() -> UIView {
        let label = UILabel()
        label.text          = "GeminiBoard • Powered by Google Gemini API\nRequires Full Access for network translation"
        label.font          = .systemFont(ofSize: 11)
        label.textColor     = UIColor(white: 0.35, alpha: 1)
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }
    
    // MARK: - Helpers
    
    private func makeCard() -> UIView {
        let v = UIView()
        v.backgroundColor    = cardBG
        v.layer.cornerRadius = 16
        v.layer.borderWidth  = 0.5
        v.layer.borderColor  = borderColor.cgColor
        v.layer.shadowColor  = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.2
        v.layer.shadowRadius  = 8
        v.layer.shadowOffset  = CGSize(width: 0, height: 4)
        return v
    }
    
    private func makeSectionCard(title: String, subtitle: String, content: UIView) -> UIView {
        let card = makeCard()
        let outer = UIStackView()
        outer.axis    = .vertical
        outer.spacing = 12
        outer.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(outer)
        NSLayoutConstraint.activate([
            outer.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            outer.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            outer.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            outer.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
        ])
        
        let titleLabel = UILabel()
        titleLabel.text      = title
        titleLabel.font      = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = textColor
        
        let subLabel = UILabel()
        subLabel.text      = subtitle
        subLabel.font      = .systemFont(ofSize: 11)
        subLabel.textColor = subtextColor
        
        outer.addArrangedSubview(titleLabel)
        outer.addArrangedSubview(subLabel)
        outer.addArrangedSubview(content)
        return card
    }
    
    private func makeGradientBadge(_ text: String) -> UIView {
        let container = UIView()
        container.layer.cornerRadius = 10
        container.clipsToBounds = true
        
        let gl = CAGradientLayer()
        gl.colors     = [accentColor.withAlphaComponent(0.3).cgColor, accentEnd.withAlphaComponent(0.3).cgColor]
        gl.startPoint = CGPoint(x: 0, y: 0.5)
        gl.endPoint   = CGPoint(x: 1, y: 0.5)
        container.layer.insertSublayer(gl, at: 0)
        
        let label = UILabel()
        label.text          = text
        label.font          = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor     = UIColor(red: 0.7, green: 0.6, blue: 1.0, alpha: 1)
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 5),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -5),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12)
        ])
        
        container.layoutIfNeeded()
        gl.frame = container.bounds
        
        return container
    }
    
    // MARK: - Load / Save Settings
    
    private func loadSavedSettings() {
        let defaults = SharedConstants.sharedDefaults
        
        if let key = defaults?.string(forKey: SharedConstants.apiKeyUserDefaultsKey) {
            apiKeyField.text = key
        }
        
        let savedSource = defaults?.string(forKey: SharedConstants.sourceLanguageKey) ?? SharedConstants.defaultSourceLanguage
        let savedTarget = defaults?.string(forKey: SharedConstants.targetLanguageKey) ?? SharedConstants.defaultTargetLanguage
        
        selectedSourceIndex = SharedConstants.languages.firstIndex(of: savedSource) ?? 0
        selectedTargetIndex = SharedConstants.languages.firstIndex(of: savedTarget) ?? 5
        
        sourceLangPicker.selectRow(selectedSourceIndex, inComponent: 0, animated: false)
        targetLangPicker.selectRow(selectedTargetIndex, inComponent: 0, animated: false)
        
        sourceLangField.text = SharedConstants.languages[selectedSourceIndex]
        targetLangField.text = SharedConstants.languages[selectedTargetIndex]
    }
    
    @objc private func saveSettings() {
        view.endEditing(true)
        
        let key = apiKeyField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !key.isEmpty else {
            showAlert(title: "Missing API Key", message: "Please enter your Gemini API key.")
            return
        }
        
        let defaults = SharedConstants.sharedDefaults
        defaults?.set(key, forKey: SharedConstants.apiKeyUserDefaultsKey)
        defaults?.set(SharedConstants.languages[selectedSourceIndex], forKey: SharedConstants.sourceLanguageKey)
        defaults?.set(SharedConstants.languages[selectedTargetIndex], forKey: SharedConstants.targetLanguageKey)
        defaults?.synchronize()
        
        // Success feedback
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        
        let btn = contentStack.arrangedSubviews.compactMap { $0 as? UIButton }.first
        UIView.animate(withDuration: 0.15, animations: {
            btn?.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.15) { btn?.transform = .identity }
        }
        showAlert(title: "✅ Saved!", message: "Settings saved. Your keyboard is ready to use.")
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        if #available(iOS 13, *) { alert.overrideUserInterfaceStyle = .dark }
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    
    @objc private func toggleAPIKeyVisibility(_ sender: UIButton) {
        apiKeyField.isSecureTextEntry.toggle()
        let imgName = apiKeyField.isSecureTextEntry ? "eye.slash" : "eye"
        sender.setImage(UIImage(systemName: imgName), for: .normal)
    }
    
    @objc private func dismissPicker() {
        view.endEditing(true)
    }
}

// MARK: - UIPickerViewDataSource / Delegate

extension SettingsViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        // Source picker: include Auto-Detect; target: exclude Auto-Detect
        if pickerView.tag == 0 {
            return SharedConstants.languages.count
        } else {
            return SharedConstants.languages.filter { $0 != "Auto-Detect" }.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 0 {
            return SharedConstants.languages[row]
        } else {
            return SharedConstants.languages.filter { $0 != "Auto-Detect" }[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let langs = pickerView.tag == 0 ? SharedConstants.languages : SharedConstants.languages.filter { $0 != "Auto-Detect" }
        return NSAttributedString(string: langs[row], attributes: [.foregroundColor: textColor])
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 0 {
            selectedSourceIndex = row
            sourceLangField.text = SharedConstants.languages[row]
        } else {
            selectedTargetIndex = row
            let filtered = SharedConstants.languages.filter { $0 != "Auto-Detect" }
            targetLangField.text = filtered[row]
        }
    }
}

// MARK: - UITextFieldDelegate

extension SettingsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
