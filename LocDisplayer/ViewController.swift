//
//  ViewController.swift
//  LocDisplayer
//
//  Created by Florian Lecoeuche on 9/14/17.
//  Copyright © 2017 Florian Lecoeuche. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var currentSiteLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var onEnterLabel: UILabel!
    @IBOutlet weak var onExitLabel: UILabel!
    @IBOutlet weak var siteIdTextField: UITextField!
    @IBOutlet weak var mapView: UIView!
    
    var map : UIView!
    var isMapView : ISMapView?
    
    var insiteoIsStarted = false
    
    var locationRenderer : ISLocationRenderer?
    
    var onEnterCounter : Int32 = 0
    var onExitCounter : Int32 = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        self.initInsiteoSDK()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Insiteo SDK Init/Start
    
    func initInsiteoSDK() {
        
        print("Init InsiteoSDK - Start")
        
        Insiteo.sharedInstance().launch(initializeHandler: { (error: ISError?, suggestedSite: ISUserSite?, fromLocalCache: Bool) in
            
            if let errorMessage = error?.message {
                print("Insiteo SDK initialization failed : \(errorMessage)")
            } else {
                self.startInsiteoSDK()
            }
            
        }, andChooseSiteHandler: { () -> CLLocation? in
            
            return nil
            
        }, andStartHandler: { (error: ISError?, tab: [Any]?) in
            
            if let errorMessage = error?.message {
                print("Start handler error : \(errorMessage)")
            }
            
        }, andUpdateHandler: { (error: ISError?) in
            
            if let errorMessage = error?.message {
                print("Update handler error : \(errorMessage)")
            }
            
        }, andUpdateProgressHandler: { (packageType: ISEPackageType, dowload: Bool, progress: Int32, total: Int32) in
            
        })
        
        print("Init InsiteoSDK - End")
    }
    
    func startInsiteoSDK(with site: Int32 = 0) {
        
        print("Starting InstieoSDK - Start")
        
        // Get the value of key ISSite in Info.plist
        var myDict: NSDictionary?
        
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        
        guard var siteId : Int32 = myDict?.value(forKey: "ISSite") as? Int32 else {
            print("No value found for key ISSite in the .plist file.")
            return
        }
        
        currentSiteLabel.text = String(siteId)
        
        if site > 0 {
            siteId = site
            currentSiteLabel.text = String(siteId)
        }
        
        // Start SDK with siteId
        guard let site : ISUserSite = Insiteo.currentUser().getSiteWithSiteId(siteId) else {
            print("Site not found")
            return
        }
        
        Insiteo.sharedInstance().start(with: site, andStartHandler: { (error: ISError?, newPackages:[Any]?) in
            
            guard var wantedPackages = newPackages as? [ISPackage] else {
                print("Error with packages")
                return
            }
            
            // Remove useless packages
            for (index, package) in wantedPackages.enumerated().reversed() {
                
                if package.packageType != ISEPackageType.location
                    && package.packageType != ISEPackageType.mapData
                    && package.packageType != ISEPackageType.tiles {
                    
                    wantedPackages.remove(at: index)
                    
                }
            }
            
            if error == nil {
                Insiteo.sharedInstance().updateCurrentSite(withWantedPackages: wantedPackages, andUpdateHandler: { (err: ISError?) in
                    
                    if let errorMessage = err?.message {
                        print("Update site error : \(errorMessage)")
                    } else {
                        print("Update site succes")
                    }
                    
                    self.initMapConstraints()
                    self.createMap()
                    
                }, andUpdateProgressHandler: { (packageType: ISEPackageType, download: Bool, progress: Int32, total: Int32) in
                    
                    let totalProgress: Float = (Float(progress) / Float(total)) * 100
                    
                    var package: String = String();
                    
                    switch (packageType.rawValue) {
                    case 0:
                        break
                    case 1:
                        package = "mapdata"
                        break
                    case 2:
                        package = "tiles";
                        break;
                    case 3:
                        package = "location"
                        break
                    default:
                        package = "default"
                        break
                    }
                    print("Downloading package : \(package) - \(totalProgress)%")
                })
                
                self.initMapConstraints()
                self.createMap()
            } else {
                if let errorMessage = error?.message {
                    print("Start insiteo SDK ERROR : \(errorMessage)")
                }
            }
            
        })
        
        print("Starting InstieoSDK - End")
        insiteoIsStarted = true
        
        // Launch ISBeaconProvider
        ISBeaconProvider.sharedInstance().start(with: self)
        
    }
    
    // Change site
    
    func changeSite(with newSite : Int32) {
        
        onEnterCounter = 0
        onExitCounter = 0
        
        if !insiteoIsStarted {
            startInsiteoSDK(with: newSite)
            return
        }
        
        print("Changing site - Start")
        
        // If ISLocationProvider started, stop it
        if ISLocationProvider.sharedInstance().isStarted {
            self.stopLocation()
        }
        
        let site : ISUserSite = Insiteo.currentUser().getSiteWithSiteId(newSite)
        Insiteo.sharedInstance().startAndUpdate(with:site, andStartHandler: { (error: ISError?, tab: [Any]?) in
            
            if let errorMessage = error?.message {
                print("Start handler error : \(errorMessage)")
            }
            
        }, andUpdateHandler: { (error: ISError?) in
            
            if let errorMessage = error?.message {
                print("Update handler error : \(errorMessage)")
            }
            
            self.isMapView?.resetMap()
            
        }, andUpdateProgressHandler: { (packageType: ISEPackageType, dowload: Bool, progress: Int32, total: Int32) in
            let totalProgress: Float = (Float(progress) / Float(total)) * 100
            
            var package: String = String();
            
            switch (packageType.rawValue) {
            case 0:
                break
            case 1:
                package = "mapdata"
                break
            case 2:
                package = "tiles";
                break;
            case 3:
                package = "location"
                break
            default:
                package = "default"
                break
            }
            print("Package type : \(packageType.rawValue)")
            print("Downloading package : \(package) - \(totalProgress)%")
        })
        
        currentSiteLabel.text = newSite.description
        
        print("Changing site - End")
    }
    
    // MARK : Map
    
    func initMapConstraints() {
        print("Map constraints initilization")
        
        self.map = UIView()
        
        self.mapView.addSubview(map!)
        
        self.map.translatesAutoresizingMaskIntoConstraints = false
        
        let topConstraint = NSLayoutConstraint(item: self.map, attribute: .top, relatedBy: .equal, toItem: self.mapView, attribute: .top, multiplier: 1, constant: 0)
        self.view.addConstraint(topConstraint)
        
        let leftConstraint = NSLayoutConstraint(item: self.map, attribute: .left, relatedBy: .equal, toItem: self.mapView, attribute: .left, multiplier: 1, constant: 0)
        self.view.addConstraint(leftConstraint)
        
        let bottomConstraint = NSLayoutConstraint(item: self.map, attribute: .bottom, relatedBy: .equal, toItem: self.mapView, attribute: .bottom, multiplier: 1, constant: 0)
        self.view.addConstraint(bottomConstraint)
        
        let rightConstraint = NSLayoutConstraint(item: self.map, attribute: .right, relatedBy: .equal, toItem: self.mapView, attribute: .right, multiplier: 1, constant: 0)
        self.view.addConstraint(rightConstraint)
    }
    
    func createMap() {
        
        let frame : CGRect = CGRect(x: 0, y: 0, width: self.mapView.frame.size.width, height: self.mapView.frame.size.height)
        
        if Insiteo.currentSite().hasPackage(ISEPackageType.mapData)
            && Insiteo.currentSite().hasPackage(ISEPackageType.tiles) {
            
            if Insiteo.currentUser().renderMode == ISERenderMode.mode2D {
                ISMap2DView.getWithFrame(frame, andMapDelegate: self, andHandler: { (map : ISMap2DView?) in
                    
                    self.isMapView = map
                    
                    self.locationRenderer = ISLocationProvider.sharedInstance().renderer
                    self.isMapView?.add(self.locationRenderer)
                    self.isMapView?.startRendering()
                    
                    self.map.addSubview(self.isMapView!)
                    
                })
                
            } else {
                
                print("Can't find Render Mode 2D")
                
            }
            
            print("Can't find Map Data or/and Tiles packages")
        }
        
    }
    
    // MARK : Location
    
>>>>>>> 29b441a2086fae1fd3030f60c4fff704759d151c
    func startLocation() {
        
        if Insiteo.currentSite().hasPackage(ISEPackageType.location)
            && Insiteo.currentSite().hasPackage(ISEPackageType.mapData){
            
            ISLocationProvider.sharedInstance().start(with: self)
            self.locationButton.setTitle("Stop loc", for: UIControlState.normal)
        }
        
    }
    
    func stopLocation() {
        ISLocationProvider.sharedInstance().stopLocation()
        self.locationButton.setTitle("Start loc", for: UIControlState.normal)
    }
    
    // MARK : IBAction
    
    @IBAction func changeSitePressed(_ sender: Any) {
        self.becomeFirstResponder()
        
        if let siteId = siteIdTextField.text {
            print(siteId)
            changeSite(with: Int32(siteId)!)
        }
        
        siteIdTextField.text = nil
    }
    
    @IBAction func locationButtonPressed(_ sender: Any) {
        if self.locationButton.titleLabel?.text == "Start loc" {
            startLocation()
        } else {
            stopLocation()
        }
    }
}

// MARK : ISLocationDelegate

extension ViewController : ISLocationDelegate {
    
    func onLocationInitDone(withSuccess success: Bool, andError error: ISError!) {
        if let errorMessage = error?.message {
            print(errorMessage)
        } else if success {
            print("Location initialization done")
        }
    }
    
    func onLocationReceived(_ location: ISLocation!) {
        
        guard let currentMap : ISMap = Insiteo.currentSite().getMapWithMapId(location.mapId) else {
            return
        }
        
        let locationCoordinates : CGPoint = currentMap.toLatLongWith(x: location.x, andY: location.y)
        
        print("Location : Lattitude(\(locationCoordinates.y)) - Longitude(\(locationCoordinates.x))")
        
        longitudeLabel.text = locationCoordinates.x.description
        latitudeLabel.text = locationCoordinates.y.description
        
    }
    
    func onAzimuthReceived(_ azimuth: Float) {
        print("Azimut received : \(azimuth)")
    }
    
    func onLocationLost(_ lastPosition: ISPosition!) {
        print("Location lost at \(lastPosition.coordinates)")
    }
}

// MARK : ISMapViewDelegate

extension ViewController : ISMapViewDelegate {
    
    func onZoneClicked(with zone: ISZone!) {
        print("onZoneClicked : \(zone.idZone)")
    }
    
    func onZoomEnd(_ newZoom: Double) {
        print("onZoomEnd")
    }
    
    func onMapMoved() {
        print("onMapMoved")
    }
    
    func onMapClicked(_ touchPosition: ISPosition!) {
        print("onMapClicked")
    }
    func onMapReleased() {
        print("onMapReleased")
    }
    func onMapChanged(withNewMapId newMapId: Int32, andMapName mapName: String!) {
        print("onMapChanged")
    }
    
}

// MARK : ISBeaconDelegate

extension ViewController : ISBeaconDelegate {
    func onEnter(_ beaconRegion: ISBeaconRegion!) {
        print("On enter beacon region")
        onEnterCounter += 1
        onEnterLabel.text = String(onEnterCounter)
    }
    
    func onExitBeaconRegion(_ beaconRegion: ISBeaconRegion!) {
        print("On exit beacon region")
        onExitCounter += 1
        onExitLabel.text = String(onExitCounter)
    }
}

// MARK : UIViewControler

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
}

