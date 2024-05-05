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

    init() {
        loadHabits()
    }

    func loadHabits() {
        db.collection("habits").addSnapshotListener { (querySnapshot, error) in
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
                self.updateStreak() // Ažurirajte streak nakon što se navike učitaju
            }
        }
    }
    
    func updateStreak() {
        for index in 0..<habits.count {
            if let lastCompletionDate = habits[index].completionDates.last {
                if Calendar.current.isDateInYesterday(lastCompletionDate) {
                    habits[index].streak += 1
                } else if !Calendar.current.isDateInToday(lastCompletionDate) {
                    habits[index].streak = 0
                }
                
                // Ažuriranje Firestore dokumenta
                db.collection("habits").document(habits[index].id).updateData([
                    "streak": habits[index].streak
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
                self.loadHabits()  // Reload the habits after adding a new one
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
                    self.loadHabits() // Reload the habits after deletion
                }
            }
        }
    }

    func markHabitAsCompleted(habitId: String) {
        if let index = habits.firstIndex(where: { $0.id == habitId }) {
            var habit = habits[index]
            habit.isCompletedToday = true
            habit.completionDates.append(Date())
            habits[index] = habit
            updateHabit(habit)
        }
    }
    
    func toggleHabitCompletion(habitId: String) {
        if let index = habits.firstIndex(where: { $0.id == habitId }) {
            var habit = habits[index]
            habit.isCompletedToday.toggle()  // Prebacuje stanje izvršenosti

            if habit.isCompletedToday {
                // Dodaj trenutni datum ako je navika označena kao izvršena
                habit.completionDates.append(Date())
            } else {
                // Ukloni posljednji datum ako navika više nije označena kao izvršena
                habit.completionDates.removeLast()
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
            "completionDates": habit.completionDates.map { $0.timeIntervalSince1970 }
        ]) { error in
            if let error = error {
                print("Error updating document: \(error)")
            }
        }
    }
}
