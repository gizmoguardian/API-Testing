import SwiftUI

struct SavedVehicleDetailView: View {
    @EnvironmentObject var storage: StorageService
    @Environment(\.dismiss) var dismiss
    @State private var vehicle: SavedVehicle
    @State private var isEditingPlate = false
    @State private var editedPlate = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingShareSheet = false
    @State private var shareImage: UIImage?
    @State private var showingAdvancedDetails = false
    
    private let carCheckService = CarCheckScraperService()
    
    init(vehicle: SavedVehicle) {
        _vehicle = State(initialValue: vehicle)
        _editedPlate = State(initialValue: vehicle.plate)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Media Carousel
                    MediaCarouselView(images: vehicle.images)
                        .background(AppTheme.cardBackground)
                        .cornerRadius(AppTheme.cardRadius)
                        .padding(.horizontal)
                    
                    // Vehicle Details Card
                    VStack(alignment: .leading, spacing: 16) {
                        // Plate Number Section
                        HStack {
                            Text("Plate: \(vehicle.plate)")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            
                            Button(action: {
                                isEditingPlate = true
                                editedPlate = vehicle.plate
                            }) {
                                Image(systemName: "pencil.circle")
                                    .foregroundColor(AppTheme.accentBlue)
                                    .font(.title3)
                            }
                        }
                        
                        if isEditingPlate {
                            VStack(spacing: 12) {
                                TextField("Enter plate number", text: $editedPlate)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.allCharacters)
                                
                                HStack {
                                    Button("Update") {
                                        Task {
                                            await updatePlate()
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(editedPlate.isEmpty)
                                    
                                    Button("Cancel") {
                                        isEditingPlate = false
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .padding()
                            .background(AppTheme.cardBackground)
                            .cornerRadius(AppTheme.cardRadius)
                        }
                        
                        if isLoading {
                            ProgressView()
                                .tint(AppTheme.accentBlue)
                        }
                        
                        if let errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        Divider()
                            .background(AppTheme.divider)
                        
                        // Vehicle Details
                        VStack(spacing: 16) {
                            Group {
                                detailRow(title: "Make", value: vehicle.details.brand)
                                detailRow(title: "Model", value: vehicle.details.model)
                                detailRow(title: "Color", value: vehicle.details.color)
                                detailRow(title: "Year", value: vehicle.details.year)
                            }
                            
                            DisclosureGroup {
                                VStack(spacing: 12) {
                                    detailRow(title: "Engine", value: vehicle.details.engineSize)
                                    detailRow(title: "Cylinders", value: vehicle.details.cylinders)
                                    detailRow(title: "Fuel", value: vehicle.details.fuelType)
                                    detailRow(title: "Power", value: vehicle.details.power)
                                    detailRow(title: "Top Speed", value: vehicle.details.topSpeed)
                                    detailRow(title: "0-60 mph", value: vehicle.details.zeroToSixty)
                                    detailRow(title: "MOT Status", value: vehicle.details.motStatus)
                                    detailRow(title: "Tax Status", value: vehicle.details.taxStatus)
                                }
                                .padding(.top, 8)
                            } label: {
                                Text("Additional Details")
                                    .foregroundColor(AppTheme.accentBlue)
                                    .font(.headline)
                            }
                        }
                    }
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.cardRadius)
                    .shadow(color: Color.black.opacity(0.2), radius: 10)
                    .padding(.horizontal)
                    
                    Button(action: {
                        showingAdvancedDetails = true
                    }) {
                        HStack {
                            Image(systemName: "chart.bar.doc.horizontal")
                            Text("Advanced Details")
                        }
                        .foregroundColor(AppTheme.accentBlue)
                        .padding()
                        .background(AppTheme.cardBackground)
                        .cornerRadius(AppTheme.cardRadius)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [AppTheme.gradientStart, AppTheme.gradientEnd]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("\(vehicle.details.brand ?? "") \(vehicle.details.model ?? "")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: prepareShare) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let image = shareImage {
                    ShareSheet(items: [image])
                }
            }
            .sheet(isPresented: $showingAdvancedDetails) {
                NavigationStack {
                    AdvancedVehicleDetailsView(vehicle: vehicle)
                }
            }
        }
    }
    
    private func detailRow(title: String, value: String?) -> some View {
        if let value = value {
            return HStack {
                Text(title + ":")
                    .foregroundColor(AppTheme.secondaryText)
                    .fontWeight(.medium)
                Spacer()
                Text(value)
                    .foregroundColor(.white)
            }
        } else {
            return EmptyView()
        }
    }
    
    private func updatePlate() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let newDetails = try await carCheckService.getVehicleDetails(plate: editedPlate)
            let updatedVehicle = SavedVehicle(
                id: vehicle.id,
                date: vehicle.date,
                plate: editedPlate,
                images: vehicle.images,
                details: newDetails
            )
            
            storage.updateVehicle(updatedVehicle)
            vehicle = updatedVehicle
            isEditingPlate = false
        } catch {
            errorMessage = "Error updating vehicle details: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func prepareShare() {
        let renderer = ImageRenderer(content: ShareCardView(vehicle: vehicle))
        renderer.scale = UIScreen.main.scale
        
        if let image = renderer.uiImage {
            shareImage = image
            showingShareSheet = true
        }
    }
}

// Share Sheet using UIKit's activity view controller
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 