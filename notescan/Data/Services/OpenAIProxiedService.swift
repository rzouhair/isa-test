//
//  OpenAIService.swift
//  notescan
//
//  Created by user on 14/2/2025.
//

import Foundation
import SwiftUI

public class OpenAIProxiedProvider: AIServiceProvider {
    private let baseURL = URL(string: Constants.proxyLambdaURL)!
    private let defaultModel: String
    
    private var functionRegistry: [String: ([String: Any]) async throws -> String] = [:]
    
    init(defaultModel: String = "gpt-4o-mini") {
        self.defaultModel = defaultModel
    }
    
    public func sendChat(messages: [Message], model: String?, temperature: Double, functions: [FunctionDefinition]?) async throws -> Message {
        let parameters: [String: Any] = [
            "endpoint": "text",
            "model": model ?? defaultModel,
            "input": messages.map { $0.toDict() },
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)

        var request = URLRequest(url: URL(string: Constants.proxyLambdaURL)!,timeoutInterval: Double.infinity)
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
        
        var request = URLRequest(url: URL(string: Constants.proxyLambdaURL)!,
                               timeoutInterval: Double.infinity)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            print(data)
            
            guard let responseString = String(data: data, encoding: .utf8) else {
                print("Some error here")
                throw AIServiceError.functionHandlingFailed
            }
            
            return responseString
        } catch {
            print(error)
            print("Error: \(error.localizedDescription)")
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
                "model": model ?? "gpt-4o-mini",
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
                    url: URL(string: Constants.proxyLambdaURL)!,
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
                
                print("Response from OpenAI: \(responseString)")

                let parsedResponse = parseOpenAIResponse(jsonString: responseString) as? FunctionCallResponse
                
                print("Parsed Response:")
                print(parsedResponse)

                guard (parsedResponse?.functionCall) != nil else {
                    return nil
                }
                if let functionCall = parsedResponse?.functionCall {
                    print("Function Call Output:")
                    print(functionCall)
                    let handledResponse = try await self.handleFunctionCall(functionCall)
                    print("Handled Response:")
                    print(handledResponse)
                    
                    // CHANGE: Parse the handled response string to the generic type T
                    if let jsonData = handledResponse.data(using: .utf8) {
                        do {
                            let decodedResult = try JSONDecoder().decode(T.self, from: jsonData)
                            print("Decoded Result:")
                            print(decodedResult)
                            return decodedResult
                        } catch {
                            print("Error decoding to type \(T.self): \(error)")
                            throw AIServiceError.functionHandlingFailed
                        }
                    }
                }
                
                return nil
            } catch {
                print("Error: \(error)")
                throw error
            }
    }
    
    public func sendWebSearch(prompt: String, model: String?) async throws -> CitationResult? {
        let parameters: [String: Any] = [
            "endpoint": "web_search",
            "model": model ?? defaultModel,
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
        
        var request = URLRequest(url: URL(string: Constants.proxyLambdaURL)!,
                               timeoutInterval: Double.infinity)
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
            print("No handler registered for function '\(functionCall.name)'")
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

