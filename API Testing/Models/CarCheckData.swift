import Foundation

struct CarCheckData: Codable {
    let brand: String?
    let model: String?
    let color: String?
    let year: String?
    let engineSize: String?
    let cylinders: String?
    let fuelType: String?
    let motStatus: String?
    let taxStatus: String?
    let power: String?
    let topSpeed: String?
    let zeroToSixty: String?
}

extension CarCheckData {
    var isRare: Bool {
        // Define criteria for rarity. For example:
        if let power = power,
           let powerValue = Int(power.replacingOccurrences(of: " bhp", with: "")),
           powerValue >= 400 {
            return true
        }
        
        if let topSpeed = topSpeed,
           let speedValue = Int(topSpeed.replacingOccurrences(of: " mph", with: "")),
           speedValue >= 155 {
            return true
        }
        
        if let zeroToSixty = zeroToSixty,
           let accelerationValue = Double(zeroToSixty.replacingOccurrences(of: " seconds", with: "")),
           accelerationValue <= 4.0 {
            return true
        }
        
        return false
    }
} 