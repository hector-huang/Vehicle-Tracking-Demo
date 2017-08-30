//
//  VehicleTrackingDemoTests.swift
//  VehicleTrackingDemoTests
//
//  Created by 黄 康平 on 8/16/17.
//  Copyright © 2017 黄 康平. All rights reserved.
//

import XCTest
@testable import VehicleTrackingDemo

class VehicleTrackingDemoTests: XCTestCase {
    
    let viewController = ViewController()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTimeToString() {
        let time = 192930
        
        XCTAssertEqual("19:29", viewController.timeToString(time: time))
    }
    
    func testImageTailored() {
        XCTAssertEqual(#imageLiteral(resourceName: "home").size, viewController.imageWithImage(image: #imageLiteral(resourceName: "car"), scaledToSize: CGSize(width: 64, height: 64)).size)
    }
    
}
