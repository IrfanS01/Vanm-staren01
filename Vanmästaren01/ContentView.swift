//
//  ContentView.swift
//  Vanmästaren01
//
//  Created by Irfan Sarac on 2024-04-25.
//

import SwiftUI
import Firebase




struct ContentView: View {
    @ObservedObject var habitsViewModel = HabitsViewModel()

    var body: some View {
        NavigationView {
            List {
                ForEach(habitsViewModel.habits) { habit in
                    VStack(alignment: .leading) {
                        Text(habit.name).font(.headline)
                        Text("Streak: \(habit.streak)").font(.subheadline)
                        Text("Completed Today: \(habit.isCompletedToday ? "Yes" : "No")").font(.subheadline)
                    }
                }
                .onDelete(perform: habitsViewModel.deleteHabit)
            }
            .navigationBarItems(trailing: Button(action: {
                habitsViewModel.addHabit(name: "Read Book", streak: 1, isCompletedToday: false)
            }) {
                Image(systemName: "plus")
            })
            .navigationBarTitle("Habits")
        }
    }
}
