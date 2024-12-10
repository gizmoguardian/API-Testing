import SwiftUI

// Move enum outside of HistoryView
enum VehicleFilter: String, CaseIterable {
    case all = "All"
    case lastWeek = "Last Week"
    case lastMonth = "Last Month"
    case byBrand = "By Brand"
    case rare = "Rare Cars"
}

struct HistoryView: View {
    @EnvironmentObject var storage: StorageService
    @State private var isGridView = false
    @State private var searchText = ""
    @State private var selectedFilter: VehicleFilter = .all
    @State private var showingFilterSheet = false
    @State private var showingShareSheet = false
    @State private var shareImage: UIImage?
    @State private var selectedVehicle: SavedVehicle?
    
    private let gridColumns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var filteredVehicles: [SavedVehicle] {
        let filtered = storage.savedVehicles.filter { vehicle in
            if searchText.isEmpty { return true }
            return vehicle.plate.lowercased().contains(searchText.lowercased()) ||
                   (vehicle.details.brand?.lowercased().contains(searchText.lowercased()) ?? false) ||
                   (vehicle.details.model?.lowercased().contains(searchText.lowercased()) ?? false)
        }
        
        switch selectedFilter {
        case .all:
            return filtered
        case .lastWeek:
            let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            return filtered.filter { $0.date >= oneWeekAgo }
        case .lastMonth:
            let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
            return filtered.filter { $0.date >= oneMonthAgo }
        case .byBrand:
            return filtered.sorted { ($0.details.brand ?? "") < ($1.details.brand ?? "") }
        case .rare:
            return filtered.filter { $0.details.isRare }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Search and Filter Bar
                    HStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Search", text: $searchText)
                                .foregroundColor(.white)
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        
                        Button(action: { showingFilterSheet = true }) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .foregroundColor(.white)
                        }
                        
                        Button(action: { isGridView.toggle() }) {
                            Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    
                    // Content view (Grid or List)
                    Group {
                        if isGridView {
                            ScrollView {
                                LazyVGrid(columns: gridColumns, spacing: 16) {
                                    ForEach(filteredVehicles) { vehicle in
                                        NavigationLink(destination: SavedVehicleDetailView(vehicle: vehicle)) {
                                            VehicleGridCell(vehicle: vehicle)
                                        }
                                        .contextMenu {
                                            Button(action: { prepareShare(vehicle) }) {
                                                Label("Share", systemImage: "square.and.arrow.up")
                                            }
                                            
                                            Button(role: .destructive) {
                                                storage.deleteVehicle(vehicle)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                        .transition(.scale.combined(with: .opacity))
                                    }
                                }
                                .padding()
                            }
                            .refreshable {
                                try? await Task.sleep(nanoseconds: 1_000_000_000)
                            }
                        } else {
                            List {
                                ForEach(filteredVehicles) { vehicle in
                                    NavigationLink(destination: SavedVehicleDetailView(vehicle: vehicle)) {
                                        VehicleRowView(vehicle: vehicle)
                                    }
                                    .listRowBackground(Color.black)
                                }
                                .onDelete(perform: deleteVehicles)
                            }
                            .listStyle(.plain)
                        }
                    }
                    .animation(.spring(), value: isGridView)
                }
            }
            .navigationTitle("History")
            .sheet(isPresented: $showingFilterSheet) {
                FilterView(selectedFilter: $selectedFilter)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let image = shareImage {
                    ShareSheet(items: [image])
                }
            }
        }
    }
    
    private func deleteVehicles(at offsets: IndexSet) {
        HapticManager.shared.notification(type: .success)
        for index in offsets {
            storage.deleteVehicle(storage.savedVehicles[index])
        }
    }
    
    private func prepareShare(_ vehicle: SavedVehicle) {
        HapticManager.shared.impact(style: .medium)
        selectedVehicle = vehicle
        let renderer = ImageRenderer(content: ShareCardView(vehicle: vehicle))
        renderer.scale = UIScreen.main.scale
        
        if let image = renderer.uiImage {
            shareImage = image
            showingShareSheet = true
        }
    }
}

// Separate view for the row to reduce complexity
struct VehicleRowView: View {
    let vehicle: SavedVehicle
    
    var body: some View {
        HStack(spacing: 12) {
            // Show first image if available
            if let firstImage = vehicle.images.first,
               let imageData = firstImage.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "car.fill")
                    .font(.system(size: 30))
                    .frame(width: 60, height: 60)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(vehicle.plate)
                        .font(.headline)
                    
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
                        .foregroundColor(.secondary)
                }
                
                Text(vehicle.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Show number of images if more than 1
            if vehicle.images.count > 1 {
                Text("\(vehicle.images.count) images")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// Filter Sheet View
struct FilterView: View {
    @Binding var selectedFilter: VehicleFilter
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(VehicleFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        selectedFilter = filter
                        dismiss()
                    }) {
                        HStack {
                            Text(filter.rawValue)
                            Spacer()
                            if selectedFilter == filter {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(StorageService())
} 