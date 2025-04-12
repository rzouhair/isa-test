//
//  ItemGradeFunction.swift
//  notescan
//
//  Created by user on 16/2/2025.
//

import Foundation

struct DetectedGrade: Codable {
    var grade: String                 // e.g., "VF 25"
    var gradeLabel: String            // e.g., "Very Fine 25"
    var gradingScale: String          // e.g., "PMG"
    var justification: String         // Concise grading reasoning
    var notableStrengths: String    // Key highlights
    var notableFlaws: String        // Key defects
}

struct ItemGradeFunction: ToolDefinition {
    static let name = "grade_banknote"
    static let description = "Assigns a professional banknote grade and explains the rationale based on grading criteria"

    static let parameters: [String: AnyCodable] = [
        "type": AnyCodable("object"),
        "properties": AnyCodable([
            "grade": [
                "type": "string",
                "description": "The final assigned grade (e.g., 'VF 25', 'AU 55')"
            ],
            "gradeLabel": [
                "type": "string",
                "description": "A human-readable label for the grade, such as 'Very Fine 25'"
            ],
            "gradingScale": [
                "type": "string",
                "description": "The grading scale used, usually 'PMG' or 'IBNS'"
            ],
            "justification": [
                "type": "string",
                "description": "Summary of grading reasoning, based on paper quality, folds, corners, and other features"
            ],
            "notableStrengths": [
                "type": "string",
                "description": "List of positive features that strengthen the note’s grade, in form of a comma joined string"
            ],
            "notableFlaws": [
                "type": "string",
                "description": "List of flaws or imperfections that justify the deduction in grading, in form of a comma joined string"
            ]
        ]),
        "required": AnyCodable(["grade", "gradingScale", "justification", "notableStrengths", "notableFlaws"])
    ]

    static func handler(arguments: [String: Any]) async throws -> String {
        let grade = DetectedGrade(
            grade: arguments["grade"] as? String ?? "Unknown",
            gradeLabel: arguments["gradeLabel"] as? String ?? "Unknown Grade",
            gradingScale: arguments["gradingScale"] as? String ?? "PMG",
            justification: arguments["justification"] as? String ?? "No justification provided",
            notableStrengths: arguments["notableStrengths"] as? String ?? "",
            notableFlaws: arguments["notableFlaws"] as? String ?? ""
        )
        
        let encoder = JSONEncoder()
        return String(data: try encoder.encode(grade), encoding: .utf8) ?? "{}"
    }

    static func toFunctionDefinition() -> FunctionDefinition {
        return FunctionDefinition(
            name: self.name,
            description: self.description,
            parameters: self.parameters
        )
    }

    static func registerableFunction() -> RegisterableFunction {
        return RegisterableFunction(
            name: ItemGradeFunction.name,
            description: ItemGradeFunction.description,
            parameters: ItemGradeFunction.parameters,
            handler: ItemGradeFunction.handler
        )
    }
}
