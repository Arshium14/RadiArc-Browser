//
//  PerplexityRequest.swift
//  Perplexity API
//
//  Created by Reyna Myers on 20/6/24.
//

import Foundation

/// Retains the call site's prompt-only API; failures are errors, never answer text.
func getChatCompletion(prompt: String) async throws -> String {
    let client = PerplexityClient(apiKey: UserDefaults.standard.string(forKey: "apiKey") ?? "")
    return try await client.completion(prompt: prompt)
}

enum PerplexityError: Error, LocalizedError, Equatable {
    case emptyPrompt
    case missingAPIKey
    case unauthorized
    case forbidden
    case quotaExceeded
    case rateLimited
    case httpError(statusCode: Int, message: String?)
    case invalidResponse
    case invalidResponseBody
    case emptyResponse
    case network(URLError.Code)

    var needsSettings: Bool {
        switch self {
        case .missingAPIKey, .unauthorized, .forbidden, .quotaExceeded:
            return true
        default:
            return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .emptyPrompt:
            return "Enter a question to search."
        case .missingAPIKey:
            return "Add your Perplexity API key in Settings to use Browse for Me."
        case .unauthorized:
            return "Perplexity did not accept your API key. Check it in Settings and try again."
        case .forbidden:
            return "This API key does not have access. Check your Perplexity account and API key."
        case .quotaExceeded:
            return "Your Perplexity API account needs credits. Check your account billing before trying again."
        case .rateLimited:
            return "Perplexity is receiving too many requests. Wait a moment, then try again."
        case let .httpError(statusCode, message):
            if statusCode >= 500 {
                return "Perplexity is temporarily unavailable (HTTP \(statusCode)). Please try again shortly."
            }
            let detail = message.map { " \($0)" } ?? ""
            return "Perplexity could not complete the request (HTTP \(statusCode)).\(detail) Try another question."
        case .invalidResponse, .invalidResponseBody:
            return "Perplexity returned an unreadable response. Please try again."
        case .emptyResponse:
            return "Perplexity returned no answer. Try again or rephrase your question."
        case .network(.timedOut):
            return "The search timed out. Check your connection and try again."
        case .network:
            return "Unable to reach Perplexity. Check your internet connection and try again."
        }
    }
}

struct PerplexityClient {
    let apiKey: String
    var session: URLSession = .shared

    func completion(prompt: String) async throws -> String {
        try Task.checkCancellation()
        let query = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { throw PerplexityError.emptyPrompt }
        guard !key.isEmpty else { throw PerplexityError.missingAPIKey }

        // Documented synchronous Sonar compatibility endpoint; the public docs
        // recommend the Agent API for a future, separate API migration.
        // https://docs.perplexity.ai/api-reference/chat-completions-post
        let url = URL(string: "https://api.perplexity.ai/v1/sonar")!
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(CompletionRequest(
            model: "sonar",
            messages: [
                Message(role: "system", content: "Be precise. Answer in several paragraphs. Format your response using markdown. Include bullet points for key information."),
                Message(role: "user", content: query)
            ]
        ))

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError {
            if error.code == .cancelled || Task.isCancelled { throw CancellationError() }
            throw PerplexityError.network(error.code)
        } catch {
            try Task.checkCancellation()
            throw PerplexityError.network(.unknown)
        }
        try Task.checkCancellation()
        guard let response = response as? HTTPURLResponse else {
            throw PerplexityError.invalidResponse
        }
        guard (200..<300).contains(response.statusCode) else {
            switch response.statusCode {
            case 401: throw PerplexityError.unauthorized
            case 402: throw PerplexityError.quotaExceeded
            case 403: throw PerplexityError.forbidden
            case 429: throw PerplexityError.rateLimited
            default:
                let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                let message = errorResponse?.error.message?.trimmingCharacters(in: .whitespacesAndNewlines)
                throw PerplexityError.httpError(
                    statusCode: response.statusCode,
                    message: message.flatMap { $0.isEmpty ? nil : $0 }
                )
            }
        }

        let completion: CompletionResponse
        do {
            completion = try JSONDecoder().decode(CompletionResponse.self, from: data)
        } catch {
            throw PerplexityError.invalidResponseBody
        }
        let answer = (completion.choices.first?.message.content ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !answer.isEmpty else { throw PerplexityError.emptyResponse }
        return answer
    }

    private struct CompletionRequest: Encodable {
        let model: String
        let messages: [Message]
    }

    private struct Message: Encodable {
        let role: String
        let content: String
    }

    private struct CompletionResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let content: String?
            }
            let message: Message
        }
        let choices: [Choice]
    }

    private struct ErrorResponse: Decodable {
        struct Detail: Decodable {
            let message: String?
        }
        let error: Detail
    }
}
