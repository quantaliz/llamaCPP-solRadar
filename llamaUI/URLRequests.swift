//
//  URLRequests.swift
//  llmBridge-solRadar
//
//  Created by Q on 6/10/2024.
//

import Foundation

struct URLRequests
{
    static func performRequest(
        urlString: String, httpMethod: String = "GET", body: Data? = nil
    ) async throws -> (Error?, Data?) {
        guard let url = URL(string: urlString) else {
            return (NSError(domain: "Invalid URL", code: 0, userInfo: nil), nil)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = body
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        return (nil, data)
    }
    
    static func fetchData(from: String) -> Data? {
        let semaphore = DispatchSemaphore(value: 0)
        var fetchedData: Data?
        
        let url = URL(string: from)!
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            fetchedData = data
            semaphore.signal()
        }
        task.resume()
        
        semaphore.wait()
        return fetchedData
    }
}
