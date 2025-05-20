//
//  WeatherFunction.swift
//  paperscan
//
//  Created by user on 16/2/2025.
//

import Foundation

struct DetectedBanknote: Codable {
    var country: String?
    var title: String?
    var year: String?
    var serialNumber: String?
    var designElements: [String]?
    var specifications: [DetectedSpecification]?
    
    var name: String? {
        return "\(String(describing: country))'s \(year != nil ? String(year ?? "0") : "") \(String(describing: title))"
    }
    
    var fullSpecsList: String {
        return specifications?.map { "\($0.title): \($0.value)" }.joined(separator: "\n") ?? "No specifications available."
    }
}

struct DetectedSpecification: Codable {
    var title: String
    var value: String
}

struct ItemDetectionFunction: ToolDefinition {
    static let name = "detect_banknote"
    static let description = "Analyze and detect banknote details from the provided image"
    static let parameters: [String: AnyCodable] = [
        "type": AnyCodable("object"),
        "properties": AnyCodable([
            "country": [
                "type": "string",
                "description": "The country of origin for the banknote"
            ],
            "title": [
                "type": "string",
                "description": "The denomination and name of the banknote"
            ],
            "year": [
                "type": "string",
                "description": "The most probable year range of the banknote's issue or design change, one year if confident about it"
            ],
            "serialNumber": [
                "type": "string",
                "description": "The serial number printed on the banknote, if visible"
            ],
            "designElements": [
                "type": "array",
                "items": [
                    "type": "string"
                ],
                "description": "Array of design elements found on the banknote (portraits, buildings, symbols, etc.)"
            ],
            "specifications": [
                "type": "array",
                "items": [
                    "type": "object",
                    "properties": [
                        "title": [
                            "type": "string",
                            "description": "The name of the specification (e.g., 'Dimensions', 'Material')"
                        ],
                        "value": [
                            "type": "string",
                            "description": "The value of the specification"
                        ]
                    ],
                    "required": ["title", "value"]
                ],
                "description": "Array of specifications about the banknote"
            ]
        ]),
        "required": AnyCodable(["country", "title", "year", "serialNumber", "designElements", "specifications"])
    ]
    
    static func handler(arguments: [String: Any]) async throws -> String {
        let specs: [DetectedSpecification]
        if let specsArray = arguments["specifications"] as? [[String: String]] {
            specs = specsArray.compactMap { dict in
                guard let title = dict["title"], let value = dict["value"] else { return nil }
                return DetectedSpecification(title: title, value: value)
            }
        } else {
            specs = []
        }
        
        let banknote = DetectedBanknote(
            country: arguments["country"] as? String,
            title: arguments["title"] as? String,
            year: arguments["year"] as? String,
            serialNumber: arguments["serialNumber"] as? String,
            designElements: arguments["designElements"] as? [String],
            specifications: specs
        )
        
        let encoder = JSONEncoder()
        return String(data: try encoder.encode(banknote), encoding: .utf8) ?? "{}"
    }
    
    static func toFunctionDefinition() -> FunctionDefinition {
        return FunctionDefinition(name: self.name, description: self.description, parameters: self.parameters)
    }
    
    static func registerableFunction() -> RegisterableFunction {
        return RegisterableFunction(
            name: ItemDetectionFunction.name,
            description: ItemDetectionFunction.description,
            parameters: ItemDetectionFunction.parameters,
            handler: ItemDetectionFunction.handler
        )
    }
}
