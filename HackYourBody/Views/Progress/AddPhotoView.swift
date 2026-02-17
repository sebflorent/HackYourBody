import SwiftUI
import PhotosUI

struct AddPhotoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var pose: PhotoPose = .front
    @State private var notes = ""
    @State private var bodyWeight: String = ""
    @State private var showCamera = false
    @State private var sourceChoice: ImageSourceChoice?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Image preview / picker
                    imageSection

                    // Pose selector
                    poseSection

                    // Optional fields
                    optionalFieldsSection

                    // Save button
                    if selectedImage != nil {
                        Button {
                            savePhoto()
                        } label: {
                            Text("Enregistrer la photo")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Nouvelle photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") { dismiss() }
                }
            }
            .confirmationDialog("Source de la photo", isPresented: .init(
                get: { sourceChoice != nil },
                set: { if !$0 { sourceChoice = nil } }
            )) {
                Button("Appareil photo") {
                    showCamera = true
                    sourceChoice = nil
                }
                Button("Galerie photo") {
                    sourceChoice = .gallery
                }
                Button("Annuler", role: .cancel) {
                    sourceChoice = nil
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView(image: $selectedImage)
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Image Section

    private var imageSection: some View {
        Group {
            if let image = selectedImage {
                VStack(spacing: 12) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 4)

                    Button("Changer la photo") {
                        sourceChoice = .choosing
                    }
                    .font(.subheadline)
                }
                .padding(.horizontal)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)

                    Text("Prends une photo de ta progression")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        Button {
                            showCamera = true
                        } label: {
                            Label("Appareil", systemImage: "camera.fill")
                                .font(.subheadline)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }

                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Label("Galerie", systemImage: "photo.on.rectangle")
                                .font(.subheadline)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color(.secondarySystemBackground))
                                .foregroundStyle(.primary)
                                .clipShape(Capsule())
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 250)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                }
            }
        }
    }

    // MARK: - Pose Section

    private var poseSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pose")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(PhotoPose.allCases) { p in
                    Button {
                        pose = p
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: p.icon)
                                .font(.title2)
                            Text(p.rawValue)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(pose == p ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
                        .foregroundStyle(pose == p ? Color.accentColor : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(pose == p ? Color.accentColor : .clear, lineWidth: 2)
                        )
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Optional Fields

    private var optionalFieldsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Détails (optionnel)")
                .font(.headline)

            HStack {
                Image(systemName: "scalemass")
                    .foregroundStyle(.secondary)
                TextField("Poids du jour (kg)", text: $bodyWeight)
                    .keyboardType(.decimalPad)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            HStack(alignment: .top) {
                Image(systemName: "note.text")
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
                TextField("Notes...", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
    }

    // MARK: - Save

    private func savePhoto() {
        guard let image = selectedImage,
              let data = ProgressPhoto.compressImage(image) else { return }

        let weight = Double(bodyWeight.replacingOccurrences(of: ",", with: "."))

        let photo = ProgressPhoto(
            date: .now,
            imageData: data,
            pose: pose,
            notes: notes,
            bodyWeightKg: weight
        )

        modelContext.insert(photo)
        dismiss()
    }
}

// MARK: - Helper Enum

enum ImageSourceChoice {
    case choosing
    case gallery
}

// MARK: - Camera View (UIImagePickerController wrapper)

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraDevice = .front
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
