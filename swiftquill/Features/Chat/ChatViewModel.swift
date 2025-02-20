//
//  ChatViewModel.swift
//  swiftquill
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
    
    func sendMessage(_ text: String, functions: [FunctionDefinition]? = nil) async {
        let userMessage = Message(role: .user, content: text)
        messages.append(userMessage)
        isLoading = true
        
        do {
            // Step 1: Send the user message to the AI
            let response = try await provider.sendChat(
                messages: messages,
                model: "gpt-3.5-turbo",
                temperature: 0.7,
                functions: functions
            )
            
            // Step 2: Check if the AI wants to call a function
            if let functionCall = response.functionCall {
                // Append the function call request to the messages
                messages.append(response)
                
                // Step 3: Handle the function call
                let result = try await provider.handleFunctionCall(functionCall)
                print(result)
                
                // Step 4: Append the function result to the messages
                let functionMessage = Message(
                    role: .function,
                    content: result,
                    functionName: functionCall.name
                )
                messages.append(functionMessage)
                
                // Step 5: Send the function result back to the AI
                let finalResponse = try await provider.sendChat(
                    messages: messages,
                    model: "gpt-3.5-turbo",
                    temperature: 0.7,
                    functions: nil
                )
                
                print(finalResponse)
                
                // Step 6: Append the final response to the messages
                messages.append(finalResponse)
            } else {
                // If no function call, just append the AI's response
                messages.append(response)
            }
        } catch let error as AIServiceError {
                self.error = error
            } catch {
                self.error = .unknownError(error.localizedDescription)
            }
        
        isLoading = false
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
                model: "gpt-3.5-turbo",
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
            self.error = error
        } catch {
            self.error = .unknownError(error.localizedDescription)
        }
        
        isLoading = false
        
        return completionResult
    }
}
