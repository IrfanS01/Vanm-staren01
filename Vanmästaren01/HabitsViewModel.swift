//
//  HabitsViewModel.swift
//  Vanmästaren01
//
//  Created by Irfan Sarac on 2024-04-25.
//

import Foundation
import SwiftUI
import Firebase

class HabitsViewModel: ObservableObject {
    @Published var habits: [Habit] = []
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var timer: Timer?

    init() {
        loadHabits()
        startDailyCheckTimer()
    }

    deinit {
        listener?.remove()
        timer?.invalidate()
    }

    func loadHabits() {
        listener = db.collection("habits").addSnapshotListener { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("No documents or error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            var newHabits: [Habit] = []
            let group = DispatchGroup()

            for document in documents {
                group.enter()
                DispatchQueue.global(qos: .userInteractive).async {
                    let data = document.data()
                    let completionTimestamps = data["completionDates"] as? [TimeInterval] ?? []
                    let completionDates = completionTimestamps.map { Date(timeIntervalSince1970: $0) }

                    let habit = Habit(
                        id: document.documentID,
                        name: data["name"] as? String ?? "",
                        streak: data["streak"] as? Int ?? 0,
                        isCompletedToday: data["isCompletedToday"] as? Bool ?? false,
                        totalDays: data["totalDays"] as? Int ?? 0,
                        completionDates: completionDates
                    )

                    DispatchQueue.main.async {
                        newHabits.append(habit)
                        group.leave()
                    }
                }
            }

            group.notify(queue: .main) {
                self.habits = newHabits.sorted { $0.name < $1.name }
                self.checkAndResetCompletionStatus()
                self.updateStreak()
            }
        }
    }

    func checkAndResetCompletionStatus() {
        let calendar = Calendar.current
        let currentDate = Date()

        for index in 0..<habits.count {
            if let lastCompletionDate = habits[index].completionDates.last {
                if !calendar.isDate(lastCompletionDate, inSameDayAs: currentDate) {
                    habits[index].isCompletedToday = false
                    updateHabit(habits[index])
                }
            } else {
                habits[index].isCompletedToday = false
                updateHabit(habits[index])
            }
        }
    }

    func startDailyCheckTimer() {
        checkAndResetCompletionStatus()

        timer = Timer.scheduledTimer(withTimeInterval: 60 * 60 * 24, repeats: true) { _ in
            self.checkAndResetCompletionStatus()
        }
    }

    func updateStreak() {
        let calendar = Calendar.current
        
        for index in 0..<habits.count {
            var habit = habits[index]
            let sortedDates = habit.completionDates.sorted()
            var currentStreak = 0
            var lastDate = sortedDates.last ?? Date()

            for date in sortedDates.reversed() {
                if calendar.isDateInToday(date) {
                    continue
                } else if calendar.isDate(lastDate, inSameDayAs: date) {
                    continue
                } else if let dayBefore = calendar.date(byAdding: .day, value: -1, to: lastDate),
                          calendar.isDate(dayBefore, inSameDayAs: date) {
                    currentStreak += 1
                    lastDate = date
                } else {
                    break
                }
            }

            if habit.streak != currentStreak {
                habit.streak = currentStreak
                habits[index] = habit

                db.collection("habits").document(habit.id).updateData([
                    "streak": habit.streak
                ]) { error in
                    if let error = error {
                        print("Error updating document: \(error)")
                    }
                }
            }
        }
    }

    func addHabit(name: String, streak: Int, isCompletedToday: Bool) {
        let currentDate = Date()
        let newHabit = Habit(
            name: name,
            streak: streak,
            isCompletedToday: isCompletedToday,
            totalDays: 1,
            completionDates: isCompletedToday ? [currentDate] : []
        )
        db.collection("habits").addDocument(data: [
            "name": newHabit.name,
            "streak": newHabit.streak,
            "isCompletedToday": newHabit.isCompletedToday,
            "totalDays": newHabit.totalDays,
            "completionDates": newHabit.completionDates.map { $0.timeIntervalSince1970 }
        ]) { error in
            if let error = error {
                print("Error adding document: \(error)")
            } else {
                self.loadHabits()
            }
        }
    }

    func deleteHabit(at offsets: IndexSet) {
        offsets.forEach { index in
            let habitId = habits[index].id
            db.collection("habits").document(habitId).delete() { error in
                if let error = error {
                    print("Error removing document: \(error)")
                } else {
                    self.loadHabits()
                }
            }
        }
    }

    func markHabitAsCompleted(habitId: String) {
        if let index = habits.firstIndex(where: { $0.id == habitId }) {
            var habit = habits[index]
            habit.isCompletedToday = true
            habit.totalDays += 1
            habit.completionDates.append(Date())
            habits[index] = habit
            updateHabit(habit)
        }
    }

    func toggleHabitCompletion(habitId: String) {
        if let index = habits.firstIndex(where: { $0.id == habitId }) {
            var habit = habits[index]
            habit.isCompletedToday.toggle()

            if habit.isCompletedToday {
                habit.completionDates.append(Date())
                habit.totalDays += 1
            } else {
                if !habit.completionDates.isEmpty {
                    habit.completionDates.removeLast()
                    habit.totalDays -= 1
                }
            }
            habits[index] = habit
            updateHabit(habit)
        }
    }

    func updateHabit(_ habit: Habit) {
        let habitRef = db.collection("habits").document(habit.id)
        habitRef.updateData([
            "name": habit.name,
            "streak": habit.streak,
            "isCompletedToday": habit.isCompletedToday,
            "totalDays": habit.totalDays,
            "completionDates": habit.completionDates.map { $0.timeIntervalSince1970 }
        ]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            }
        }
    }
}
