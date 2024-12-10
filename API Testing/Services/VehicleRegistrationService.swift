import Foundation
import SwiftUI

class VehicleRegistrationService {
    static let shared = VehicleRegistrationService()
    
    // This would ideally come from an API, but for now we'll use sample data
    private let registrationData: [String: Int] = [
        "BMW M3": 892,
        "BMW M4": 743,
        "Porsche 911": 1243,
        "Ferrari 488": 156,
        "Lamborghini Huracan": 89,
        "Audi RS6": 1567,
        "Mercedes AMG GT": 423,
        "Aston Martin DB11": 234,
        "McLaren 720S": 98,
        // Add more models as needed
    ]
    
    func getRegistrationCount(brand: String?, model: String?) -> Int? {
        guard let brand = brand, let model = model else { return nil }
        return registrationData["\(brand) \(model)"]
    }
    
    func getRarityStatus(count: Int) -> RarityStatus {
        switch count {
        case 0...100: return .ultraRare
        case 101...500: return .veryRare
        case 501...1000: return .rare
        default: return .common
        }
    }
}

enum RarityStatus: String {
    case common = "Common"
    case rare = "Rare"
    case veryRare = "Very Rare"
    case ultraRare = "Ultra Rare"
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .veryRare: return .purple
        case .ultraRare: return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .common: return "car.fill"
        case .rare: return "star.fill"
        case .veryRare: return "stars.fill"
        case .ultraRare: return "crown.fill"
        }
    }
} 