//
//  Event.swift
//  VehicleTrackingDemo
//
//  Created by 黄 康平 on 8/16/17.
//  Copyright © 2017 黄 康平. All rights reserved.
//

import Foundation

public struct Event {
    
    public let type: String
    public let time: Int
    public let location: (latitude: Double, longitude: Double)
    
    public init?(json: [String: Any]) {
        guard let type = json["etp"] as? String,
            let time = json["tim"] as? Int,
            let latitude = json["lat"] as? Double,
            let longitude = json["lon"] as? Double
            else {
                return nil
        }
        self.type = type
        self.time = time
        self.location = (latitude, longitude)
    }
}
