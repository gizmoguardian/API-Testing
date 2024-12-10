import SwiftUI

struct MainTabView: View {
    @StateObject private var storage = StorageService()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView()
                .environmentObject(storage)
                .tabItem {
                    Label("Spot", systemImage: "camera.fill")
                }
                .tag(0)
            
            HistoryView()
                .environmentObject(storage)
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(1)
            
            StatisticsView()
                .environmentObject(storage)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(2)
        }
        .onChange(of: selectedTab) { _ in
            HapticManager.shared.impact(style: .light)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainTabView()
} 