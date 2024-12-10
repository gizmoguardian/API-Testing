import SwiftUI
import AVKit

struct MediaCarouselView: View {
    let images: [SavedVehicle.ImageData]
    @State private var currentIndex = 0
    @State private var showFullscreen = false
    @State private var selectedTab = 0
    
    var imagesOnly: [SavedVehicle.ImageData] {
        images.filter { $0.imageData != nil }
    }
    
    var videosOnly: [SavedVehicle.ImageData] {
        images.filter { $0.videoData != nil }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Media type selector
            if !imagesOnly.isEmpty || !videosOnly.isEmpty {
                HStack(spacing: 24) {
                    MediaTypeButton(
                        title: "Images",
                        count: imagesOnly.count,
                        isSelected: selectedTab == 0,
                        action: { withAnimation { selectedTab = 0 } }
                    )
                    
                    if !videosOnly.isEmpty {
                        MediaTypeButton(
                            title: "Videos",
                            count: videosOnly.count,
                            isSelected: selectedTab == 1,
                            action: { withAnimation { selectedTab = 1 } }
                        )
                    }
                }
                .padding(.horizontal)
                
                // Media content
                if selectedTab == 0 && !imagesOnly.isEmpty {
                    TabView(selection: $currentIndex) {
                        ForEach(0..<imagesOnly.count, id: \.self) { index in
                            if let imageData = imagesOnly[index].imageData,
                               let uiImage = UIImage(data: imageData) {
                                MediaCard(image: processImage(uiImage), 
                                        date: imagesOnly[index].date) {
                                    showFullscreen = true
                                }
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 350)
                    
                    if imagesOnly.count > 1 {
                        CustomPageIndicator(total: imagesOnly.count, current: currentIndex)
                    }
                } else if selectedTab == 1 && !videosOnly.isEmpty {
                    TabView(selection: $currentIndex) {
                        ForEach(0..<videosOnly.count, id: \.self) { index in
                            if let videoData = videosOnly[index].videoData {
                                VideoCard(videoData: videoData, date: videosOnly[index].date)
                                    .id(index)
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 350)
                    
                    if videosOnly.count > 1 {
                        CustomPageIndicator(total: videosOnly.count, current: currentIndex)
                    }
                }
            } else {
                // Placeholder when no media
                Text("No media available")
                    .foregroundColor(AppTheme.secondaryText)
                    .frame(height: 200)
            }
        }
        .fullScreenCover(isPresented: $showFullscreen) {
            if let imageData = imagesOnly[currentIndex].imageData,
               let uiImage = UIImage(data: imageData) {
                FullscreenImageView(image: uiImage, isPresented: $showFullscreen)
            }
        }
    }
    
    private func processImage(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 1200
        let size = image.size
        
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }
        
        let scale = min(maxDimension/size.width, maxDimension/size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

struct MediaTypeButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                Text("\(count)")
                    .font(.system(.caption, design: .rounded))
            }
            .foregroundColor(isSelected ? .white : AppTheme.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                    .fill(isSelected ? AppTheme.accentBlue : AppTheme.cardBackground)
                    .shadow(color: isSelected ? AppTheme.accentBlue.opacity(0.3) : .clear,
                           radius: isSelected ? 8 : 0)
            )
        }
    }
}

struct MediaCard: View {
    let image: UIImage
    let date: Date
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                .onTapGesture(perform: onTap)
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(AppTheme.accentBlue)
                Text(date.formatted(date: .abbreviated, time: .shortened))
                    .foregroundColor(AppTheme.secondaryText)
                    .font(.caption)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.cardBackground.opacity(AppTheme.glassEffect))
            )
        }
        .padding(.horizontal)
    }
}

struct VideoCard: View {
    let videoData: Data
    let date: Date
    @State private var showFullscreen = false
    
    var body: some View {
        VStack(spacing: 12) {
            VideoPlayerView(videoData: videoData)
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                .onTapGesture {
                    showFullscreen = true
                }
                .onDisappear {
                    // Release video resources when card disappears
                    cleanup()
                }
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(AppTheme.accentBlue)
                Text(date.formatted(date: .abbreviated, time: .shortened))
                    .foregroundColor(AppTheme.secondaryText)
                    .font(.caption)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.cardBackground.opacity(AppTheme.glassEffect))
            )
        }
        .padding(.horizontal)
        .fullScreenCover(isPresented: $showFullscreen) {
            FullscreenVideoView(videoData: videoData, isPresented: $showFullscreen)
        }
    }
    
    private func cleanup() {
        // Clear any temporary files or resources
        NotificationCenter.default.post(
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        // Force UI update
        DispatchQueue.main.async {
            // Reset any UI state if needed
        }
    }
}

struct FullscreenImageView: View {
    let image: UIImage
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .ignoresSafeArea()
                .overlay(alignment: .topTrailing) {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
        }
    }
}

struct FullscreenVideoView: View {
    let videoData: Data
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VideoPlayerView(videoData: videoData, shouldAutoPlay: true)
                .ignoresSafeArea()
            
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
    }
}

struct CustomPageIndicator: View {
    let total: Int
    let current: Int
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(current == index ? AppTheme.accentBlue : AppTheme.secondaryText)
                    .frame(width: current == index ? 20 : 6, height: 6)
                    .animation(.spring(), value: current)
            }
        }
        .padding(.vertical, 8)
    }
}

// Add LazyView to defer loading of content
struct LazyView<Content: View>: View {
    let build: () -> Content
    
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    
    var body: Content {
        build()
    }
} 