import Foundation
import HealthKit

@MainActor @Observable
final class HealthKitService {
    static let shared = HealthKitService()

    private let healthStore = HKHealthStore()
    private(set) var isAuthorized = false

    // Current day data
    var stepsToday: Int = 0
    var activeCaloriesToday: Double = 0
    var restingHeartRate: Double = 0
    var sleepHoursLastNight: Double = 0
    var currentWeight: Double = 0

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    func requestAuthorization() async throws {
        guard isAvailable else { return }

        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.heartRate),
            HKQuantityType(.restingHeartRate),
            HKQuantityType(.bodyMass),
            HKCategoryType(.sleepAnalysis)
        ]

        let writeTypes: Set<HKSampleType> = [
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.bodyMass)
        ]

        try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
        isAuthorized = true
    }

    // MARK: - Fetch Today's Data

    func fetchTodayData() async {
        guard isAuthorized else { return }

        let s = await fetchStepsToday()
        let c = await fetchActiveCaloriesToday()
        let h = await fetchRestingHeartRate()
        let sl = await fetchSleepLastNight()
        let w = await fetchLatestWeight()

        self.stepsToday = s
        self.activeCaloriesToday = c
        self.restingHeartRate = h
        self.sleepHoursLastNight = sl
        self.currentWeight = w
    }

    // MARK: - Steps

    func fetchStepsToday() async -> Int {
        await fetchSumQuantity(
            type: HKQuantityType(.stepCount),
            unit: .count(),
            start: Date().startOfDay,
            end: Date()
        ).map { Int($0) } ?? 0
    }

    func fetchStepsHistory(days: Int) async -> [(date: Date, steps: Int)] {
        var results: [(Date, Int)] = []
        for dayOffset in 0..<days {
            let date = Date().daysAgo(dayOffset)
            let start = date.startOfDay
            let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
            let steps = await fetchSumQuantity(
                type: HKQuantityType(.stepCount),
                unit: .count(),
                start: start,
                end: end
            ).map { Int($0) } ?? 0
            results.append((start, steps))
        }
        return results.reversed()
    }

    // MARK: - Active Calories

    func fetchActiveCaloriesToday() async -> Double {
        await fetchSumQuantity(
            type: HKQuantityType(.activeEnergyBurned),
            unit: .kilocalorie(),
            start: Date().startOfDay,
            end: Date()
        ) ?? 0
    }

    // MARK: - Heart Rate

    func fetchRestingHeartRate() async -> Double {
        // Try resting heart rate first (Apple Watch)
        let resting = await fetchLatestQuantity(
            type: HKQuantityType(.restingHeartRate),
            unit: HKUnit.count().unitDivided(by: .minute())
        )
        if let resting, resting > 0 { return resting }

        // Fallback: latest heart rate sample (Xiaomi, Fitbit, etc.)
        let hr = await fetchLatestQuantity(
            type: HKQuantityType(.heartRate),
            unit: HKUnit.count().unitDivided(by: .minute())
        )
        return hr ?? 0
    }

    // MARK: - Sleep

    func fetchSleepLastNight() async -> Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        // Wider window: yesterday 6PM to today noon (covers night sleep fully)
        let searchStart = calendar.date(byAdding: .hour, value: -30, to: startOfToday)!
        let searchEnd = calendar.date(byAdding: .hour, value: 12, to: startOfToday)!

        let predicate = HKQuery.predicateForSamples(
            withStart: searchStart,
            end: searchEnd,
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKCategoryType(.sleepAnalysis),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0)
                    return
                }

                // Accept all sleep-related categories (asleep variants + inBed as fallback)
                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                ]
                let inBedValue = HKCategoryValueSleepAnalysis.inBed.rawValue

                let asleepSamples = samples.filter { asleepValues.contains($0.value) }

                let totalSeconds: Double
                if !asleepSamples.isEmpty {
                    // Prefer detailed sleep stages
                    totalSeconds = asleepSamples.reduce(0.0) {
                        $0 + $1.endDate.timeIntervalSince($1.startDate)
                    }
                } else {
                    // Fallback: use "inBed" samples (Xiaomi, Mi Fitness, etc.)
                    let inBedSamples = samples.filter { $0.value == inBedValue }
                    totalSeconds = inBedSamples.reduce(0.0) {
                        $0 + $1.endDate.timeIntervalSince($1.startDate)
                    }
                }

                continuation.resume(returning: totalSeconds / 3600.0)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Weight

    func fetchLatestWeight() async -> Double {
        await fetchLatestQuantity(
            type: HKQuantityType(.bodyMass),
            unit: .gramUnit(with: .kilo)
        ) ?? 0
    }

    func saveWeight(_ weightKg: Double) async throws {
        let type = HKQuantityType(.bodyMass)
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weightKg)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: Date(), end: Date())
        try await healthStore.save(sample)
    }

    // MARK: - Write Workout

    func saveWorkout(type: HKWorkoutActivityType, duration: TimeInterval, calories: Double) async throws {
        let workout = HKWorkout(
            activityType: type,
            start: Date().addingTimeInterval(-duration),
            end: Date(),
            duration: duration,
            totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: calories),
            totalDistance: nil,
            metadata: nil
        )
        try await healthStore.save(workout)
    }

    // MARK: - Private Helpers

    private func fetchSumQuantity(type: HKQuantityType, unit: HKUnit, start: Date, end: Date) async -> Double? {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                continuation.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit))
            }
            healthStore.execute(query)
        }
    }

    private func fetchLatestQuantity(type: HKQuantityType, unit: HKUnit) async -> Double? {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }
            healthStore.execute(query)
        }
    }
}
