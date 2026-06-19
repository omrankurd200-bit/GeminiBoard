// GeminiService.swift
// Handles translation via Google Gemini REST API

import Foundation

enum GeminiError: LocalizedError {
    case missingAPIKey
    case networkError(Error)
    case invalidResponse
    case emptyTranslation
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "No API key found. Please set your Gemini API key in the GeminiBoard app."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from Gemini API."
        case .emptyTranslation:
            return "Received empty translation."
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}

// MARK: - Gemini API Response Models

private struct GeminiRequest: Codable {
    let contents: [Content]
    let generationConfig: GenerationConfig
    
    struct Content: Codable {
        let parts: [Part]
    }
    struct Part: Codable {
        let text: String
    }
    struct GenerationConfig: Codable {
        let temperature: Double
        let maxOutputTokens: Int
    }
}

private struct GeminiResponse: Codable {
    let candidates: [Candidate]?
    let error: GeminiAPIError?
    
    struct Candidate: Codable {
        let content: Content
        struct Content: Codable {
            let parts: [Part]
            struct Part: Codable {
                let text: String
            }
        }
    }
    struct GeminiAPIError: Codable {
        let message: String
    }
}

// MARK: - GeminiService

final class GeminiService {
    
    static let shared = GeminiService()
    private let session: URLSession
    private var currentTask: URLSessionDataTask?
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
    }
    
    // MARK: - Public API
    
    /// Translates `text` from `sourceLang` to `targetLang` using Gemini API.
    func translate(
        text: String,
        from sourceLang: String,
        to targetLang: String,
        completion: @escaping (Result<String, GeminiError>) -> Void
    ) {
        // Prefer saved key from shared defaults; if missing, fall back to a DEBUG-only dev key.
        let savedKey = SharedConstants.sharedDefaults?.string(forKey: SharedConstants.apiKeyUserDefaultsKey)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let apiKey: String = {
            if let key = savedKey, !key.isEmpty { return key }
            if let dev = SharedConstants.devAPIKey?.trimmingCharacters(in: .whitespacesAndNewlines), !dev.isEmpty { return dev }
            return ""
        }()
        guard !apiKey.isEmpty else {
            completion(.failure(.missingAPIKey))
            return
        }
        
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            completion(.failure(.emptyTranslation))
            return
        }
        
        currentTask?.cancel()
        
        let prompt = buildPrompt(text: trimmedText, source: sourceLang, target: targetLang)
        
        guard let request = buildRequest(apiKey: apiKey, prompt: prompt) else {
            completion(.failure(.invalidResponse))
            return
        }
        
        currentTask = session.dataTask(with: request) { [weak self] data, response, error in
            guard self != nil else { return }
            
            if let error = error as? URLError, error.code == .cancelled {
                return
            }
            if let error = error {
                DispatchQueue.main.async { completion(.failure(.networkError(error))) }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(.invalidResponse)) }
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
                
                if let apiError = decoded.error {
                    DispatchQueue.main.async { completion(.failure(.apiError(apiError.message))) }
                    return
                }
                
                guard let text = decoded.candidates?.first?.content.parts.first?.text else {
                    DispatchQueue.main.async { completion(.failure(.emptyTranslation)) }
                    return
                }
                
                let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
                DispatchQueue.main.async { completion(.success(cleaned)) }
                
            } catch {
                DispatchQueue.main.async { completion(.failure(.invalidResponse)) }
            }
        }
        currentTask?.resume()
    }
    
    func cancelCurrentTask() {
        currentTask?.cancel()
        currentTask = nil
    }
    
    // MARK: - Private Helpers
    
    private func buildPrompt(text: String, source: String, target: String) -> String {
        let sourceDesc = (source == "Auto-Detect") ? "any language" : source
        return """
        Translate the following \(sourceDesc) text into \(target). \
        Return ONLY the translated text with no explanations, notes, or quotes. \
        Preserve the original formatting and line breaks.
        
        Text to translate:
        \(text)
        """
    }
    
    private func buildRequest(apiKey: String, prompt: String) -> URLRequest? {
        let urlString = "\(SharedConstants.geminiBaseURL)/v1beta/models/\(SharedConstants.geminiModel):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = GeminiRequest(
            contents: [
                GeminiRequest.Content(parts: [GeminiRequest.Part(text: prompt)])
            ],
            generationConfig: GeminiRequest.GenerationConfig(
                temperature: 0.1,
                maxOutputTokens: 2048
            )
        )
        
        guard let httpBody = try? JSONEncoder().encode(body) else { return nil }
        request.httpBody = httpBody
        return request
    }
}

