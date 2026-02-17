import SwiftUI
import SwiftData

struct PhotoTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ProgressPhoto.date, order: .reverse)
    private var allPhotos: [ProgressPhoto]

    @State private var selectedPoseFilter: PhotoPose?
    @State private var showAddPhoto = false
    @State private var selectedPhoto: ProgressPhoto?

    private var filteredPhotos: [ProgressPhoto] {
        if let filter = selectedPoseFilter {
            return allPhotos.filter { $0.pose == filter }
        }
        return allPhotos
    }

    /// Group photos by month
    private var groupedPhotos: [(key: String, photos: [ProgressPhoto])] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "MMMM yyyy"

        var groups: [String: [ProgressPhoto]] = [:]
        var order: [String] = []

        for photo in filteredPhotos {
            let key = formatter.string(from: photo.date).capitalized
            if groups[key] == nil {
                order.append(key)
            }
            groups[key, default: []].append(photo)
        }

        return order.map { (key: $0, photos: groups[$0]!) }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Pose filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    filterChip(label: "Toutes", isSelected: selectedPoseFilter == nil) {
                        selectedPoseFilter = nil
                    }
                    ForEach(PhotoPose.allCases) { pose in
                        filterChip(label: pose.rawValue, isSelected: selectedPoseFilter == pose) {
                            selectedPoseFilter = pose
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            if filteredPhotos.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "Pas encore de photos",
                    systemImage: "camera.fill",
                    description: Text("Ajoute ta première photo de progression")
                )
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(groupedPhotos, id: \.key) { group in
                            Section {
                                LazyVGrid(columns: columns, spacing: 4) {
                                    ForEach(group.photos) { photo in
                                        photoThumbnail(photo)
                                    }
                                }
                            } header: {
                                Text(group.key)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailSheet(photo: photo)
        }
    }

    // MARK: - Filter Chip

    private func filterChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }

    // MARK: - Photo Thumbnail

    private func photoThumbnail(_ photo: ProgressPhoto) -> some View {
        Button {
            selectedPhoto = photo
        } label: {
            ZStack(alignment: .bottomLeading) {
                if let uiImage = photo.uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                } else {
                    Color.gray.opacity(0.3)
                        .aspectRatio(1, contentMode: .fill)
                }

                // Date label
                Text(photo.date.dayMonth)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(4)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Photo Detail Sheet

struct PhotoDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let photo: ProgressPhoto
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let uiImage = photo.uiImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(radius: 4)
                            .padding(.horizontal)
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label(photo.date.shortFormatted, systemImage: "calendar")
                                .font(.subheadline)
                            Spacer()
                            Label(photo.pose.rawValue, systemImage: photo.pose.icon)
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        }

                        if let weight = photo.bodyWeightKg {
                            Label("\(weight.cleanString) kg", systemImage: "scalemass")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if !photo.notes.isEmpty {
                            Text(photo.notes)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Supprimer", systemImage: "trash")
                            .font(.subheadline)
                    }
                    .padding(.top, 8)
                }
                .padding(.vertical)
            }
            .navigationTitle("Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
            .confirmationDialog("Supprimer cette photo ?", isPresented: $showDeleteConfirm) {
                Button("Supprimer", role: .destructive) {
                    modelContext.delete(photo)
                    dismiss()
                }
                Button("Annuler", role: .cancel) { }
            }
        }
    }
}
