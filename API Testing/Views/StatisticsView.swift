import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject var storage: StorageService
    
    var statistics: VehicleStatistics {
        VehicleStatistics(vehicles: storage.savedVehicles)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Overview Cards
                        HStack {
                            StatCard(
                                title: "Total Spots",
                                value: "\(storage.savedVehicles.count)",
                                icon: "car.fill"
                            )
                            
                            StatCard(
                                title: "This Month",
                                value: "\(statistics.spotsThisMonth)",
                                icon: "calendar"
                            )
                        }
                        
                        // Performance Stats
                        VStack(spacing: 12) {
                            Text("Performance Records")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack {
                                StatCard(
                                    title: "Highest Power",
                                    value: statistics.highestPower?.power ?? "N/A",
                                    subtitle: statistics.highestPower?.model ?? "",
                                    icon: "bolt.fill"
                                )
                                
                                StatCard(
                                    title: "Top Speed",
                                    value: statistics.highestTopSpeed?.speed ?? "N/A",
                                    subtitle: statistics.highestTopSpeed?.model ?? "",
                                    icon: "speedometer"
                                )
                            }
                            
                            StatCard(
                                title: "Quickest 0-60",
                                value: statistics.quickestZeroToSixty?.time ?? "N/A",
                                subtitle: statistics.quickestZeroToSixty?.model ?? "",
                                icon: "timer"
                            )
                        }
                        
                        // Brand Distribution
                        ChartCard(title: "Popular Brands") {
                            Chart(statistics.brandDistribution) { item in
                                BarMark(
                                    x: .value("Count", item.count),
                                    y: .value("Brand", item.name)
                                )
                                .foregroundStyle(Color.blue.gradient)
                            }
                        }
                        
                        // Color Distribution
                        ChartCard(title: "Popular Colors") {
                            Chart(statistics.colorDistribution) { item in
                                BarMark(
                                    x: .value("Count", item.count),
                                    y: .value("Color", item.name)
                                )
                                .foregroundStyle(Color.purple.gradient)
                            }
                        }
                        
                        // Monthly Activity
                        ChartCard(title: "Monthly Activity") {
                            Chart(statistics.monthlyActivity) { item in
                                LineMark(
                                    x: .value("Month", item.date),
                                    y: .value("Spots", item.count)
                                )
                                .foregroundStyle(Color.green.gradient)
                                .symbol(Circle())
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Statistics")
        }
    }
}

// Supporting Views
struct StatCard: View {
    let title: String
    let value: String
    var subtitle: String = ""
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .foregroundColor(.gray)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
}

struct ChartCard<Content: View>: View {
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
                .frame(height: 200)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
}

// Data Models
struct VehicleStatistics {
    let vehicles: [SavedVehicle]
    
    var spotsThisMonth: Int {
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date()))!
        return vehicles.filter { $0.date >= startOfMonth }.count
    }
    
    var brandDistribution: [StatItem] {
        let distribution = Dictionary(grouping: vehicles) { $0.details.brand ?? "Unknown" }
            .map { StatItem(name: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
        return Array(distribution.prefix(5))
    }
    
    var colorDistribution: [StatItem] {
        let distribution = Dictionary(grouping: vehicles) { $0.details.color ?? "Unknown" }
            .map { StatItem(name: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
        return Array(distribution.prefix(5))
    }
    
    var monthlyActivity: [MonthlyStatItem] {
        let calendar = Calendar.current
        let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: Date())!
        
        let monthlyGroups = Dictionary(grouping: vehicles) { vehicle in
            calendar.startOfMonth(for: vehicle.date)
        }
        
        var items: [MonthlyStatItem] = []
        var currentDate = sixMonthsAgo
        
        while currentDate <= Date() {
            let startOfMonth = calendar.startOfMonth(for: currentDate)
            let count = monthlyGroups[startOfMonth]?.count ?? 0
            items.append(MonthlyStatItem(date: startOfMonth, count: count))
            if let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentDate) {
                currentDate = nextMonth
            } else {
                break
            }
        }
        
        return items
    }
    
    struct PerformanceRecord {
        let model: String
        let power: String
        let speed: String
        let time: String
    }
    
    var highestPower: PerformanceRecord? {
        // Debug print all vehicles and their power values
        for vehicle in vehicles {
            print("Vehicle: \(vehicle.details.brand ?? "") \(vehicle.details.model ?? ""), Power: \(vehicle.details.power ?? "nil")")
        }
        
        let vehicle = vehicles.compactMap { vehicle -> (SavedVehicle, Int)? in
            guard let powerString = vehicle.details.power else { return nil }
            
            // Handle different power formats
            let cleanPower: String
            if powerString.contains("/") {
                // Format: "55 kW / 75 HP / 99 BHP" - take the last value (BHP)
                cleanPower = powerString.components(separatedBy: "/").last?
                    .trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: " BHP", with: "") ?? "0"
            } else {
                // Format: "700 BHP"
                cleanPower = powerString.uppercased()
                    .replacingOccurrences(of: " BHP", with: "")
                    .trimmingCharacters(in: .whitespaces)
            }
            
            guard let powerValue = Int(cleanPower) else { return nil }
            return (vehicle, powerValue)
        }
        .max { $0.1 < $1.1 }
        .map { $0.0 }
        
        guard let vehicle = vehicle,
              let power = vehicle.details.power,
              let brand = vehicle.details.brand,
              let model = vehicle.details.model else { return nil }
        
        return PerformanceRecord(
            model: "\(brand) \(model)",
            power: power,
            speed: vehicle.details.topSpeed ?? "",
            time: vehicle.details.zeroToSixty ?? ""
        )
    }
    
    var highestTopSpeed: PerformanceRecord? {
        let vehicle = vehicles.max { a, b in
            let aSpeed = Int(a.details.topSpeed?.replacingOccurrences(of: " mph", with: "") ?? "0") ?? 0
            let bSpeed = Int(b.details.topSpeed?.replacingOccurrences(of: " mph", with: "") ?? "0") ?? 0
            return aSpeed < bSpeed
        }
        
        guard let vehicle = vehicle,
              let speed = vehicle.details.topSpeed,
              let brand = vehicle.details.brand,
              let model = vehicle.details.model else { return nil }
        
        return PerformanceRecord(
            model: "\(brand) \(model)",
            power: vehicle.details.power ?? "",
            speed: speed,
            time: vehicle.details.zeroToSixty ?? ""
        )
    }
    
    var quickestZeroToSixty: PerformanceRecord? {
        let vehicle = vehicles.min { a, b in
            let aTime = Double(a.details.zeroToSixty?.replacingOccurrences(of: " seconds", with: "") ?? "999") ?? 999
            let bTime = Double(b.details.zeroToSixty?.replacingOccurrences(of: " seconds", with: "") ?? "999") ?? 999
            return aTime < bTime
        }
        
        guard let vehicle = vehicle,
              let time = vehicle.details.zeroToSixty,
              let brand = vehicle.details.brand,
              let model = vehicle.details.model else { return nil }
        
        return PerformanceRecord(
            model: "\(brand) \(model)",
            power: vehicle.details.power ?? "",
            speed: vehicle.details.topSpeed ?? "",
            time: time
        )
    }
}

struct StatItem: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
}

struct MonthlyStatItem: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

// Calendar Extension
extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = self.dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}

#Preview {
    StatisticsView()
        .environmentObject(StorageService())
} 