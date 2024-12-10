//
//  ContentView.swift
//  API Testing
//
//  Created by Ryan Service on 09/12/2024.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var plateResponse: PlateResponse?
    @State private var carDetails: CarCheckData?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var manualPlate: String = ""
    @State private var isEditingPlate: Bool = false
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    private let plateService = PlateRecognizerService()
    private let carCheckService = CarCheckScraperService()
    @EnvironmentObject var storage: StorageService
    
    private func resetState() {
        selectedItem = nil
        selectedImage = nil
        plateResponse = nil
        carDetails = nil
        manualPlate = ""
        isEditingPlate = false
        errorMessage = nil
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                }
                
                HStack(spacing: 20) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Upload Image", systemImage: "square.and.arrow.up")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button {
                        showCamera = true
                    } label: {
                        Label("Take Photo", systemImage: "camera")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                
                if isLoading {
                    ProgressView()
                }
                
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
                
                if let bestMatch = plateResponse?.bestMatch {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Plate: \(bestMatch.plate)")
                                .font(.headline)
                            Button(action: {
                                manualPlate = bestMatch.plate
                                isEditingPlate = true
                            }) {
                                Image(systemName: "pencil.circle")
                                    .foregroundColor(.blue)
                            }
                        }
                        Text("Confidence: \(Int(bestMatch.score * 100))%")
                        
                        if isEditingPlate {
                            HStack {
                                TextField("Enter plate number", text: $manualPlate)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.allCharacters)
                                
                                Button("Update") {
                                    Task {
                                        isEditingPlate = false
                                        await refreshCarDetails(plate: manualPlate)
                                    }
                                }
                                .disabled(manualPlate.isEmpty)
                                .buttonStyle(.bordered)
                            }
                        }
                        
                        if let carData = carDetails {
                            Divider()
                            Group {
                                if let brand = carData.brand {
                                    Text("Make: \(brand)")
                                }
                                if let model = carData.model {
                                    Text("Model: \(model)")
                                }
                                if let color = carData.color {
                                    Text("Color: \(color)")
                                }
                                if let year = carData.year {
                                    Text("Year: \(year)")
                                }
                                if let engineSize = carData.engineSize {
                                    Text("Engine: \(engineSize)")
                                }
                                if let cylinders = carData.cylinders {
                                    Text("Cylinders: \(cylinders)")
                                }
                                if let fuelType = carData.fuelType {
                                    Text("Fuel: \(fuelType)")
                                }
                                if let power = carData.power {
                                    Text("Power: \(power)")
                                }
                                if let topSpeed = carData.topSpeed {
                                    Text("Top Speed: \(topSpeed)")
                                }
                                if let zeroToSixty = carData.zeroToSixty {
                                    Text("0-60 mph: \(zeroToSixty)")
                                }
                                if let motStatus = carData.motStatus {
                                    Text("MOT Status: \(motStatus)")
                                }
                                if let taxStatus = carData.taxStatus {
                                    Text("Tax Status: \(taxStatus)")
                                }
                            }
                            .font(.subheadline)
                            
                            Button("Save Vehicle") {
                                storage.saveVehicle(
                                    plate: isEditingPlate ? manualPlate : bestMatch.plate,
                                    image: selectedImage,
                                    details: carData
                                )
                                resetState()
                            }
                            .buttonStyle(.bordered)
                            .padding(.top)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $selectedImage, sourceType: .camera)
                .ignoresSafeArea()
                .onDisappear {
                    if selectedImage != nil {
                        Task {
                            await loadTransferrable()
                        }
                    }
                }
        }
    }
    
    private func loadTransferrable() async {
        do {
            guard let data = try await selectedItem?.loadTransferable(type: Data.self) else {
                errorMessage = "Failed to load image data"
                return
            }
            
            guard let image = UIImage(data: data) else {
                errorMessage = "Failed to create image from data"
                return
            }
            
            selectedImage = image
            isLoading = true
            errorMessage = nil
            
            do {
                plateResponse = try await plateService.recognizePlate(image: image)
                
                // Only fetch details for the plate with highest confidence
                if let bestPlate = plateResponse?.bestMatch {
                    print("Using plate with confidence: \(bestPlate.score): \(bestPlate.plate)")
                    do {
                        carDetails = try await carCheckService.getVehicleDetails(plate: bestPlate.plate)
                    } catch {
                        print("Car Check Error: \(error)")
                        errorMessage = "Error fetching vehicle details: \(error.localizedDescription)"
                    }
                }
            } catch {
                print("API Error: \(error)")
                errorMessage = "Error recognizing plate: \(error.localizedDescription)"
            }
        } catch {
            print("Image Loading Error: \(error)")
            errorMessage = "Error loading image: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func refreshCarDetails(plate: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            carDetails = try await carCheckService.getVehicleDetails(plate: plate)
        } catch {
            print("Car Check Error: \(error)")
            errorMessage = "Error fetching vehicle details: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

#Preview {
    ContentView()
}
