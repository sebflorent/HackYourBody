import Foundation
import SwiftData
import UIKit

enum PhotoPose: String, Codable, CaseIterable, Identifiable {
    case front = "Face"
    case side = "Profil"
    case back = "Dos"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .front: return "person.fill"
        case .side: return "person.fill.turn.right"
        case .back: return "person.fill.turn.left"
        }
    }
}

@Model
final class ProgressPhoto {
    var date: Date
    @Attribute(.externalStorage) var imageData: Data
    var pose: PhotoPose
    var notes: String
    var bodyWeightKg: Double?

    init(
        date: Date = .now,
        imageData: Data,
        pose: PhotoPose = .front,
        notes: String = "",
        bodyWeightKg: Double? = nil
    ) {
        self.date = date
        self.imageData = imageData
        self.pose = pose
        self.notes = notes
        self.bodyWeightKg = bodyWeightKg
    }

    var uiImage: UIImage? {
        UIImage(data: imageData)
    }

    /// Compress an image to JPEG data with target max size ~500KB
    static func compressImage(_ image: UIImage, maxSizeKB: Int = 500) -> Data? {
        var compression: CGFloat = 0.8
        var data = image.jpegData(compressionQuality: compression)

        while let d = data, d.count > maxSizeKB * 1024, compression > 0.1 {
            compression -= 0.1
            data = image.jpegData(compressionQuality: compression)
        }

        return data
    }
}
