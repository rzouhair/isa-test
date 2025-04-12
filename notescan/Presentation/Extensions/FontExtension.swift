//
//  FontExtension.swift
//  notescan
//
//  Created by user on 06/03/2024.
//

import SwiftUI

extension SwiftUI.Font {

    static let title = (
        regular: FontFamily.Rubik.regular.swiftUIFont(size: FontConvertible.Font.preferredFont(forTextStyle: .title1).pointSize),
        medium: FontFamily.Rubik.medium.swiftUIFont(size: FontConvertible.Font.preferredFont(forTextStyle: .title1).pointSize),
        bold: FontFamily.Rubik.bold.swiftUIFont(size: FontConvertible.Font.preferredFont(forTextStyle: .title1).pointSize)
    )

    static let subtitle = (
        regular: FontFamily.Rubik.regular.swiftUIFont(size: FontConvertible.Font.preferredFont(forTextStyle: .subheadline).pointSize),
        medium: FontFamily.Rubik.medium.swiftUIFont(size: 24),
        bold: FontFamily.Rubik.bold.swiftUIFont(size: FontConvertible.Font.preferredFont(forTextStyle: .subheadline).pointSize)
    )

    static let defaultText = (
        regular: FontFamily.Rubik.regular.swiftUIFont(size: FontConvertible.Font.systemFontSize),
        medium: FontFamily.Rubik.medium.swiftUIFont(size: FontConvertible.Font.systemFontSize),
        bold: FontFamily.Rubik.bold.swiftUIFont(size: FontConvertible.Font.systemFontSize)
    )
}
