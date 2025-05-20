//
//  Weather.swift
//  paperscan
//
//  Created by user on 16/2/2025.
//

struct WeatherInput: Codable {
    let location: String
    let unit: String?
}

struct WeatherOutput: Codable {
    let location: String
    let temperature: Double
    let unit: String
    let description: String
}
