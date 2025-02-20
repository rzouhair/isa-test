//
//  AIServiceProvider.swift
//  swiftquill
//
//  Created by user on 14/2/2025.
//

import Foundation
import SwiftUI

// MARK: - Core Data Models
public enum MessageRole: String, Codable {
    case system
    case user
    case assistant
    case function
}

public struct Message: Codable, Identifiable {
    public let id = UUID()
    public let role: MessageRole
    public var content: String
    public var functionCall: FunctionCall?
    public var functionName: String?
    
    public init(role: MessageRole, content: String, functionCall: FunctionCall? = nil, functionName: String? = nil) {
        self.role = role
        self.content = content
        self.functionCall = functionCall
        self.functionName = functionName
    }
}

public struct FunctionCall: Codable {
    public let name: String
    public let arguments: String
    
    public init(name: String, arguments: String) {
        self.name = name
        self.arguments = arguments
    }
}

public struct FunctionDefinition: Codable {
    public let name: String
    public let description: String
    public let parameters: [String: AnyCodable]
    
    public init(name: String, description: String, parameters: [String: AnyCodable]) {
        self.name = name
        self.description = description
        self.parameters = parameters
    }
}

public struct AnyCodable: Codable {
    public let value: Any
    
    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode AnyCodable")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let string as String: try container.encode(string)
        case let int as Int: try container.encode(int)
        case let bool as Bool: try container.encode(bool)
        case let double as Double: try container.encode(double)
        case let array as [Any]: try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]: try container.encode(dictionary.mapValues { AnyCodable($0) })
        default: break
        }
    }
}

protocol FunctionProtocol {
    associatedtype Input: Codable
    associatedtype Output: Codable
    
    var name: String { get }
    var description: String { get }
    var parameters: [String: AnyCodable] { get }
    func handle(arguments: Input) async throws -> Output
}

public struct AnyFunction: FunctionProtocol {
    private let _name: () -> String
    private let _description: () -> String
    private let _parameters: () -> [String: AnyCodable]
    private let _handle: (Data) async throws -> String
    
    init<F: FunctionProtocol>(_ function: F) {
        self._name = { function.name }
        self._description = { function.description }
        self._parameters = { function.parameters }
        self._handle = { data in
            let input = try JSONDecoder().decode(F.Input.self, from: data)
            let output = try await function.handle(arguments: input)
            return String(data: try JSONEncoder().encode(output), encoding: .utf8) ?? "{}"
        }
    }
    
    var name: String { _name() }
    var description: String { _description() }
    var parameters: [String: AnyCodable] { _parameters() }
    
    func handle(arguments: Data) async throws -> String {
        try await _handle(arguments)
    }
}

// MARK: - Service Protocol
public protocol AIServiceProvider {
    func sendChat(
        messages: [Message],
        model: String,
        temperature: Double,
        functions: [FunctionDefinition]?
    ) async throws -> Message
    
    func sendCompletion(
        prompt: String,
        model: String,
        temperature: Double
    ) async throws -> String
    
    func sendChat<T: Codable>(
        prompt: String,
        model: String,
        temperature: Double,
        functions: [FunctionDefinition]?
    ) async throws -> T?

    // func registerFunction(_ function: AnyFunction)
    // func handleFunctionCall(_ functionCall: FunctionCall) async throws -> String
    
    func registerFunction(
        name: String,
        description: String,
        parameters: [String: AnyCodable],
        handler: @escaping ([String: Any]) async throws -> String
    )
    
    func handleFunctionCall(_ functionCall: FunctionCall) async throws -> String
}

// MARK: - Service Errors
public enum AIServiceError: Error {
    case invalidResponse
    case networkError(Int)
    case rateLimited
    case invalidAPIKey
    case functionHandlingFailed
    case unknownError(String)
}
