//
//  ViewController.swift
//  VehicleTrackingDemo
//
//  Created by 黄 康平 on 8/16/17.
//  Copyright © 2017 黄 康平. All rights reserved.
//

import UIKit
import GoogleMaps
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, GMSMapViewDelegate, KASlideShowDelegate, KASlideShowDataSource, MKDropdownMenuDelegate, MKDropdownMenuDataSource {
    
    @IBOutlet weak var infoView: UIScrollView!
    @IBOutlet weak var distanceImage: UIImageView!
    @IBOutlet weak var eventImage: UIImageView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var eventLabel: UILabel!
    @IBOutlet weak var distanceView: UIView!
    @IBOutlet weak var eventView: UIView!
    @IBOutlet weak var slideShow: KASlideShow!
    @IBOutlet weak var camera: UIButton!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var play: UIButton!
    @IBOutlet weak var stop: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dropdownMenu: MKDropdownMenu!
    
    let selectedVehicles = ["Hector", "Dave", "Gary"]
    let sampleEventJson = "SampleRecords"
    let sampleTrackJson = "SampleTracks"
    let mainUrl = "http://120.146.195.80:100"           //Url that stores the event image in its subdirectory
    var mapView: GMSMapView!
    let movingMarker = GMSMarker()
    var eventMarkers = [GMSMarker()]
    var urlSource = [NSURL()]
    
    let standardImageSize = CGRect(x: 10, y: UIImage().size.height+1, width: 25, height: 25)
    let standardLabelSize = CGRect(x: 40, y: UIImage().size.height+1, width:50, height: 25)
    var totalDistance: Int! = 0
    var selectedEventTime: Int!                         //the time of selected event by the user
    var selectedVehicleId =  "00004"                    //demo vehicle's identity
    var trackPositions = [Int: (CLLocationCoordinate2D, Int)]() //Dictionary that stores vehicles' positions and headings
    var eventPositions = [Int: (CLLocationCoordinate2D, String)]() //Dictionary that stores events' postions and types
    var tapSomewhere: Bool!                             //To check whether user taps the screen to interrupt the animation

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAllViews()                     //set up all the layout of every element
        initializeMapView()                 //simulate the track of the vehicle in the map
        updateEvent(events: eventPositions) //add every event marker to the map
        distanceViewTapped()                //tap the distance-info icon by default
    }
    
    fileprivate func setupAllViews(){
        setupInfoView()
        setupDistanceView()
        setupEventView()
        setupCameraButton()
        movingMarker.icon = self.imageWithImage(image: #imageLiteral(resourceName: "car"), scaledToSize: CGSize(width: 35, height: 17))
    }
    
    fileprivate func setupInfoView(){
        titleLabel.frame = CGRect(x: 0.5*self.view.frame.width-75, y: 28, width: 150, height: 30)
        infoView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 90)
        dropdownMenu.frame = CGRect(x: self.view.frame.width-100, y: 28, width: 90, height: 30)
        let settingImage = #imageLiteral(resourceName: "setting").resizedImageWithinRect(rectSize: CGSize(width: 30, height: 30))
        dropdownMenu.disclosureIndicatorImage = settingImage
        dropdownMenu.delegate = self
        dropdownMenu.dataSource = self
        dropdownMenu.backgroundDimmingOpacity = 0
    }
    
    fileprivate func setupDistanceView(){
        distanceView.frame = CGRect(x: 10, y: 60, width: 90, height: 27)
        distanceImage.frame = standardImageSize
        distanceLabel.frame = standardLabelSize
        distanceView.layer.cornerRadius = 13.5
        distanceView.layer.masksToBounds = true
        distanceLabel.text = "0 km"
        
        let distanceViewGesture = UITapGestureRecognizer(target: self, action:  #selector (self.distanceTapped(_:)))
        distanceView.addGestureRecognizer(distanceViewGesture)
    }
    
    fileprivate func setupEventView(){
        eventView.frame = CGRect(x: 105, y:60, width: 100, height: 27)
        eventImage.frame = standardImageSize
        eventLabel.frame = standardLabelSize
        eventView.layer.cornerRadius = 13.5
        eventView.layer.masksToBounds = true
        eventLabel.text = "5 events"
        
        let eventViewGesture = UITapGestureRecognizer(target: self, action:  #selector (self.eventTapped(_:)))
        eventView.addGestureRecognizer(eventViewGesture)
    }
    
    fileprivate func initializeMapView(){
        setupTrackPositions()                                                   //get all the positions and their time
        if trackPositions.isEmpty != true{
            let sortedTrackPositions = trackPositions.sorted{ $0.key < $1.key } //sort position dictionary by time
            drawAllPath(positions: sortedTrackPositions)                        //draw all the paths between positions
            eventMarkers.removeAll()
            setEventMarker(position: (sortedTrackPositions.first?.value.0)!, time: (sortedTrackPositions.first?.key)!, type: "Start", icon: #imageLiteral(resourceName: "home"))                                          //mark the start position of the track, which happens at the earliest time during the day
            animateMoveMarkers(positions: sortedTrackPositions)
        }
        
        self.view.addSubview(mapView)
        mapView.delegate = self
        self.view.bringSubview(toFront: infoView)
        self.view.bringSubview(toFront: camera)
    }
    
    fileprivate func setupCameraButton(){
        camera.frame = CGRect(x: 0.5*view.frame.width-20, y: 0.4*view.frame.height+0.75*self.view.frame.width, width: 50, height: 50)
        camera.layer.cornerRadius = camera.bounds.size.height / 2
        camera.layer.borderWidth = 1.5
        camera.layer.borderColor = UIColor.black.cgColor
        camera.addTarget(self, action: #selector(cameraTapped(_:)), for: .touchUpInside)
    }
    
    func numberOfComponents(in dropdownMenu: MKDropdownMenu) -> Int {
        return 1
    }
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let attributedString = NSAttributedString(string: selectedVehicles[row], attributes: [NSForegroundColorAttributeName: UIColor.black])
        return attributedString
    }
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, didSelectRow row: Int, inComponent component: Int) {
        titleLabel.text = "\(selectedVehicles[row])'s Track"
        dropdownMenu.closeAllComponents(animated: true)
    }
    
    func dropdownMenu(_ dropdownMenu: MKDropdownMenu, numberOfRowsInComponent component: Int) -> Int {
        return selectedVehicles.count
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        camera.isHidden = true
        tapSomewhere = true
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        //If user taps at the event marker, the camera button shows at the bottom for retrieving the event images from the server. Otherwise only shows the time of the marker.
        tapSomewhere = true
        mapView.selectedMarker = marker
        if let type = marker.snippet{
            if type != "Start"{
                camera.isHidden = false
                selectedEventTime = marker.userData as! Int!
                self.view.bringSubview(toFront: camera)
            }
        }
        return true
    }

    
    func distanceTapped(_ sender:UITapGestureRecognizer){
        //Deal with color change and animation event
        distanceViewTapped()
        eventViewUntapped()
    }
    
    func eventTapped(_ sender:UITapGestureRecognizer){
        eventViewTapped()
        distanceViewUntapped()
    }
    
    func distanceViewTapped(){
        distanceView.backgroundColor = UIColor.darkGray
        distanceImage.image = #imageLiteral(resourceName: "cartrackTapped")
        distanceLabel.textColor = UIColor(hex: "F1F8E9")
        mapView.animate(toZoom: 12)
    }
    
    func eventViewTapped(){
        eventView.backgroundColor = UIColor.darkGray
        eventImage.image = #imageLiteral(resourceName: "careventTapped")
        eventLabel.textColor = UIColor(hex: "F1F8E9")
        print(eventMarkers)
        animateEventMarkers(markers: eventMarkers.sorted(by: {$0.userData as! Int! < $1.userData as! Int!}))
    }
    
    func distanceViewUntapped(){
        distanceView.backgroundColor = UIColor.clear
        distanceImage.image = #imageLiteral(resourceName: "cartrack")
        distanceLabel.textColor = UIColor.darkGray
    }
    
    func eventViewUntapped(){
        eventView.backgroundColor = UIColor.clear
        eventImage.image = #imageLiteral(resourceName: "carevent")
        eventLabel.textColor = UIColor.darkGray
        mapView.selectedMarker = nil
    }
    
    func setupTrackPositions(){
        var events = [Int: (CLLocationCoordinate2D, String)]()
        var tracks = [Int: (CLLocationCoordinate2D, Int)]()
        let bundle = Bundle.main
        let eventFilePath = bundle.url(forResource: sampleEventJson, withExtension: "json")
        let eventData = try? Data(contentsOf: eventFilePath!)
        let eventJson = JSON(data: eventData!)
        let eventValues = eventJson["values"].arrayObject
        
        for eventValue in eventValues!{
            let event = Event(json: eventValue as! [String : Any])
            if event?.location.latitude != 0 {
                events[(event?.time)!] = (CLLocationCoordinate2D(latitude: (event?.location.latitude)!, longitude: (event?.location.longitude)!), (event?.type)!)
            }
        }
        eventPositions = events
        
        let trackFilePath = bundle.url(forResource: sampleTrackJson, withExtension: "json")
        let trackData = try? Data(contentsOf: trackFilePath!)
        let trackJson = JSON(data: trackData!)
        let trackValues = trackJson["values"].arrayObject
        
        for trackValue in trackValues!{
            let track = Track(json: trackValue as! [String : Any])
            if track?.location.latitude != 0 {
                tracks[(track?.time)!] = (CLLocationCoordinate2D(latitude: (track?.location.latitude)!, longitude: (track?.location.longitude)!), (track?.heading)!)
            }
        }
        trackPositions = tracks
    }
    
    func setMarker(position: CLLocationCoordinate2D, heading: Int, time: Int){
        let marker = GMSMarker()
        marker.icon = imageWithImage(image: #imageLiteral(resourceName: "car"), scaledToSize: CGSize(width: 17.5, height: 8.5)).alpha(0.3)
        marker.position = position
        marker.title = timeToString(time: time)
        marker.rotation = CDouble(heading+90)
        marker.groundAnchor = CGPoint(x: CGFloat(0.5), y: CGFloat(0.5))
        marker.map = mapView
    }
    
    func drawAllPath(positions: [(key: Int, value: (CLLocationCoordinate2D, Int))]){
        //draw every path between two positions and loop, and "drawPath" function specifies the drawing method for each path
        var twoPositions = [CLLocationCoordinate2D?](repeating: nil, count: 2)
        for position in positions{
            setMarker(position: position.value.0, heading: position.value.1, time: position.key)
            if twoPositions[1] == nil{
                let camera = GMSCameraPosition.camera(withLatitude: position.value.0.latitude, longitude: position.value.0.longitude, zoom: 12.0)
                mapView = GMSMapView.map(withFrame: CGRect.init(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height), camera: camera)
                twoPositions[1] = CLLocationCoordinate2D(latitude: position.value.0.latitude, longitude: position.value.0.longitude)
            }
            else{
                twoPositions[0] = twoPositions[1]
                twoPositions[1] = CLLocationCoordinate2D(latitude: position.value.0.latitude, longitude: position.value.0.longitude)
                if position.key > 120000{
                    //if afternoon, the path will be orange
                    drawPath(position1: twoPositions[0]!, position2: twoPositions[1]!, lineColor: UIColor(hex: "FD8C08"))
                }
                else{
                    drawPath(position1: twoPositions[0]!, position2: twoPositions[1]!)
                }
            }
        }
    }
    
    func setEventMarker(position: CLLocationCoordinate2D, time: Int, type: String, icon: UIImage){
        let marker = GMSMarker()
        if icon == #imageLiteral(resourceName: "geofence") || icon == #imageLiteral(resourceName: "home"){
            marker.icon = imageWithImage(image: icon, scaledToSize: CGSize(width: 50, height:50))
        }else{
            marker.icon = imageWithImage(image: icon, scaledToSize: CGSize(width: 20, height:20))
        }
        marker.position = position
        marker.title = timeToString(time: time)
        marker.snippet = type
        marker.userData = time
        marker.map = mapView
        eventMarkers.append(marker)
    }
    
    func updateEvent(events: [Int: (CLLocationCoordinate2D, String)]){
        for event in events{
            if event.value.1 == "SpdOver"{
                setEventMarker(position: event.value.0, time: event.key, type: "SpdOver", icon: #imageLiteral(resourceName: "overspeed"))
            } else if event.value.1 == "Geofence"{
                setEventMarker(position: event.value.0, time: event.key, type: event.value.1, icon: #imageLiteral(resourceName: "geofence"))
            } else{
                setEventMarker(position: event.value.0, time: event.key, type: event.value.1, icon: #imageLiteral(resourceName: "warn"))
            }
        }
    }
    
    func drawPath(position1: CLLocationCoordinate2D, position2: CLLocationCoordinate2D, lineColor: UIColor = UIColor(hex: "14A1FC"))
        //draw path between one position and another assisted by Google Navigation (RestAPI), the algorithm has amended to avoid detour due to GPS inaccurency. Line color can be cutomized to distinguish time of tracks.
    {
        let origin = "\(position1.latitude),\(position1.longitude)"
        let destination = "\(position2.latitude),\(position2.longitude)"
        
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=driving&key=AIzaSyBFTEmpETJFA_eg-eUn5IBEM1mkf50wwRo"
        
        Alamofire.request(url).responseJSON { response in
            
            let json = JSON(data: response.data!)
            let routes = json["routes"].arrayValue
            
            for route in routes
            {
                var polyline: GMSPolyline
                let routelegs = route["legs"].arrayValue
                for routeleg in routelegs{
                    let distance = routeleg["distance"].dictionary
                    let meters = distance?["value"]?.intValue
                    self.totalDistance = self.totalDistance + meters!
                    
                    if meters! > 2000{
                        //If the navigation has returned a detour result because of the inacurrancy of the geoposition which has exceeded the normal car speed range (2km/min), draw a straight line instead
                        let path = GMSMutablePath()
                        path.add(position1)
                        path.add(position2)
                        polyline = GMSPolyline(path: path)
                    }
                    else{
                        let routeOverviewPolyline = route["overview_polyline"].dictionary
                        let points = routeOverviewPolyline?["points"]?.stringValue
                        let path = GMSPath(fromEncodedPath: points!)
                        polyline = GMSPolyline(path: path)
                    }
                    polyline.strokeWidth = 3.0
                    polyline.strokeColor = lineColor
                    polyline.map = self.mapView
                }
            }
            self.distanceLabel.text = "\(self.totalDistance/1000) km"
        }
    }
    
    func animateEventMarkers(markers: [GMSMarker]){
        tapSomewhere = false
        var j = 0.0
        //display every event marker every 2 seconds untill user taps elsewhere in the screen to interrupt
        for marker in markers{
            delay(2*j){
                let updatedCamera = GMSCameraPosition.camera(withLatitude: marker.position.latitude, longitude: marker.position.longitude, zoom: 15.0)
                if !self.tapSomewhere{
                    self.mapView.animate(to: updatedCamera)
                    self.mapView.selectedMarker = marker
                    if marker.snippet != "Start"{
                        self.camera.isHidden = false
                        self.selectedEventTime = marker.userData as! Int!
                        self.view.bringSubview(toFront: self.camera)
                    }
                    else{
                        self.camera.isHidden = true
                    }
                }
            }
            j += 1
        }
    }
    
    func animateMoveMarkers(positions: [(key: Int, value: (CLLocationCoordinate2D, Int))]){
        //animate the tracking of the marker, only animate path between two given positions on account of memory performance
        var twoPositions = [CLLocationCoordinate2D?](repeating: nil, count: 2)
        var j = 0.0
        for position in positions{
            if twoPositions[1] == nil{
                twoPositions[1] = CLLocationCoordinate2D(latitude: position.value.0.latitude, longitude: position.value.0.longitude)
            }
            else{
                delay(Double(j)){
                    twoPositions[0] = twoPositions[1]
                    twoPositions[1] = CLLocationCoordinate2D(latitude: position.value.0.latitude, longitude: position.value.0.longitude)
                    self.animateMoveMarker(oldPosition: twoPositions[0]!, newPosition: twoPositions[1]!, heading: position.value.1)
                }
            }
            j += 2.1 //set another two new positions and launch the animation every 2.1 seconds, which lasts 0.1 sec longer than the animation to make sure the previous animation has completed
        }
    }
    
    func delay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
    
    func animateMoveMarker(oldPosition: CLLocationCoordinate2D, newPosition: CLLocationCoordinate2D, heading: Int){
        movingMarker.groundAnchor = CGPoint(x: CGFloat(0.5), y: CGFloat(0.5))
        movingMarker.rotation = CLLocationDegrees(getHeadingForDirection(fromCoordinate: oldPosition, toCoordinate: newPosition))
        //found bearing value by calculation when marker add
        movingMarker.position = oldPosition
        //this can be old position to make car movement to new position
        movingMarker.map = mapView
        //marker movement animation
        CATransaction.begin()
        CATransaction.setValue(Int(2.0), forKey: kCATransactionAnimationDuration)
        CATransaction.setCompletionBlock({() -> Void in
            self.movingMarker.groundAnchor = CGPoint(x: CGFloat(0.5), y: CGFloat(0.5))
            self.movingMarker.rotation = CDouble(heading+90)
            //New bearing value from backend after car movement is done
        })
        movingMarker.position = newPosition
        //this can be new position after car moved from old position to new position with animation
        movingMarker.groundAnchor = CGPoint(x: CGFloat(0.5), y: CGFloat(0.5))
        movingMarker.rotation = CDouble(getHeadingForDirection(fromCoordinate: oldPosition, toCoordinate: newPosition))
        //found bearing value by calculation
        CATransaction.commit()
        print("animateMovemarker")
    }
    
    func getHeadingForDirection(fromCoordinate fromLoc: CLLocationCoordinate2D, toCoordinate toLoc: CLLocationCoordinate2D) -> Float {
        
        let fLat: Float = Float((fromLoc.latitude).degreesToRadians)
        let fLng: Float = Float((fromLoc.longitude).degreesToRadians)
        let tLat: Float = Float((toLoc.latitude).degreesToRadians)
        let tLng: Float = Float((toLoc.longitude).degreesToRadians)
        let degree: Float = (atan2(sin(tLng - fLng) * cos(tLat), cos(fLat) * sin(tLat) - sin(fLat) * cos(tLat) * cos(tLng - fLng))).radiansToDegrees
        if degree >= 0 {
            return degree+90
        }
        else {
            return 360 + degree+90
        }
    }
    
    func cameraTapped(_ sender: AnyObject?) {
        //If camera is tapped, a slide image controller will appear for snapshots review.
        tapSomewhere = true //interrupt animation when camera is tapped
        urlSource = timeToURLs(time: selectedEventTime)
        
        slideShow.isHidden = false
        slideShow.delegate = self
        slideShow.datasource = self
        slideShow.delay = 1
        slideShow.transitionDuration = 0.5
        slideShow.transitionType = KASlideShowTransitionType.fade
        slideShow.contentMode = .scaleAspectFit
        slideShow.backgroundColor = UIColor.black
        slideShow.frame = CGRect(x: 0, y: 0.4*self.view.frame.height, width: self.view.frame.width, height: 0.75*self.view.frame.width)
        
        playerView.isHidden = false
        playerView.frame = CGRect(x: 0, y: 0.4*self.view.frame.height+0.75*self.view.frame.width, width: self.view.frame.width, height: 30)
        play.frame = CGRect(x: 0.5*self.view.frame.width-50, y: 1, width: 28, height: 28)
        stop.frame = CGRect(x: 0.5*self.view.frame.width+22, y: 1, width: 28, height: 28)
        
        let playGesture = UITapGestureRecognizer(target: self, action:  #selector (self.playTapped(_:)))
        play.addGestureRecognizer(playGesture)
        let stopGesture = UITapGestureRecognizer(target: self, action:  #selector (self.stopTapped(_:)))
        stop.addGestureRecognizer(stopGesture)
        
        
        self.view.bringSubview(toFront: slideShow)
        camera.isHidden = true
        self.view.bringSubview(toFront: playerView)
        slideShow.start()
    }
    
    func playTapped(_ sender:UITapGestureRecognizer){ //user taps play/pause button to control the event slide show.
        if play.currentImage == #imageLiteral(resourceName: "pause"){
            slideShow.stop()
            play.setImage(#imageLiteral(resourceName: "play"), for: .normal)
        }
        else{
            slideShow.start()
            play.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
        }
    }
    
    func stopTapped(_ sender:UITapGestureRecognizer){ //user taps stop button to turn off the event slide show.
        slideShow.stop()
        play.setImage(#imageLiteral(resourceName: "pause"), for: .normal) //show pause rather than play button by default
        slideShow.isHidden = true
        slideShow.delegate = nil
        slideShow.datasource = nil
        playerView.isHidden = true
    }
    
    func slideShow(_ slideShow: KASlideShow!, objectAt index: UInt) -> NSObject! {
        return urlSource[Int(index)]
    }
    
    public func slideShowImagesNumber(_ slideShow: KASlideShow!) -> UInt {
        return UInt(urlSource.count)
    }
    
    func timeToURLs(time: Int) -> [NSURL]{
        let demoDate: String! = "2017/08/15"
        
        var urls = [NSURL]()
        for index in -4...5{
            let convertedTime = timeTo0time(time: time+index)
            urls.append(NSURL(string: "\(mainUrl)/VEHICLE/\(selectedVehicleId)/\(demoDate!)/EVENT/cam1-\(convertedTime)01.jpg")!)
        }
        return urls
    }
    
    func timeToString(time: Int) -> String{
        let hour: Int = time/10000
        let minute: Int = time/100 - hour*100
        return String(format: "%02d:%02d", hour, minute)
    }
    
    func timeTo0time(time: Int) -> String{
        return String(format: "%06d", time)
    }
    
    func imageWithImage(image:UIImage, scaledToSize newSize:CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        image.draw(in: CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: newSize.width, height: newSize.height))  )
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}

