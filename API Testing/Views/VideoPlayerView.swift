import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let videoData: Data
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var error: Error?
    let shouldAutoPlay: Bool
    @State private var tempURL: URL?
    
    // Add maximum video size (e.g., 100MB)
    private let maxVideoSize: Int = 100 * 1024 * 1024 // 100MB
    
    init(videoData: Data, shouldAutoPlay: Bool = false) {
        if videoData.count > maxVideoSize {
            print("Warning: Video size exceeds recommended maximum")
        }
        self.videoData = videoData
        self.shouldAutoPlay = shouldAutoPlay
        print("VideoPlayerView initialized with \(videoData.count) bytes")
    }
    
    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        if shouldAutoPlay {
                            player.play()
                        }
                    }
            } else if let error = error {
                VStack {
                    Image(systemName: "video.slash")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text("Failed to load video")
                        .foregroundColor(.red)
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            } else if isLoading {
                ProgressView()
                    .tint(AppTheme.accentBlue)
            }
        }
        .onAppear {
            print("VideoPlayerView appeared")
            setupPlayer()
        }
        .onDisappear {
            print("VideoPlayerView disappeared")
            cleanup()
        }
    }
    
    private func setupPlayer() {
        isLoading = true
        error = nil
        
        Task {
            do {
                // Create a unique temporary URL
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("mov")
                
                print("Writing video to temp URL: \(tempURL.path)")
                try videoData.write(to: tempURL)
                self.tempURL = tempURL
                
                // Create asset and check if it's playable
                let asset = AVAsset(url: tempURL)
                
                // Load asset properties
                let keys = ["playable"]
                try await asset.load(.isPlayable)
                
                if asset.isPlayable {
                    print("Asset is playable")
                    let playerItem = AVPlayerItem(asset: asset)
                    let newPlayer = AVPlayer(playerItem: playerItem)
                    newPlayer.isMuted = !shouldAutoPlay
                    
                    await MainActor.run {
                        self.player = newPlayer
                        self.isLoading = false
                        print("Player setup complete")
                    }
                } else {
                    throw NSError(domain: "VideoPlayerError", 
                                code: -1, 
                                userInfo: [NSLocalizedDescriptionKey: "Asset is not playable"])
                }
            } catch {
                print("Error setting up video: \(error.localizedDescription)")
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
    
    private func cleanup() {
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
        
        // Clean up temporary file
        if let tempURL = tempURL {
            try? FileManager.default.removeItem(at: tempURL)
            self.tempURL = nil
        }
    }
} 