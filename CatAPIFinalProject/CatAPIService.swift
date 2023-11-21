//
//  CatAPIService.swift
//  CatAPIFinalProject
//
//  Created by Jason Angel on 11/20/23.
//

import Foundation
import UIKit

class CatAPIService {
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    func getSearchImages(completion: @escaping (Result<[SearchImagesData], Error>) -> Void) {
        let url = CatAPI.searchURL
        
        var request = URLRequest(url: url)
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(CatAPI.apiKey, forHTTPHeaderField: "x-api-key")
        
        let task = session.dataTask(with: request) {
            (data, response, error) in
            
            let result = self.processGetSearchImagesResult(data: data, error: error)
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        task.resume()
    }
    
    private func processGetSearchImagesResult(data: Data?, error: Error?) -> Result<[SearchImagesData], Error> {
        guard let jsonData = data else {
            return .failure(error!)
        }
        
        return CatAPI.searchImages(fromJSON: jsonData)
    }
}
