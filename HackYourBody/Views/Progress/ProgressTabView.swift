import SwiftUI
import SwiftData

enum ProgressSection: String, CaseIterable, Identifiable {
    case photos = "Photos"
    case measurements = "Mensurations"
    case charts = "Graphiques"
    case compare = "Comparer"

    var id: String { rawValue }
}

struct ProgressTabView: View {
    @State private var selectedSection: ProgressSection = .photos
    @State private var showAddPhoto = false
    @State private var showAddMeasurement = false

    @Query(sort: \BodyMeasurement.date, order: .reverse)
    private var measurements: [BodyMeasurement]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented control
                Picker("Section", selection: $selectedSection) {
                    ForEach(ProgressSection.allCases) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                // Content
                switch selectedSection {
                case .photos:
                    PhotoTimelineView()
                case .measurements:
                    MeasurementListView()
                case .charts:
                    MeasurementChartsView()
                case .compare:
                    PhotoCompareView()
                }
            }
            .navigationTitle("Suivi corporel")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showAddPhoto = true
                        } label: {
                            Label("Ajouter une photo", systemImage: "camera.fill")
                        }

                        Button {
                            showAddMeasurement = true
                        } label: {
                            Label("Ajouter des mensurations", systemImage: "ruler")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showAddPhoto) {
                AddPhotoView()
            }
            .sheet(isPresented: $showAddMeasurement) {
                AddMeasurementView(prefill: measurements.first)
            }
        }
    }
}
