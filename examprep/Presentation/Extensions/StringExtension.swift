//
//  StringExtension.swift
//  examprep
//
//  Created by user on 31/3/2025.
//

import Foundation

extension String {
    func replaceVariables (with values: [String: String]) -> String {
        var result = self
        let pattern = #"\{\{\s*([^\}]+)\s*\}\}"#
        
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let matches = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
            
            for match in matches.reversed() {
                if let keyRange = Range(match.range(at: 1), in: self) {
                    let key = String(self[keyRange]).trimmingCharacters(in: .whitespaces)
                    if let value = values[key] {
                        if let replaceRange = Range(match.range(at: 0), in: self) {
                            result = result.replacingCharacters(in: replaceRange, with: value)
                        }
                    }
                }
            }
        }
        
        return result
    }
}

extension String {
    func removeMarkdownLinks() -> String {
        // This regex matches markdown links in the format: ([text](url))
        let pattern = "\\(\\[[^\\]]*\\]\\([^\\)]*\\)\\)"
        return self.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
    }
}

extension String {
    func replaceQueryItemWith(name oldSource: String, with newSource: String) -> String? {
        guard var components = URLComponents(string: self) else { return nil }

        if let index = components.queryItems?.firstIndex(where: { $0.name == oldSource }) {
            components.queryItems?[index].value = newSource
        } else {
            // Append utm_source if not found
            var queryItems = components.queryItems ?? []
            queryItems.append(URLQueryItem(name: oldSource, value: newSource))
            components.queryItems = queryItems
        }

        return components.string
    }
}

extension Decimal {
    var doubleValue:Double {
        return NSDecimalNumber(decimal:self).doubleValue
    }
}