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
        urlString: String, httpMethod: String = "GET", headers: [String:String] = [:], body: Data? = nil
    ) -> (Error?, String?) {
        guard let url = URL(string: urlString) else {
            return (NSError(domain: "Invalid URL", code: 0, userInfo: nil), nil)
        }
        
        var rData: Data? = nil
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        for (k,v) in headers
        {
            request.setValue(v, forHTTPHeaderField: k)
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        var finished = false
        Task {
            (rData, _) = try await URLSession.shared.data(for: request)
            finished = true
        }
        
        while finished == false {}
        
        if let sData = rData {
            let str = String(data: sData, encoding: .utf8)
            return (nil, str)
        }
        else {
            return (nil, nil)
        }
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
