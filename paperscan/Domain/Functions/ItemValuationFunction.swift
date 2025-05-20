//
//  WeatherFunction.swift
//  paperscan
//
//  Created by user on 16/2/2025.
//

import Foundation

struct DetectedValuation: Codable {
    var banknote: String
    var circulated: String
    var uncirculated: String
}

struct ItemValuationFunction: ToolDefinition {
    static let name = "valuate_banknote"
    static let description = "Analyze and detect the banknote valuation from the provided web search results"
    static let parameters: [String: AnyCodable] = [
        "type": AnyCodable("object"),
        "properties": AnyCodable([
            "banknote": [
                "type": "string",
                "description": "The banknote description"
            ],
            "circulated": [
                "type": "string",
                "description": "The number of banknotes in circulated condition with the currency prefix, or n/a if unavailable"
            ],
            "uncirculated": [
                "type": "string",
                "description": "The number of banknotes in uncirculated condition with the currency prefix, or n/a if unavailable"
            ]
        ]),
        "required": AnyCodable(["banknote", "circulated", "uncirculated"])
    ]
    
    static func handler(arguments: [String: Any]) async throws -> String {
        let banknote = DetectedValuation(
            banknote: arguments["banknote"] as? String ?? "",
            circulated: arguments["circulated"] as? String ?? "n/a",
            uncirculated: arguments["uncirculated"] as? String ?? "n/a"
        )
        
        let encoder = JSONEncoder()
        return String(data: try encoder.encode(banknote), encoding: .utf8) ?? "{}"
    }
    
    static func toFunctionDefinition() -> FunctionDefinition {
        return FunctionDefinition(name: self.name, description: self.description, parameters: self.parameters)
    }
    
    static func registerableFunction() -> RegisterableFunction {
        return RegisterableFunction(
            name: ItemValuationFunction.name,
            description: ItemValuationFunction.description,
            parameters: ItemValuationFunction.parameters,
            handler: ItemValuationFunction.handler
        )
    }
}
