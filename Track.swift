//
//  Track.swift
//  VehicleTrackingDemo
//
//  Created by 黄 康平 on 8/16/17.
//  Copyright © 2017 黄 康平. All rights reserved.
//

import Foundation

public struct Track {
    
    public let location: (latitude: Double, longitude: Double)
    public let heading: Int
    public let time: Int
    
    public init?(json: [String: Any]) {
        guard let latitude = json["lat"] as? Double,
            let longitude = json["lon"] as? Double,
            let heading = json["ghd"] as? Int,
            let time = json["tim"] as? Int
            else {
                return nil
        }
        self.location = (latitude, longitude)
        self.heading = heading
        self.time = time
    }
}

