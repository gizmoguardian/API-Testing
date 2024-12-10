//
//  ContentView.swift
//  API Testing
//
//  Created by Ryan Service on 09/12/2024.
//

import SwiftUI
import PhotosUI
import Photos

struct ContentView: View {
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [(UIImage, PlateResponse?, CarCheckData?)] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingSaveAllAnimation = false
    @State private var selectedVideoURL: URL?
    @State private var showingVideoPicker = false
    
    private let plateService = PlateRecognizerService()
    private let carCheckService = CarCheckScraperService()
    @EnvironmentObject var storage: StorageService
    private let videoProcessor = VideoProcessingService()
    
    private var hasProcessedImages: Bool {
        !selectedImages.isEmpty && selectedImages.contains { $0.1?.bestMatch != nil && $0.2 != nil }
    }
    
    private func resetState() {
        selectedItems.removeAll()
        selectedImages.removeAll()
        errorMessage = nil
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // App Logo/Title
                VStack {
                    Text("Spotted")
                        .font(.title.bold())
                    Image("spotted-logo")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
                .padding(.top)
                
                if selectedImages.isEmpty {
                    // Placeholder when no images selected
                    VStack {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(.blue.opacity(0.8))
                        Text("Select images to scan")
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 200)
                } else {
                    // Display selected images in a grid
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                        ForEach(selectedImages.indices, id: \.self) { index in
                            VStack {
                                Image(uiImage: selectedImages[index].0)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 150)
                                    .cornerRadius(8)
                                
                                if let plateResponse = selectedImages[index].1?.bestMatch {
                                    Text(plateResponse.plate)
                                        .font(.caption)
                                        .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                HStack(spacing: 12) {
                    PhotosPicker(
                        selection: $selectedItems,
                        matching: .images
                    ) {
                        Label("Select Images", systemImage: "photo.stack.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button {
                        showingVideoPicker = true
                    } label: {
                        Label("Add Video", systemImage: "video.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .sheet(isPresented: $showingVideoPicker) {
                    VideoPickerView(selectedURL: $selectedVideoURL)
                }
                
                if hasProcessedImages {
                    Button {
                        saveAllVehicles()
                    } label: {
                        Label("Save All", systemImage: "square.and.arrow.down.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                if isLoading {
                    ProgressView()
                        .padding(.vertical, 8)
                }
                
                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .padding(.vertical, 4)
                }
                
                // Results section
                ForEach(selectedImages.indices, id: \.self) { index in
                    if let plateResponse = selectedImages[index].1,
                       let bestMatch = plateResponse.bestMatch {
                        PlateResultView(
                            image: selectedImages[index].0,
                            plateResult: bestMatch,
                            carDetails: selectedImages[index].2,
                            videoURL: selectedVideoURL,
                            onSave: { plate, details, videoData in
                                storage.saveVehicle(
                                    plate: plate,
                                    image: selectedImages[index].0,
                                    videoData: videoData,
                                    details: details
                                )
                                // Remove this item from the array
                                selectedImages.remove(at: index)
                            }
                        )
                        .padding()
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .onChange(of: selectedItems) { oldValue, newValue in
            Task {
                await loadTransferrables()
            }
        }
        .onChange(of: selectedVideoURL) { oldValue, newValue in
            if let url = newValue {
                Task {
                    do {
                        let frames = try await videoProcessor.extractFrames(from: url)
                        await processVideoFrames(frames)
                    } catch {
                        print("Error processing video: \(error)")
                        errorMessage = "Error processing video: \(error.localizedDescription)"
                    }
                }
            }
        }
        .overlay {
            if showingSaveAllAnimation {
                CarSaveAnimation(isShowing: $showingSaveAllAnimation) {
                    showingSaveAllAnimation = false
                }
            }
        }
    }
    
    private func loadTransferrables() async {
        isLoading = true
        errorMessage = nil
        selectedImages.removeAll()
        
        for item in selectedItems {
            do {
                if item.supportedContentTypes.contains(.movie) || item.supportedContentTypes.contains(.video) {
                    // Try loading as movie first
                    do {
                        if let movieURL = try await item.loadTransferable(type: URL.self) {
                            selectedVideoURL = movieURL
                            // Extract frames from video
                            let frames = try await videoProcessor.extractFrames(from: movieURL)
                            await processVideoFrames(frames)
                        } else {
                            // Fallback to loading as data
                            if let videoData = try await item.loadTransferable(type: Data.self) {
                                let tempURL = FileManager.default.temporaryDirectory
                                    .appendingPathComponent(UUID().uuidString)
                                    .appendingPathExtension("mov")
                                
                                try videoData.write(to: tempURL)
                                selectedVideoURL = tempURL
                                let frames = try await videoProcessor.extractFrames(from: tempURL)
                                await processVideoFrames(frames)
                            }
                        }
                    } catch {
                        print("Error processing video: \(error)")
                        errorMessage = "Error processing video: \(error.localizedDescription)"
                    }
                } else {
                    // Handle images as before
                    guard let data = try await item.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else {
                        continue
                    }
                    await processImage(image)
                }
            } catch {
                print("Error processing media: \(error)")
                errorMessage = "Error processing one or more items: \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
    
    private func processVideoFrames(_ frames: [UIImage]) async {
        // Process each frame
        for frame in frames {
            selectedImages.append((frame, nil, nil))
            
            do {
                let plateResponse = try await plateService.recognizePlate(image: frame)
                
                if let index = selectedImages.firstIndex(where: { $0.0 == frame }) {
                    selectedImages[index].1 = plateResponse
                    
                    if let bestPlate = plateResponse.bestMatch {
                        do {
                            let carDetails = try await carCheckService.getVehicleDetails(plate: bestPlate.plate)
                            selectedImages[index].2 = carDetails
                        } catch {
                            print("Car Check Error for frame: \(error)")
                        }
                    }
                }
            } catch {
                print("Error processing frame: \(error)")
            }
        }
        
        // Keep only the frame with highest confidence
        if let bestFrame = selectedImages
            .compactMap({ ($0, $0.1?.bestMatch?.score ?? 0.0) })
            .max(by: { $0.1 < $1.1 })?.0 {
            selectedImages = [bestFrame]
        }
    }
    
    private func processImage(_ image: UIImage) async {
        selectedImages.append((image, nil, nil))
        
        do {
            let plateResponse = try await plateService.recognizePlate(image: image)
            
            if let index = selectedImages.firstIndex(where: { $0.0 == image }) {
                selectedImages[index].1 = plateResponse
                
                if let bestPlate = plateResponse.bestMatch {
                    do {
                        let carDetails = try await carCheckService.getVehicleDetails(plate: bestPlate.plate)
                        selectedImages[index].2 = carDetails
                    } catch {
                        print("Car Check Error: \(error)")
                    }
                }
            }
        } catch {
            print("Error processing image: \(error)")
        }
    }
    
    private func saveAllVehicles() {
        for (image, plateResponse, carDetails) in selectedImages {
            if let bestMatch = plateResponse?.bestMatch,
               let details = carDetails {
                let videoData = selectedVideoURL.flatMap { try? Data(contentsOf: $0) }
                
                storage.saveVehicle(
                    plate: bestMatch.plate,
                    image: image,
                    videoData: videoData,
                    details: details
                )
            }
        }
        showingSaveAllAnimation = true
        // Clear everything
        selectedImages.removeAll()
        selectedItems.removeAll()
        selectedVideoURL = nil
    }
}

// New view to handle individual plate results
struct PlateResultView: View {
    let image: UIImage
    let plateResult: PlateResult
    let carDetails: CarCheckData?
    let videoURL: URL?
    let onSave: (String, CarCheckData, Data?) -> Void
    
    @State private var isEditingPlate = false
    @State private var manualPlate: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSaveAnimation = false
    
    private let carCheckService = CarCheckScraperService()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 8) {
                    if isEditingPlate {
                        TextField("Enter plate", text: $manualPlate)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 120)
                        
                        HStack {
                            Button("Save") {
                                Task {
                                    await updatePlate()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("Cancel") {
                                isEditingPlate = false
                                manualPlate = plateResult.plate
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        HStack {
                            Text(plateResult.plate)
                                .font(.title2)
                                .bold()
                            
                            Button {
                                manualPlate = plateResult.plate
                                isEditingPlate = true
                            } label: {
                                Image(systemName: "pencil.circle")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    Text("Confidence: \(Int(plateResult.score * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let carDetails = carDetails {
                    Button {
                        let videoData = videoURL.flatMap { try? Data(contentsOf: $0) }
                        onSave(
                            manualPlate.isEmpty ? plateResult.plate : manualPlate,
                            carDetails,
                            videoData
                        )
                        showSaveAnimation = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            if let carDetails = carDetails {
                VStack(alignment: .leading, spacing: 8) {
                    if let make = carDetails.brand {
                        Text("Make: \(make)")
                    }
                    if let model = carDetails.model {
                        Text("Model: \(model)")
                    }
                    if let year = carDetails.year {
                        Text("Year: \(year)")
                    }
                    if let color = carDetails.color {
                        Text("Color: \(color)")
                    }
                    
                    // Additional details in an expandable section
                    DisclosureGroup("More Details") {
                        VStack(alignment: .leading, spacing: 4) {
                            if let engineSize = carDetails.engineSize {
                                Text("Engine: \(engineSize)")
                            }
                            if let fuelType = carDetails.fuelType {
                                Text("Fuel: \(fuelType)")
                            }
                            if let motStatus = carDetails.motStatus {
                                Text("MOT: \(motStatus)")
                            }
                            if let taxStatus = carDetails.taxStatus {
                                Text("Tax: \(taxStatus)")
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                }
            } else if isLoading {
                ProgressView()
                    .padding(.vertical, 4)
            }
            
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .overlay {
            if showSaveAnimation {
                CarSaveAnimation(isShowing: $showSaveAnimation) {
                    showSaveAnimation = false
                }
            }
        }
    }
    
    private func updatePlate() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let newDetails = try await carCheckService.getVehicleDetails(plate: manualPlate)
            let videoData = videoURL.flatMap { try? Data(contentsOf: $0) }
            onSave(manualPlate, newDetails, videoData)
            isEditingPlate = false
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

#Preview {
    ContentView()
}
