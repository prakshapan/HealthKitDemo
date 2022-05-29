//
//  ContentView.swift
//  HealthKitDemo
//
//  Created by Praks on 29/05/2022.
//

import HealthKit
import SwiftUI

struct ContentView: View {
    private var healthStore: HealthKitHelper?
    @State private var steps: [Step] = [Step]()
    @State private var heartRateValue: String?
    @State private var heartRateDateValue: String?

    init() {
        healthStore = HealthKitHelper()
    }

    var body: some View {
        NavigationView {
            VStack {
                GraphView(steps: steps).navigationTitle("Heath Data")
                Text("Heart Rate measured on **\(heartRateDateValue ?? "")** was **\(heartRateValue ?? "")** count per minute.")
            }.padding()
        }
        .task { await fetchFromHealthStore() }
    }

    private func fetchFromHealthStore() async {
        guard let healthStore = healthStore else { return }
        do {
            if let accessHealthStore = try? await healthStore.requestAuthorization(), accessHealthStore {
                if let userSteps = try await healthStore.calculateSteps() {
                    updateSteps(with: userSteps)
                }

                if let heartRate = try await healthStore.fetchRecentHeartRate() {
                    updateHeartRate(with: heartRate)
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }

    private func updateHeartRate(with results: [HKSample]) {
        let heartRateUnit: HKUnit = HKUnit.count().unitDivided(by: HKUnit.minute())

        if let recentHeartRate = results.first, let heartRate = recentHeartRate as? HKQuantitySample {
            heartRateValue = heartRate.quantity.doubleValue(for: heartRateUnit).description

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM dd, yyyy 'at' hh:MM a"
            heartRateDateValue = dateFormatter.string(from: heartRate.startDate)
        }
    }

    private func updateSteps(with statisticsCollection: HKStatisticsCollection) {
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let endDate = Date()

        statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
            let count = statistics.sumQuantity()?.doubleValue(for: .count())
            let step = Step(count: Int(count ?? 0), date: statistics.startDate)
            steps.append(step)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
