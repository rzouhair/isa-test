//
//  File.swift
//  
//
//  Created by user on 10/09/2023.
//

import RevenueCat
import Foundation

extension SubscriptionPeriod {

    var string: String {
        var unitString = ""

        if value == 1, unit == .week {
            return "7-day"
        }

        if value == 1 {
            unitString = unit.string
        } else {
            unitString = "\(unit.string)s"
        }

        return "\(value) \(unitString)"
    }

    var periodString: String {
        switch unit {
        case .month:
            return value == 3 ? "Quarterly" : "Monthly"
        case .year: return "Annual"
        case .day: return "Daily"
        case .week: return "Weekly"
        }
    }
}

extension SubscriptionPeriod.Unit {
    var string: String {
        switch self {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        }
    }
}

extension Package {
    var periodSting: String {
        if let subscription = storeProduct.subscriptionPeriod {
            return subscription.periodString
        } else if packageType == .lifetime {
            return "Lifetime"
        } else {
            return "Unknown"
        }
    }

    var priceString: String {
        if packageType == .lifetime {
            return localizedPriceString
        } else {
            return "\(localizedPriceString) / \(storeProduct.subscriptionPeriod?.unit.string ?? "")"
        }
    }

    var weeklyPriceString: String {
        guard let pricePerYear = storeProduct.pricePerYear else { return "" }
        let pricePerWeek = pricePerYear.dividing(by: 52.14)
        return "\(storeProduct.priceFormatter?.string(from: pricePerWeek) ?? "") / week"
    }
}
