import Foundation
import UIKit

class PlateRecognizerService {
    private let apiKey = "f0baee01a3f03980458a502f1d14848011e112ca"
    private let baseURL = "https://api.platerecognizer.com/v1/plate-reader/"
    private let maxFileSize: Int = 3 * 1024 * 1024 // 3MB in bytes
    
    private func compressImage(_ image: UIImage) -> Data? {
        var compression: CGFloat = 0.8
        var imageData = image.jpegData(compressionQuality: compression)
        
        // Reduce image size if needed
        var currentSize = CGSize(width: image.size.width, height: image.size.height)
        while (imageData?.count ?? 0) > maxFileSize {
            if compression > 0.1 {
                // First try reducing quality
                compression -= 0.1
                imageData = image.jpegData(compressionQuality: compression)
            } else {
                // If quality reduction isn't enough, reduce dimensions
                currentSize = CGSize(
                    width: currentSize.width * 0.7,
                    height: currentSize.height * 0.7
                )
                
                let renderer = UIGraphicsImageRenderer(size: currentSize)
                let resizedImage = renderer.image { context in
                    image.draw(in: CGRect(origin: .zero, size: currentSize))
                }
                
                imageData = resizedImage.jpegData(compressionQuality: 0.7)
            }
            
            // Safety check to prevent infinite loop
            if currentSize.width < 200 || currentSize.height < 200 {
                break
            }
        }
        
        return imageData
    }
    
    func recognizePlate(image: UIImage) async throws -> PlateResponse {
        guard let imageData = compressImage(image) else {
            throw NSError(domain: "ImageCompressionError", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "Failed to compress image to acceptable size"])
        }
        
        print("Image size after compression: \(Double(imageData.count) / 1024 / 1024)MB")
        
        guard let url = URL(string: baseURL) else {
            throw NSError(domain: "URLError", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"upload\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NSError(domain: "NetworkError", code: -1, 
                            userInfo: [NSLocalizedDescriptionKey: "Invalid response type"])
            }
            
            print("Response status code: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response data: \(responseString)")
            }
            
            guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
                throw NSError(domain: "APIError", 
                            code: httpResponse.statusCode,
                            userInfo: [NSLocalizedDescriptionKey: "API returned status code \(httpResponse.statusCode)"])
            }
            
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(PlateResponse.self, from: data)
            } catch {
                print("Decoding error: \(error)")
                throw NSError(domain: "DecodingError",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to decode API response: \(error.localizedDescription)"])
            }
        } catch {
            print("Network error: \(error)")
            throw error
        }
    }
} 