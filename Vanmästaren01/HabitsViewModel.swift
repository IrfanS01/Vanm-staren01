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
                print("No documents")
                return
            }

            self.habits = documents.map { queryDocumentSnapshot -> Habit in
                let data = queryDocumentSnapshot.data()
                let name = data["name"] as? String ?? ""
                let streak = data["streak"] as? Int ?? 0
                let isCompletedToday = data["isCompletedToday"] as? Bool ?? false
                let id = queryDocumentSnapshot.documentID

                return Habit(id: id, name: name, streak: streak, isCompletedToday: isCompletedToday)
            }
        }
    }

    func addHabit(name: String, streak: Int, isCompletedToday: Bool) {
        let newHabit = Habit(name: name, streak: streak, isCompletedToday: isCompletedToday)
        db.collection("habits").addDocument(data: [
            "name": newHabit.name,
            "streak": newHabit.streak,
            "isCompletedToday": newHabit.isCompletedToday
        ]) { error in
            if let error = error {
                print("Error adding document: \(error)")
            } else {
                self.loadHabits() // Reload the habits after adding new one
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
}
