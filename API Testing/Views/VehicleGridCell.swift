import SwiftUI

struct VehicleGridCell: View {
    let vehicle: SavedVehicle
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Vehicle Image
            if let firstImage = vehicle.images.first,
               let imageData = firstImage.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(isHovered ? 0.5 : 0),
                                  lineWidth: 2)
                    )
            } else {
                Image(systemName: "car.fill")
                    .font(.system(size: 40))
                    .frame(height: 160)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Vehicle Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(vehicle.plate)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if vehicle.details.isRare {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
                
                if let brand = vehicle.details.brand,
                   let model = vehicle.details.model {
                    Text("\(brand) \(model)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Text(vehicle.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 4)
        }
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .shadow(color: .blue.opacity(isHovered ? 0.3 : 0), radius: 10)
        .animation(.spring(response: 0.3), value: isHovered)
        .onHover { isHovered = $0 }
    }
}

#Preview {
    VehicleGridCell(vehicle: SavedVehicle(
        id: UUID(),
        date: Date(),
        plate: "ABC123",
        images: [],
        details: CarCheckData(
            brand: "BMW",
            model: "M3",
            color: "Black",
            year: "2023",
            engineSize: nil,
            cylinders: nil,
            fuelType: nil,
            motStatus: nil,
            taxStatus: nil,
            power: nil,
            topSpeed: nil,
            zeroToSixty: nil
        )
    ))
} 