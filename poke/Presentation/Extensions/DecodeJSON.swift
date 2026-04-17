//
//  DecodeJSON.swift
//  poke
//
//  Created by user on 18/2/2025.
//

import Foundation

extension JSONDecoder {
    func decodeJson<T: Codable>(from jsonString: String) -> T? {
        // Convert the JSON string to Data
        guard let jsonData = jsonString.data(using: .utf8) else {
            print("Failed to convert JSON string to Data")
            return nil
        }
        
        do {
            // Decode the JSON data into an instance of type T
            let decodedObject = try JSONDecoder().decode(T.self, from: jsonData)
            return decodedObject
        } catch {
            print("Failed to decode JSON: \(error)")
            return nil
        }
    }
}
