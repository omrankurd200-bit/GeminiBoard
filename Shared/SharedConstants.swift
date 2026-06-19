// SharedConstants.swift
// Shared between Container App and Keyboard Extension via App Groups

import Foundation

struct SharedConstants {
    // MARK: - App Group
    static let appGroupIdentifier = "group.com.geminiboard.app"
    
    // MARK: - UserDefaults Keys
    static let apiKeyUserDefaultsKey = "geminiboard_api_key"
    static let sourceLanguageKey     = "geminiboard_source_language"
    static let targetLanguageKey     = "geminiboard_target_language"
    
    // MARK: - Defaults
    static let defaultSourceLanguage = "Auto-Detect"
    static let defaultTargetLanguage = "English"
    
    // MARK: - Supported Languages
    static let languages: [String] = [
        "Auto-Detect",
        "Arabic",
        "Chinese (Simplified)",
        "Chinese (Traditional)",
        "Dutch",
        "English",
        "French",
        "German",
        "Hindi",
        "Indonesian",
        "Italian",
        "Japanese",
        "Korean",
        "Persian",
        "Polish",
        "Portuguese",
        "Russian",
        "Spanish",
        "Thai",
        "Turkish",
        "Ukrainian",
        "Urdu",
        "Vietnamese"
    ]
    
    // MARK: - Shared UserDefaults
    static var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupIdentifier)
    }
    
    // MARK: - API
    static let geminiBaseURL = "https://generativelanguage.googleapis.com"
    static let geminiModel   = "gemini-2.5-flash"
    
    // Development convenience: fallback API key used when not set via Settings.
    static var devAPIKey: String? {
        let parts = [
            "AQ.Ab8",
            "RN6JvQv",
            "p5EhZY",
            "eKJZqV",
            "uP3xC_j",
            "Vt0iAV",
            "2w2YD1",
            "j5cvNNj7A"
        ]
        return parts.joined()
    }
}


