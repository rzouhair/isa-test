//
//  OpenAIService.swift
//  poke
//
//  Created by user on 14/2/2025.
//

import Foundation
import SwiftUI

public class OpenAIProxiedProvider: AIServiceProvider {
    private let baseURL = DIContainer.safeURL(Constants.proxyLambdaURL, context: "proxyLambdaURL")
    private let defaultModel: String
    
    private var functionRegistry: [String: ([String: Any]) async throws -> String] = [:]
    
    init(defaultModel: String = "gpt-4.1-mini") {
        self.defaultModel = defaultModel
    }
    
    public func sendChat(messages: [Message], model: String?, temperature: Double, functions: [FunctionDefinition]?) async throws -> Message {
        let parameters: [String: Any] = [
            "endpoint": "text",
            "model": model ?? defaultModel,
            "input": messages.map { $0.toDict() },
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)

        var request = URLRequest(url: DIContainer.safeURL(Constants.proxyLambdaURL, context: "proxyLambdaURL"),timeoutInterval: 240)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = jsonData

        let (data, _) = try await URLSession.shared.data(for: request)

        guard let responseString = String(data: data, encoding: .utf8) else {
            throw AIServiceError.functionHandlingFailed
        }
        
        let parsedResponse = parseOpenAIResponse(jsonString: responseString) as? TextResponse

        return Message(role: .assistant, content: parsedResponse?.textContent ?? "No function call found")
    }
    
    public func sendCompletion(prompt: String, model: String?, temperature: Double) async throws -> String {
        let parameters: [String: Any] = [
            "endpoint": "text",
            "model": model ?? defaultModel,
            "input": prompt
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        
        var request = URLRequest(url: DIContainer.safeURL(Constants.proxyLambdaURL, context: "proxyLambdaURL"),
                               timeoutInterval: 240)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)

            guard let responseString = String(data: data, encoding: .utf8) else {
                throw AIServiceError.functionHandlingFailed
            }

            return responseString
        } catch {
            #if DEBUG
            print("[OpenAIProxied] sendCompletion error: \(error.localizedDescription)")
            #endif
            throw error
        }
    }

    public func sendToolCompletion<T: Decodable>(prompt: String, tools: [FunctionDefinition], model: String?, temperature: Double = 0.5) async throws -> T? {
        let toolsArray = tools.map { tool in
            [
                "type": "function",
                "name": tool.name,
                "description": tool.description,
                "parameters": tool.parameters.mapValues { $0.value }
            ] as [String: Any]
        }
        
            // 2. Prepare the main parameters dictionary
            let parameters: [String: Any] = [
                "model": model ?? "gpt-4.1-mini",
                "endpoint": "function",
                "input": prompt,
                "tool_choice": "auto",
                "tools": toolsArray
            ]
            
            do {
                // 3. Convert to JSON with sorted keys to match Postman's order
                let jsonData = try JSONSerialization.data(
                    withJSONObject: parameters,
                    options: [.sortedKeys, .withoutEscapingSlashes]
                )
                
                // 4. Create and send the request
                var request = URLRequest(
                    url: DIContainer.safeURL(Constants.proxyLambdaURL, context: "proxyLambdaURL"),
                    timeoutInterval: 60
                )
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpMethod = "POST"
                request.httpBody = jsonData
                
                // 5. Use async/await for modern Swift concurrency
                let (data, _) = try await URLSession.shared.data(for: request)
                
                guard let responseString = String(data: data, encoding: .utf8) else {
                    throw AIServiceError.functionHandlingFailed
                }

                let parsedResponse = parseOpenAIResponse(jsonString: responseString) as? FunctionCallResponse

                guard (parsedResponse?.functionCall) != nil else {
                    return nil
                }
                if let functionCall = parsedResponse?.functionCall {
                    let handledResponse = try await self.handleFunctionCall(functionCall)

                    if let jsonData = handledResponse.data(using: .utf8) {
                        do {
                            return try JSONDecoder().decode(T.self, from: jsonData)
                        } catch {
                            #if DEBUG
                            print("[OpenAIProxied] decode error for \(T.self): \(error)")
                            #endif
                            throw AIServiceError.functionHandlingFailed
                        }
                    }
                }

                return nil
            } catch {
                #if DEBUG
                print("[OpenAIProxied] sendToolCompletion error: \(error)")
                #endif
                throw error
            }
    }
    
    public func sendWebSearch(prompt: String, model: String?) async throws -> CitationResult? {
        let parameters: [String: Any] = [
            "endpoint": "web_search",
            "model": model ?? "gpt-4o-mini",
            "input": prompt,
            "tools": [
                [
                    "type": "web_search_preview",
                    "domains": [],
                    "search_context_size": "medium"
                ]
            ]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
        
        var request = URLRequest(url: DIContainer.safeURL(Constants.proxyLambdaURL, context: "proxyLambdaURL"),
                               timeoutInterval: 240)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let responseString = String(data: data, encoding: .utf8) else {
            throw AIServiceError.functionHandlingFailed
        }
        
        let parsedResponse = parseOpenAIResponse(jsonString: responseString) as? WebSearchResponse

        // Parse the JSON response
        guard let websearchResponse = parsedResponse?.messageWithCitations else {
            throw AIServiceError.functionHandlingFailed
        }
        
        return websearchResponse
    }
    
    public func registerFunction(
        name: String,
        description: String,
        parameters: [String: AnyCodable],
        handler: @escaping ([String: Any]) async throws -> String
    ) {
        functionRegistry[name] = handler
    }
    
    public func handleFunctionCall(_ functionCall: FunctionCallOutput) async throws -> String {
        guard let handler = functionRegistry[functionCall.name] else {
            #if DEBUG
            print("[OpenAIProxied] No handler registered for function '\(functionCall.name)'")
            #endif
            throw AIServiceError.functionHandlingFailed
        }
        
        // Parse arguments
        guard let argumentsData = functionCall.arguments.data(using: .utf8),
              let arguments = try? JSONSerialization.jsonObject(with: argumentsData) as? [String: Any] else {
            throw AIServiceError.functionHandlingFailed
        }
        
        return try await handler(arguments)
    }
}

