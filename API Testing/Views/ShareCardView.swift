import SwiftUI

struct ShareCardView: View {
    let vehicle: SavedVehicle
    @State private var registrationCount: Int?
    @State private var rarityStatus: RarityStatus = .common
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with logo
            SpottedLogo(height: 40)
            
            // Vehicle Image
            if let firstImage = vehicle.images.first?.imageData,
               let uiImage = UIImage(data: firstImage) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Vehicle Details
            VStack(alignment: .leading, spacing: 12) {
                // Title with rarity badge
                HStack {
                    if let brand = vehicle.details.brand,
                       let model = vehicle.details.model {
                        Text("\(brand) \(model)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    RarityBadge(status: rarityStatus)
                }
                
                // Registration count
                if let count = registrationCount {
                    Text("Only \(count) registered in UK")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Performance stats
                HStack(spacing: 20) {
                    if let power = vehicle.details.power {
                        StatLabel(icon: "bolt.fill", value: power)
                    }
                    if let topSpeed = vehicle.details.topSpeed {
                        StatLabel(icon: "speedometer", value: topSpeed)
                    }
                    if let zeroToSixty = vehicle.details.zeroToSixty {
                        StatLabel(icon: "timer", value: zeroToSixty)
                    }
                }
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // Share options
                HStack(spacing: 16) {
                    ShareButton(title: "Instagram", icon: "camera.fill", color: .purple) {
                        // Share to Instagram
                    }
                    
                    ShareButton(title: "Twitter", icon: "message.fill", color: .blue) {
                        // Share to Twitter
                    }
                    
                    ShareButton(title: "Save", icon: "square.and.arrow.down", color: .green) {
                        // Save to photos
                    }
                }
            }
            .padding()
            
            // Footer
            Text("Spotted on \(vehicle.date.formatted())")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.black)
        .cornerRadius(16)
        .onAppear {
            loadRegistrationData()
        }
    }
    
    private func loadRegistrationData() {
        registrationCount = VehicleRegistrationService.shared.getRegistrationCount(
            brand: vehicle.details.brand,
            model: vehicle.details.model
        )
        
        if let count = registrationCount {
            rarityStatus = VehicleRegistrationService.shared.getRarityStatus(count: count)
        }
    }
}

struct RarityBadge: View {
    let status: RarityStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
            Text(status.rawValue)
        }
        .font(.caption)
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color)
        .cornerRadius(8)
    }
}

struct ShareButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color)
            .cornerRadius(8)
        }
    }
}

struct StatLabel: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(value)
                .foregroundColor(.white)
        }
    }
} 