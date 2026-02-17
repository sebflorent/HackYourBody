import SwiftUI
import SwiftData

struct PhotoCompareView: View {
    @Query(sort: \ProgressPhoto.date, order: .reverse)
    private var allPhotos: [ProgressPhoto]

    @State private var beforePhoto: ProgressPhoto?
    @State private var afterPhoto: ProgressPhoto?
    @State private var selectedPose: PhotoPose = .front
    @State private var showBeforePicker = false
    @State private var showAfterPicker = false

    private var photosForPose: [ProgressPhoto] {
        allPhotos.filter { $0.pose == selectedPose }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Pose selector
            Picker("Pose", selection: $selectedPose) {
                ForEach(PhotoPose.allCases) { pose in
                    Text(pose.rawValue).tag(pose)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: selectedPose) { _, _ in
                autoSelectPhotos()
            }

            if photosForPose.count < 2 {
                Spacer()
                ContentUnavailableView(
                    "Pas assez de photos",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text("Il faut au moins 2 photos en pose \"\(selectedPose.rawValue)\" pour comparer")
                )
                Spacer()
            } else {
                // Comparison
                GeometryReader { geo in
                    HStack(spacing: 4) {
                        // Before
                        photoColumn(
                            title: "Avant",
                            photo: beforePhoto,
                            width: (geo.size.width - 4) / 2
                        ) {
                            showBeforePicker = true
                        }

                        // After
                        photoColumn(
                            title: "Après",
                            photo: afterPhoto,
                            width: (geo.size.width - 4) / 2
                        ) {
                            showAfterPicker = true
                        }
                    }
                }
                .padding(.horizontal)

                // Delta info
                if let before = beforePhoto, let after = afterPhoto,
                   let wBefore = before.bodyWeightKg, let wAfter = after.bodyWeightKg {
                    let delta = wAfter - wBefore
                    HStack {
                        Image(systemName: "scalemass")
                            .foregroundStyle(.secondary)
                        Text("Poids: \(wBefore.cleanString) kg -> \(wAfter.cleanString) kg")
                            .font(.subheadline)
                        Text("(\(delta >= 0 ? "+" : "")\(delta.cleanString) kg)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(delta <= 0 ? .green : .orange)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                if let before = beforePhoto, let after = afterPhoto {
                    let days = after.date.daysFrom(start: before.date)
                    Text("\(days) jours d'écart")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical)
        .onAppear { autoSelectPhotos() }
        .sheet(isPresented: $showBeforePicker) {
            PhotoPickerSheet(photos: photosForPose, selected: $beforePhoto, title: "Photo Avant")
        }
        .sheet(isPresented: $showAfterPicker) {
            PhotoPickerSheet(photos: photosForPose, selected: $afterPhoto, title: "Photo Après")
        }
    }

    // MARK: - Photo Column

    private func photoColumn(title: String, photo: ProgressPhoto?, width: CGFloat, onTap: @escaping () -> Void) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)

            Button(action: onTap) {
                if let photo, let uiImage = photo.uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: width * 1.4)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: width, height: width * 1.4)
                        .overlay {
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.title)
                                    .foregroundStyle(.secondary)
                                Text("Sélectionner")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                }
            }

            if let photo {
                Text(photo.date.shortFormatted)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Auto-select

    private func autoSelectPhotos() {
        let photos = photosForPose
        if photos.count >= 2 {
            afterPhoto = photos.first // most recent (query sorted desc)
            beforePhoto = photos.last // oldest
        } else {
            beforePhoto = nil
            afterPhoto = nil
        }
    }
}

// MARK: - Photo Picker Sheet

struct PhotoPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let photos: [ProgressPhoto]
    @Binding var selected: ProgressPhoto?
    let title: String

    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(photos) { photo in
                        Button {
                            selected = photo
                            dismiss()
                        } label: {
                            ZStack {
                                if let uiImage = photo.uiImage {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(minWidth: 0, maxWidth: .infinity)
                                        .aspectRatio(1, contentMode: .fill)
                                        .clipped()
                                }

                                if selected?.id == photo.id {
                                    Color.blue.opacity(0.3)
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay {
                                VStack {
                                    Spacer()
                                    Text(photo.date.dayMonth)
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Capsule())
                                        .padding(4)
                                }
                            }
                        }
                    }
                }
                .padding(4)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}
