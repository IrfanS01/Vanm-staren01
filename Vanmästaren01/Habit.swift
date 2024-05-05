//
//  Habit.swift
//  Vanmästaren01
//
//  Created by Irfan Sarac on 2024-04-25.
//

import Foundation

struct Habit: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var streak: Int
    var isCompletedToday: Bool
    var totalDays: Int = 0
    var completionDates: [Date] = []
}
