//
//  UIImage.swift
//  VehicleTrackingDemo
//
//  Created by 黄 康平 on 8/16/17.
//  Copyright © 2017 黄 康平. All rights reserved.
//

import UIKit

extension UIImage {
    func alpha(_ value:CGFloat)->UIImage
    {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: CGPoint.zero, blendMode: .normal, alpha: value)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
        
    }
}

