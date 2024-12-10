import SwiftUI

struct AdvancedVehicleDetailsView: View {
    let vehicle: SavedVehicle
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Performance Section
                DetailSection(title: "Performance") {
                    DetailGrid {
                        if let power = vehicle.details.power {
                            DetailItem(title: "Power", value: power, icon: "bolt.fill")
                        }
                        if let topSpeed = vehicle.details.topSpeed {
                            DetailItem(title: "Top Speed", value: topSpeed, icon: "speedometer")
                        }
                        if let zeroToSixty = vehicle.details.zeroToSixty {
                            DetailItem(title: "0-60", value: zeroToSixty, icon: "timer")
                        }
                        if let engineSize = vehicle.details.engineSize {
                            DetailItem(title: "Engine", value: engineSize, icon: "engine")
                        }
                    }
                }
                
                // Technical Section
                DetailSection(title: "Technical") {
                    DetailGrid {
                        if let cylinders = vehicle.details.cylinders {
                            DetailItem(title: "Cylinders", value: cylinders, icon: "circle.grid.3x3.fill")
                        }
                        if let fuelType = vehicle.details.fuelType {
                            DetailItem(title: "Fuel Type", value: fuelType, icon: "fuelpump.fill")
                        }
                    }
                }
                
                // Status Section
                DetailSection(title: "Vehicle Status") {
                    DetailGrid {
                        if let motStatus = vehicle.details.motStatus {
                            DetailItem(
                                title: "MOT",
                                value: motStatus,
                                icon: "checkmark.seal.fill",
                                color: motStatus.contains("Valid") ? .green : .red
                            )
                        }
                        if let taxStatus = vehicle.details.taxStatus {
                            DetailItem(
                                title: "Tax",
                                value: taxStatus,
                                icon: "doc.text.fill",
                                color: taxStatus.contains("Valid") ? .green : .red
                            )
                        }
                    }
                }
                
                // Market Value Estimation
                DetailSection(title: "Market Analysis") {
                    VStack(alignment: .leading, spacing: 12) {
                        MarketValueRow(title: "Estimated Value", value: calculateEstimatedValue())
                        MarketValueRow(title: "Market Trend", value: "↗️ Appreciating", subtitle: "Based on recent sales")
                        MarketValueRow(title: "Rarity", value: "Uncommon", subtitle: "Less than 1000 registered in UK")
                    }
                }
            }
            .padding()
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .navigationTitle("Advanced Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func calculateEstimatedValue() -> String {
        // This is a placeholder for actual value calculation logic
        // You could implement real market value estimation here
        return "£25,000 - £30,000"
    }
}

// Supporting Views
struct DetailSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            content
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
}

struct DetailGrid<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            content
        }
    }
}

struct DetailItem: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = .blue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .foregroundColor(.gray)
            }
            .font(.subheadline)
            
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MarketValueRow: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .foregroundColor(.gray)
                .font(.subheadline)
            
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    NavigationView {
        AdvancedVehicleDetailsView(vehicle: SavedVehicle(
            id: UUID(),
            date: Date(),
            plate: "ABC123",
            images: [],
            details: CarCheckData(
                brand: "BMW",
                model: "M3",
                color: "Black",
                year: "2023",
                engineSize: "3.0L",
                cylinders: "6",
                fuelType: "Petrol",
                motStatus: "Valid until Dec 2024",
                taxStatus: "Valid until Mar 2024",
                power: "510 bhp",
                topSpeed: "155 mph",
                zeroToSixty: "3.8 seconds"
            )
        ))
    }
} 