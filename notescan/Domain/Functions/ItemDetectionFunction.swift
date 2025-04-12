//
//  WeatherFunction.swift
//  notescan
//
//  Created by user on 16/2/2025.
//

import Foundation

struct WeatherFunction: ToolDefinition {
    static let name = "get_current_weather"
    static let description = "Get the current weather in a given location"
    static let parameters: [String: AnyCodable] = [
        "type": AnyCodable("object"),
        "properties": AnyCodable([
            "location": [
                "type": "string",
                "description": "The city and state, e.g., San Francisco, CA"
            ],
            "temperature": [
                "type": "number",
                "description": "The actual temperature value"
            ],
            "description": [
                "type": "string",
                "description": "The description of the weather output"
            ],
            "unit": [
                "type": "string",
                "enum": ["celsius", "fahrenheit"]
            ]
        ]),
        "required": AnyCodable(["location"])
    ]
    
    static func handler(arguments: [String: Any]) async throws -> String {
        guard let location = arguments["location"] as? String else {
            throw AIServiceError.functionHandlingFailed
        }
        
        // Simulate fetching weather data
        let weather = [
            "location": location,
            "temperature": 22,
            "unit": arguments["unit"] as? String ?? "celsius",
            "description": "Sunny"
        ] as [String : Any]
        
        let weatherJSON = try JSONSerialization.data(withJSONObject: weather)
        return String(data: weatherJSON, encoding: .utf8) ?? "{}"
    }
}
