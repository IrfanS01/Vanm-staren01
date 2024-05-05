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
    @State private var showingAddHabit = false
    @State private var newHabitName = ""
    @State private var newHabitStreak = 0
    @State private var isCompletedToday = false

    var body: some View {
        NavigationView {
            List {
                ForEach(habitsViewModel.habits) { habit in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(habit.name).font(.headline)

                            Spacer()

                            Button(action: {
                                // Toggle the completion state of the habit
                                habitsViewModel.toggleHabitCompletion(habitId: habit.id)
                            }) {
                                Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(habit.isCompletedToday ? .green : .gray)
                                    .imageScale(.large)
                            }
                        }

                        Text("Streak: \(habit.streak)").font(.subheadline)
                        Text("Completed Today: \(habit.isCompletedToday ? "Yes" : "No")").font(.subheadline)
                        Text("Total Days: \(habit.totalDays)").font(.subheadline)
                        ForEach(habit.completionDates, id: \.self) { date in
                            Text("Completed on: \(date, formatter: itemFormatter)").font(.subheadline)
                        }
                    }
                }
                .onDelete(perform: habitsViewModel.deleteHabit)
            }
            .navigationBarItems(trailing: Button(action: {
                self.showingAddHabit = true
            }) {
                Image(systemName: "plus")
            })
            .navigationBarTitle("Habits")
            .sheet(isPresented: $showingAddHabit) {
                VStack {
                    TextField("Enter habit name", text: $newHabitName)
                        .padding()
                    Button("Add Habit") {
                        habitsViewModel.addHabit(name: newHabitName, streak: newHabitStreak, isCompletedToday: isCompletedToday)
                        self.newHabitName = ""
                        self.showingAddHabit = false
                    }
                    .padding()
                }
            }
        }
    }

    // DateFormatter to format the completion date
    private var itemFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }
}
