import Foundation
import SwiftSoup

class CarCheckScraperService {
    func getVehicleDetails(plate: String) async throws -> CarCheckData {
        let cleanPlate = plate.replacingOccurrences(of: " ", with: "").uppercased()
        let urlString = "https://www.carcheck.co.uk/check/\(cleanPlate)"
        
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "URLError", code: -1)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("en-GB,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        
        print("Requesting URL: \(urlString)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Response status code: \(httpResponse.statusCode)")
        }
        
        let html = String(data: data, encoding: .utf8) ?? ""
        let doc = try SwiftSoup.parse(html)
        
        // Get vehicle info from the first table
        let make = try? doc.select("tr:contains(Make) td").first()?.text().trimmingCharacters(in: .whitespacesAndNewlines)
        let model = try? doc.select("tr:contains(Model) td").first()?.text().trimmingCharacters(in: .whitespacesAndNewlines)
        let color = try? doc.select("tr:contains(Colour) td").first()?.text().trimmingCharacters(in: .whitespacesAndNewlines)
        let year = try? doc.select("tr:contains(Year of manufacture) td").first()?.text().trimmingCharacters(in: .whitespacesAndNewlines)
        let engineSize = try? doc.select("tr:contains(Engine capacity) td").first()?.text().trimmingCharacters(in: .whitespacesAndNewlines)
        let cylinders = try? doc.select("tr:contains(Cylinders) td").first()?.text().trimmingCharacters(in: .whitespacesAndNewlines)
        let fuelType = try? doc.select("tr:contains(Fuel type) td").first()?.text().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Get MOT and tax status
        let motStatus = try? doc.select("div.block-result:contains(MOT)").first()?.text().trimmingCharacters(in: .whitespacesAndNewlines)
        let taxStatus = try? doc.select("div.block-result:contains(Tax)").first()?.text().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Get performance data
        let power = try? doc.select("tr:contains(Power) td").first()?.text().trimmingCharacters(in: .whitespacesAndNewlines)
        let topSpeed = try? doc.select("tr:contains(Top speed) td").first()?.text().trimmingCharacters(in: .whitespacesAndNewlines)
        let zeroToSixty = try? doc.select("tr:contains(0 - 60 mph) td").first()?.text().trimmingCharacters(in: .whitespacesAndNewlines)
        
        return CarCheckData(
            brand: make,
            model: model,
            color: color,
            year: year,
            engineSize: engineSize,
            cylinders: cylinders,
            fuelType: fuelType,
            motStatus: motStatus,
            taxStatus: taxStatus,
            power: power,
            topSpeed: topSpeed,
            zeroToSixty: zeroToSixty
        )
    }
} 