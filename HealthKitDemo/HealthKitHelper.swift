//
//  HealthKitHelper.swift
//  HealthKitDemo
//
//  Created by Praks on 29/05/2022.
//

import Foundation
import HealthKit

class HealthKitHelper {
    var healthStore: HKHealthStore?

    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }

    func requestAuthorization() async throws -> Bool {
        let stepType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        let heartRateType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!

        guard let healthStore = self.healthStore else { return false }

        return try await withCheckedThrowingContinuation({
            (continuation: CheckedContinuation<Bool, Error>) in
            healthStore.requestAuthorization(toShare: [], read: [stepType, heartRateType]) { success, _ in
                continuation.resume(returning: success)
            }
        })
    }

    func fetchRecentHeartRate() async throws -> [HKSample]? {
        let heartRateType: HKQuantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        let sortDescriptors = [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]

        return try await withCheckedThrowingContinuation({
            (continuation: CheckedContinuation<[HKSample]?, Error>) in
            let heartRateQuery = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: sortDescriptors, resultsHandler: { _, results, error in
                if let result = results {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: error ?? AppError(message: "Something went wrong while accessing heart rate."))
                }
            })

            if let healthStore = healthStore {
                healthStore.execute(heartRateQuery)
            }
        })
    }

    func calculateSteps() async throws -> HKStatisticsCollection? {
        let stepType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        let anchorDate = Date.mondayAt12AM()
        let daily = DateComponents(day: 1)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        let query = HKStatisticsCollectionQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum, anchorDate: anchorDate, intervalComponents: daily)

        return try await withCheckedThrowingContinuation({
            (continuation: CheckedContinuation<HKStatisticsCollection, Error>) in
            query.initialResultsHandler = { _, statisticsCollection, error in
                if let statisticsCollection = statisticsCollection {
                    continuation.resume(returning: statisticsCollection)
                } else {
                    continuation.resume(throwing: error ?? AppError(message: "Something went wrong while accessing steps."))
                }
            }

            if let healthStore = healthStore {
                healthStore.execute(query)
            }
        })
    }
}

extension Date {
    static func mondayAt12AM() -> Date {
        return Calendar(identifier: .iso8601)
            .date(from: Calendar(identifier: .iso8601)
            .dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
    }
}

public struct AppError: Error {
    let message: String
}
