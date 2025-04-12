//
//  ChatViewModel.swift
//  notescan
//
//  Created by user on 14/2/2025.
//

import SwiftUI
import Foundation

@Observable
final class AIService {
    private var provider: any AIServiceProvider
    
    var messages: [Message] = []
    var isLoading = false
    var error: AIServiceError?
    
    init(provider: any AIServiceProvider) {
        self.provider = provider
    }
    
    func switchProvider(_ provider: any AIServiceProvider) {
        self.provider = provider
    }
    
    func sendMessage(_ text: String, initialMessages: [Message]? = nil, functions: [FunctionDefinition]? = nil, model: String = "gpt-4o-mini") async throws -> [Message]? {
        var conversationMessages: [Message] = initialMessages ?? messages
        let userMessage = Message(role: .user, content: text)
        conversationMessages.append(userMessage)
        isLoading = true
        
        do {
            // Step 1: Send the user message to the AI
            let response = try await provider.sendChat(
                messages: conversationMessages,
                model: model,
                temperature: 0.7,
                functions: functions
            )
            
            // Step 2: Check if the AI wants to call a function
            if let functionCall = response.functionCall {
                // Append the function call request to the messages
                conversationMessages.append(response)
                
                // Step 3: Handle the function call
                let result = try await provider.handleFunctionCall(functionCall)
                
                // Step 4: Append the function result to the messages
                let functionMessage = Message(
                    role: .function,
                    content: result,
                    functionName: functionCall.name
                )
                conversationMessages.append(functionMessage)
                
                // Step 5: Send the function result back to the AI
                let finalResponse = try await provider.sendChat(
                    messages: messages,
                    model: "gpt-4o-mini",
                    temperature: 0.7,
                    functions: nil
                )
                
                // Step 6: Append the final response to the messages
                conversationMessages.append(finalResponse)
            } else {
                // If no function call, just append the AI's response
                conversationMessages.append(response)
            }
        } catch let error as AIServiceError {
            self.error = error
        } catch {
            self.error = .unknownError(error.localizedDescription)
        }
        
        isLoading = false

        if initialMessages == nil || initialMessages?.isEmpty == true {
            messages = conversationMessages
            return messages
        } else {
            return conversationMessages
        }
    }

    func sendCompletion<T: Codable>(_ text: String, functions: [FunctionDefinition]? = nil) async -> T? {
        let userMessage = Message(role: .user, content: text)
        messages.append(userMessage)
        isLoading = true
        
        var completionResult: T? = nil
        
        do {
            // Step 1: Send the user message to the AI
            let response = try await provider.sendChat(
                messages: messages,
                model: "gpt-4o-mini",
                temperature: 0.7,
                functions: functions
            )
            
            // Step 2: Check if the AI wants to call a function
            if let functionCall = response.functionCall {
                print(functionCall)
                let result = try await provider.handleFunctionCall(functionCall)
                isLoading = false
                completionResult = JSONDecoder().decodeJson(from: result)
            }
        } catch let error as AIServiceError {
            print("Error sending completion request: \(error.localizedDescription)")
            print(error)
            self.error = error
        } catch {
            self.error = .unknownError(error.localizedDescription)
        }
        
        isLoading = false
        
        return completionResult
    }
    
    func sendWebSearch(prompt: String, model: String = "gpt-4o-mini") async -> CitationResult? {
        
        guard let response: CitationResult = try? await self.provider.sendWebSearch(
            prompt: prompt,
            model: model
        ) else {
            return nil
        }
        
        return response
    }

    func sendToolCompletion<T: Decodable>(prompt: String, tools: [FunctionDefinition], model: String = "gpt-4o-mini") async -> T? {
        
        guard let response: T? = try? await self.provider.sendToolCompletion(
            prompt: prompt,
            tools: tools,
            model: model,
            temperature: 0.5
        ) else {
            return nil
        }
        
        return response
    }
}
