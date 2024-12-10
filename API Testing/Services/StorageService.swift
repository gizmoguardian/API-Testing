import Foundation
import SwiftUI

class StorageService: ObservableObject {
    @Published var savedVehicles: [SavedVehicle] = []
    private let saveKey = "SavedVehicles"
    
    init() {
        loadVehicles()
    }
    
    func saveVehicle(plate: String, image: UIImage, videoData: Data? = nil, details: CarCheckData) {
        let imageData = image.jpegData(compressionQuality: 0.8)
        let newImageData = SavedVehicle.ImageData(
            imageData: imageData,
            videoData: videoData,
            date: Date()
        )
        
        // Normalize the plate number for comparison (remove spaces and convert to uppercase)
        let normalizedPlate = plate.replacingOccurrences(of: " ", with: "").uppercased()
        
        // Check if vehicle with this plate already exists
        if let index = savedVehicles.firstIndex(where: { 
            $0.plate.replacingOccurrences(of: " ", with: "").uppercased() == normalizedPlate 
        }) {
            // Update existing vehicle
            var updatedVehicle = savedVehicles[index]
            updatedVehicle.images.insert(newImageData, at: 0)  // Add new image at the start
            savedVehicles[index] = updatedVehicle
            print("Merged with existing vehicle: \(plate)")
        } else {
            // Create new vehicle
            let vehicle = SavedVehicle(
                plate: plate,
                imageData: imageData,
                videoData: videoData,
                details: details
            )
            savedVehicles.append(vehicle)
            print("Created new vehicle: \(plate)")
        }
        
        saveVehicles()
    }
    
    func updateVehicle(_ vehicle: SavedVehicle) {
        if let index = savedVehicles.firstIndex(where: { $0.id == vehicle.id }) {
            savedVehicles[index] = vehicle
            saveVehicles()
        }
    }
    
    func deleteVehicle(_ vehicle: SavedVehicle) {
        savedVehicles.removeAll { $0.id == vehicle.id }
        saveVehicles()
    }
    
    private func saveVehicles() {
        if let encoded = try? JSONEncoder().encode(savedVehicles) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
            print("Saved vehicles count: \(savedVehicles.count)")
        }
    }
    
    private func loadVehicles() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([SavedVehicle].self, from: data) {
            savedVehicles = decoded
            print("Loaded vehicles count: \(savedVehicles.count)")
        }
    }
} 