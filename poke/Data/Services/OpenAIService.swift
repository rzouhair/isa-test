//
//  OpenAIService.swift
//  poke
//
//  Created by user on 14/2/2025.
//

import Foundation
import SwiftUI

public class OpenAIProvider: AIServiceProvider {
    private let baseURL = URL(string: "https://api.openai.com/v1")!
    private let apiKey: String
    private let defaultModel: String
    
    private var functionRegistry: [String: ([String: Any]) async throws -> String] = [:]
        
    public func registerFunction(
        name: String,
        description: String,
        parameters: [String: AnyCodable],
        handler: @escaping ([String: Any]) async throws -> String
    ) {
        functionRegistry[name] = handler
    }
    
    public init(apiKey: String, defaultModel: String = "gpt-4.1-mini") {
        self.apiKey = apiKey
        self.defaultModel = defaultModel
    }

    public func sendChat(
        messages: [Message],
        model: String?,
        temperature: Double = 0.7,
        functions: [FunctionDefinition]? = nil
    ) async throws -> Message {
        let url = baseURL.appendingPathComponent("/chat/completions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = OpenAIChatRequest(
            model: model ?? "gpt-4.1-mini",
            messages: messages.map(OpenAIMessage.init),
            temperature: temperature,
            functions: functions?.map(OpenAIFunctionDefinition.init)
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw handleOpenAIError(statusCode: httpResponse.statusCode, data: data)
        }
        
        let responseBody = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        guard let message = responseBody.choices.first?.message else {
            throw AIServiceError.invalidResponse
        }
        
        return Message(
            role: .assistant,
            content: message.content ?? "",
            functionCall: message.function_call,
            functionName: nil
        )
    }
    
    public func sendCompletion(
        prompt: String,
        model: String?,
        temperature: Double = 0.7
    ) async throws -> String {
        let url = baseURL.appendingPathComponent("/completions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = OpenAICompletionRequest(
            model: model ?? "gpt-4.1-mini",
            prompt: prompt,
            temperature: temperature,
            functions: nil
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw handleOpenAIError(statusCode: httpResponse.statusCode, data: data)
        }
        
        let responseBody = try JSONDecoder().decode(OpenAICompletionResponse.self, from: data)
        return responseBody.choices.first?.text ?? ""
    }
    
    public func sendToolCompletion<T>(prompt: String, tools: [FunctionDefinition], model: String?, temperature: Double) async throws -> T? where T : Decodable {
        return nil
    }
    
    public func sendWebSearch(prompt: String, model: String?) async throws -> CitationResult? {
        return nil
    }

    public func handleFunctionCall(_ functionCall: FunctionCallOutput) async throws -> String {
        guard let handler = functionRegistry[functionCall.name] else {
            throw AIServiceError.functionHandlingFailed
        }
        
        // Parse arguments
        guard let argumentsData = functionCall.arguments.data(using: .utf8),
              let arguments = try? JSONSerialization.jsonObject(with: argumentsData) as? [String: Any] else {
            throw AIServiceError.functionHandlingFailed
        }
        
        return try await handler(arguments)
    }
    
    private func handleOpenAIError(statusCode: Int, data: Data) -> AIServiceError {
        guard let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) else {
            return AIServiceError.unknownError("Unknown error occurred")
        }
        
        switch errorResponse.error.code {
        case "invalid_api_key": return .invalidAPIKey
        case "rate_limit_exceeded": return .rateLimited
        default: return .unknownError(errorResponse.error.message)
        }
    }
}

// MARK: - OpenAI Request/Response Models
private struct OpenAIChatRequest: Codable {
    let model: String
    let messages: [OpenAIMessage]
    let temperature: Double
    let functions: [OpenAIFunctionDefinition]?
}

private struct OpenAIMessage: Codable {
    let role: MessageRole
    let content: String?
    let name: String?
    let function_call: FunctionCallOutput?
    
    init(_ message: Message) {
        role = message.role
        content = message.content.description.isEmpty ? nil : message.content.description
        name = message.functionName
        function_call = message.functionCall
    }
}

private struct OpenAIFunctionDefinition: Codable {
    let name: String
    let description: String
    let parameters: [String: AnyCodable]
    
    init(_ function: FunctionDefinition) {
        name = function.name
        description = function.description
        parameters = function.parameters
    }
}

private struct OpenAIChatResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: MessageRole
            let content: String?
            let function_call: FunctionCallOutput?
        }
        let message: Message
    }
    let choices: [Choice]
}

private struct OpenAICompletionRequest: Codable {
    let model: String
    let prompt: String
    let temperature: Double
    let functions: [OpenAIFunctionDefinition]?
}

private struct OpenAICompletionResponse: Codable {
    struct Choice: Codable {
        let text: String
    }
    let choices: [Choice]
}

private struct OpenAIErrorResponse: Codable {
    struct ErrorInfo: Codable {
        let message: String
        let type: String
        let code: String
    }
    let error: ErrorInfo
}
