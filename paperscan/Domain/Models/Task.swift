//
//  Item.swift
//  paperscan
//
//  Created by user on 06/03/2024.
//

import Foundation
import SwiftData

@Model
final class TodoTask {
    var name: String
    var date: Date
    var isComplete: Bool

    init(name: String, date: Date, isComplete: Bool) {
        self.name = name
        self.date = date
        self.isComplete = isComplete
    }
}
