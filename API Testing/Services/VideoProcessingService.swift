import AVFoundation
import UIKit

class VideoProcessingService {
    enum VideoError: Error {
        case failedToLoadAsset
        case failedToExtractFrames
        case invalidDuration
    }
    
    func extractFrames(from videoURL: URL) async throws -> [UIImage] {
        let asset = AVAsset(url: videoURL)
        
        // Get video duration
        guard let duration = try? await asset.load(.duration) else {
            throw VideoError.invalidDuration
        }
        
        let durationSeconds = CMTimeGetSeconds(duration)
        
        // Calculate timestamps for beginning, middle, and end
        let timestamps = [
            CMTime.zero,  // Start
            CMTime(seconds: durationSeconds / 2, preferredTimescale: 600),  // Middle
            CMTime(seconds: durationSeconds, preferredTimescale: 600)  // End
        ]
        
        // Create AVAssetImageGenerator
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        
        // Extract frames
        var frames: [UIImage] = []
        
        for timestamp in timestamps {
            do {
                let cgImage = try await generator.image(at: timestamp).image
                let image = UIImage(cgImage: cgImage)
                frames.append(image)
            } catch {
                print("Failed to extract frame at \(timestamp): \(error)")
                // Continue with other frames even if one fails
            }
        }
        
        guard !frames.isEmpty else {
            throw VideoError.failedToExtractFrames
        }
        
        return frames
    }
} 