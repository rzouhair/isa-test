//
//  Collection.swift
//  notescan
//
//  Created by user on 27/3/2025.
//

import SwiftUI

struct CollectionItem: Identifiable {
    let id = UUID()
    let country: String
    let denomination: String
    let year: String
    let serialNumber: String
    let entryDate: Date
    var isChecked = false
    
    var firstSideImage: String?
    var secondSideImage: String?
}

