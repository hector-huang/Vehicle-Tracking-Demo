//
//  FloatingPoint.swift
//  VehicleTrackingDemo
//
//  Created by 黄 康平 on 8/24/17.
//  Copyright © 2017 黄 康平. All rights reserved.
//

import Foundation

extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}

extension Int {
    var degreesToRadians: Double { return Double(self) * .pi / 180 }
}
