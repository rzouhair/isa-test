//
//  AIServiceProvider.swift
//  paperscan
//
//  Created by user on 14/2/2025.
//

import Foundation
import SwiftUI

// MARK: - Core Data Models

// ADD: Content type enum
public enum MessageContentType: String, Codable {
    case text = "input_text"
    case image = "input_image"
}

// ADD: Content item struct
public struct MessageContent: Codable {
    let type: MessageContentType
    let text: String?
    let imageURL: String?
    
    enum CodingKeys: String, CodingKey {
        case type
        case text
        case imageURL = "image_url"
    }
    
    public init(text: String) {
        self.type = .text
        self.text = text
        self.imageURL = nil
    }
    
    public init(imageURL: String) {
        self.type = .image
        self.text = nil
        self.imageURL = imageURL
    }
}

// ADD: Message content enum
public enum MessageContentValue: Codable, CustomStringConvertible {
    case string(String)
    case contentArray([MessageContent])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .string(str)
        } else if let array = try? container.decode([MessageContent].self) {
            self = .contentArray(array)
        } else {
            throw DecodingError.typeMismatch(MessageContentValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String or [MessageContent]"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let str):
            try container.encode(str)
        case .contentArray(let array):
            try container.encode(array)
        }
    }
    
    public var description: String {
        switch self {
        case .string(let str):
            return str
        case .contentArray(let contents):
            return contents.first(where: { $0.type == .text })?.text ?? ""
        }
    }
}

public enum MessageRole: String, Codable {
    case system
    case user
    case assistant
    case function
}

public struct Message: Codable, Identifiable {
    public let id = UUID()
    public let role: MessageRole
    public var content: MessageContentValue
    public var functionCall: FunctionCallOutput?
    public var functionName: String?
    
    public init(role: MessageRole, content: String, functionCall: FunctionCallOutput? = nil, functionName: String? = nil) {
        self.role = role
        self.content = .string(content)
        self.functionCall = functionCall
        self.functionName = functionName
    }
    
    public init(role: MessageRole, content: [MessageContent], functionCall: FunctionCallOutput? = nil, functionName: String? = nil) {
        self.role = role
        self.content = .contentArray(content)
        self.functionCall = functionCall
        self.functionName = functionName
    }
    
    public func toDict() -> [String: Any] {
        var messageDict: [String: Any] = [
            "role": role.rawValue
        ]
        
        switch content {
        case .string(let str):
            messageDict["content"] = str
        case .contentArray(let contents):
            messageDict["content"] = contents.map { content in
                var contentDict: [String: Any] = [
                    "type": content.type.rawValue
                ]
                if let text = content.text {
                    contentDict["text"] = text
                }
                if let imageURL = content.imageURL {
                    contentDict["image_url"] = imageURL
                }
                return contentDict
            }
        }
        
        return messageDict
    }
    
    public static func toAPIRequest(messages: [Message], endpoint: String = "text", model: String = "gpt-4o") -> [String: Any] {
        return [
            "endpoint": endpoint,
            "model": model,
            "input": messages.map { $0.toDict() }
        ]
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
        model: String?,
        temperature: Double,
        functions: [FunctionDefinition]?
    ) async throws -> Message
    
    func sendCompletion(
        prompt: String,
        model: String?,
        temperature: Double
    ) async throws -> String
    
    func sendWebSearch(prompt: String, model: String?) async throws -> CitationResult?
    
    func registerFunction(
        name: String,
        description: String,
        parameters: [String: AnyCodable],
        handler: @escaping ([String: Any]) async throws -> String
    )

    func sendToolCompletion<T: Decodable>(
        prompt: String,
        tools: [FunctionDefinition],
        model: String?,
        temperature: Double
    ) async throws -> T?
    
    func handleFunctionCall(_ functionCall: FunctionCallOutput) async throws -> String
}

// MARK: - Service Errors
public enum AIServiceError: Error {
    case invalidResponse
    case networkError(Int)
    case rateLimited
    case invalidAPIKey
    case functionHandlingFailed
    case unknownError(String)
    case serverError(statusCode: Int, message: String)
}
