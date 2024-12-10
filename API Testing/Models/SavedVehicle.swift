import Foundation
import UIKit

struct SavedVehicle: Identifiable, Codable {
    let id: UUID
    let date: Date
    let plate: String
    var images: [ImageData]
    let details: CarCheckData
    
    struct ImageData: Codable {
        let imageData: Data?
        let videoData: Data?
        let date: Date
    }
    
    init(id: UUID = UUID(), date: Date = Date(), plate: String, images: [ImageData], details: CarCheckData) {
        self.id = id
        self.date = date
        self.plate = plate
        self.images = images
        self.details = details
    }
    
    init(id: UUID = UUID(), date: Date = Date(), plate: String, imageData: Data?, videoData: Data? = nil, details: CarCheckData) {
        self.id = id
        self.date = date
        self.plate = plate
        self.images = [ImageData(imageData: imageData, videoData: videoData, date: date)]
        self.details = details
    }
} 
