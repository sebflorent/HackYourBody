import Foundation
import SwiftData

@Model
final class BodyMeasurement {
    var date: Date
    var chestCm: Double
    var waistCm: Double
    var hipsCm: Double
    var leftBicepCm: Double
    var rightBicepCm: Double
    var leftThighCm: Double
    var rightThighCm: Double
    var neckCm: Double
    var shouldersCm: Double
    var bodyFatPercent: Double?

    init(
        date: Date = .now,
        chestCm: Double = 0,
        waistCm: Double = 0,
        hipsCm: Double = 0,
        leftBicepCm: Double = 0,
        rightBicepCm: Double = 0,
        leftThighCm: Double = 0,
        rightThighCm: Double = 0,
        neckCm: Double = 0,
        shouldersCm: Double = 0,
        bodyFatPercent: Double? = nil
    ) {
        self.date = date
        self.chestCm = chestCm
        self.waistCm = waistCm
        self.hipsCm = hipsCm
        self.leftBicepCm = leftBicepCm
        self.rightBicepCm = rightBicepCm
        self.leftThighCm = leftThighCm
        self.rightThighCm = rightThighCm
        self.neckCm = neckCm
        self.shouldersCm = shouldersCm
        self.bodyFatPercent = bodyFatPercent
    }

    var waistToHipRatio: Double? {
        guard hipsCm > 0 else { return nil }
        return waistCm / hipsCm
    }

    /// Returns non-zero measurement entries as label/value pairs
    var nonZeroMeasurements: [(label: String, value: Double)] {
        var result: [(String, Double)] = []
        if chestCm > 0 { result.append(("Poitrine", chestCm)) }
        if shouldersCm > 0 { result.append(("Épaules", shouldersCm)) }
        if neckCm > 0 { result.append(("Cou", neckCm)) }
        if leftBicepCm > 0 { result.append(("Biceps G", leftBicepCm)) }
        if rightBicepCm > 0 { result.append(("Biceps D", rightBicepCm)) }
        if waistCm > 0 { result.append(("Taille", waistCm)) }
        if hipsCm > 0 { result.append(("Hanches", hipsCm)) }
        if leftThighCm > 0 { result.append(("Cuisse G", leftThighCm)) }
        if rightThighCm > 0 { result.append(("Cuisse D", rightThighCm)) }
        return result
    }
}

/// Identifiable wrapper for measurement data points used in charts
struct MeasurementDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String
}
