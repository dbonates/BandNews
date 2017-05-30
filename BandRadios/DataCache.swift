//
//  DataCache.swift
//  BandRadios
//
//  Created by Daniel Bonates on 27/03/17.
//  Copyright © 2017 Daniel Bonates. All rights reserved.
//

import Foundation

final class DataCache {
    
    let cacheBasePath = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    
    func cachePathFor(_ url: URL, sufix: String = "") -> URL {
        if !sufix.isEmpty {
            return cacheBasePath.appendingPathComponent(url.lastPathComponent + "-\(sufix)")
        }
        return cacheBasePath.appendingPathComponent(url.lastPathComponent)
    }
    
    func getResource(for url: URL, completion: @escaping ([Station]?) -> ()) {
        
        let localURL = cachePathFor(url)
        let shouldLoadLocal = FileManager.default.fileExists(atPath: localURL.path)
        
        let loadURL = shouldLoadLocal ? localURL : url
        
        let sr = stationsResource(from: loadURL, isLocal: shouldLoadLocal)
        
        if shouldLoadLocal {
            DataService().loadLocal(resource: sr, completion: { stations in
                completion(stations)
            })
        } else {
            DataService().load(resource: sr, completion: { stations in
                completion(stations)
            })
        }
        
    }
    
    func stationsResource(from url: URL, isLocal: Bool = true) -> Resource<[Station]> {
    
        let stationsResource = Resource<[Station]>(url: url, parse: { data in
            
            do {
                let localURL = self.cachePathFor(url)
                if !isLocal {
                    try data.write  (to: localURL)
                }
                
                let newData = try Data(contentsOf: localURL)
                
                if let json = try JSONSerialization.jsonObject(with: newData, options: .allowFragments) as? [String: Any] {
                    
                    return (self.stations(from: json))
                    
                }
            } catch let error {
                print(error.localizedDescription)
            }
            
            return nil
        })
        
        return stationsResource
    }
    
    func getStreamInfo(for url: URL, id: Int, completion: @escaping (StreamInfo?) -> ()) {
        
        let localURL = cachePathFor(url, sufix: "\(id)")
        let shouldLoadLocal = FileManager.default.fileExists(atPath: localURL.path)
        
        let loadURL = shouldLoadLocal ? localURL : url
        
        let sr = streamInfoResource(from: loadURL, id: id, isLocal: shouldLoadLocal)
        
        if shouldLoadLocal {
            DataService().loadLocal(resource: sr, completion: { stationInfo in
                completion(stationInfo)
            })
        } else {
            DataService().load(resource: sr, completion: { stationInfo in
                completion(stationInfo)
            })
        }
        
    }
    
    func streamInfoResource(from url: URL, id: Int, isLocal: Bool = true) -> Resource<StreamInfo> {
        
        let stationInfoResource = Resource<StreamInfo>(url: url, parse: { data in
            
            do {
                let localURL = self.cachePathFor(url, sufix: "\(id)")
                if !isLocal {
                    try data.write(to: localURL)
                }
                
                let newData = try Data(contentsOf: localURL)
                
                if let json = try JSONSerialization.jsonObject(with: newData, options: .allowFragments) as? [String: Any] {
                    
                    guard
                        let resultDataJson = json["resultData"] as? [String: Any]
                        else { return nil }
                    
                    return (StreamInfo(from: resultDataJson))
                    
                }
            } catch let error {
                print(error.localizedDescription)
            }
            
            return nil
        })
        
        return stationInfoResource
    }
    
    
    func stations(from json: [String: Any]) -> [Station]? {
        guard
            let resultDataJson = json["resultData"] as? [String: Any],
            let dataJson = resultDataJson["data"] as? [[String: Any]]
        else { return nil }
        
        return dataJson.flatMap(Station.init)
    }
    
    // clear the cache
    func clearCache() {
        do {
            let stationsSourcePath = cacheBasePath.appendingPathComponent("retrieve-radio-list").path
            if FileManager.default.fileExists(atPath: stationsSourcePath) {
                try FileManager.default.removeItem(atPath: stationsSourcePath)
            }
            
        } catch let error as NSError {
            print("Could not clear temp folder: \(error.debugDescription)")
        }
    }
}

