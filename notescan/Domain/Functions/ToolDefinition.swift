//
//  ToolDefinition.swift
//  notescan
//
//  Created by user on 30/3/2025.
//

public struct RegisterableFunction {
    let name: String
    let description: String
    let parameters: [String: AnyCodable]
    let handler: ([String: Any]) async throws -> String
}

public protocol ToolDefinition {
    static var name: String { get }
    static var description: String { get }
    static var parameters: [String: AnyCodable] { get }
    static func handler(arguments: [String: Any]) async throws -> String
    static func toFunctionDefinition() -> FunctionDefinition
    static func registerableFunction() -> RegisterableFunction
}
