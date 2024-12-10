import Foundation

struct PlateResponse: Codable {
    let results: [PlateResult]
    let timestamp: String
    let version: Int
    let camera_id: String?
    
    var bestMatch: PlateResult? {
        results.max(by: { $0.score < $1.score })
    }
}

struct PlateResult: Codable {
    let box: Box
    let plate: String
    let region: Region
    let vehicle: Vehicle
    let score: Double
}

struct Box: Codable {
    let xmin: Int
    let ymin: Int
    let xmax: Int
    let ymax: Int
}

struct Region: Codable {
    let code: String
    let score: Double
}

struct Vehicle: Codable {
    let type: String
    let score: Double
    let box: Box
} 