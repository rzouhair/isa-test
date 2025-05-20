//
//  WeatherFunction.swift
//  paperscan
//
//  Created by user on 16/2/2025.
//

import Foundation

struct DetectedBanknoteRarity: Codable {
    var rarity: Int?
}

struct ItemRarityFunction: ToolDefinition {
    static let name = "detect_banknote_rarity"
    static let description = "Analyze and detect banknote rarity score from 0-100"
    static let parameters: [String: AnyCodable] = [
        "type": AnyCodable("object"),
        "properties": AnyCodable([
            "rarity": [
                "type": "number",
                "description": "The rarity range of the banknote"
            ]
        ]),
        "required": AnyCodable(["rarity"])
    ]
    
    static func handler(arguments: [String: Any]) async throws -> String {
        let banknote = DetectedBanknoteRarity(
            rarity: arguments["rarity"] as? Int
        )
        
        let encoder = JSONEncoder()
        return String(data: try encoder.encode(banknote), encoding: .utf8) ?? "{}"
    }
    
    static func toFunctionDefinition() -> FunctionDefinition {
        return FunctionDefinition(name: self.name, description: self.description, parameters: self.parameters)
    }
    
    static func registerableFunction() -> RegisterableFunction {
        return RegisterableFunction(
            name: ItemRarityFunction.name,
            description: ItemRarityFunction.description,
            parameters: ItemRarityFunction.parameters,
            handler: ItemRarityFunction.handler
        )
    }
}
