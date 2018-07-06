//
//  ViewController.swift
//  LocDisplayer
//
//  Created by Florian Lecoeuche on 9/14/17.
//  Copyright © 2017 Florian Lecoeuche. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initInsiteoSDK()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Insiteo SDK Init/Start
    
    func initInsiteoSDK() {
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
    }
    
    func startInsiteoSDK() {
        
        var myDict: NSDictionary?
        
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        
        guard let siteId : Int32 = myDict?.value(forKey: "ISSite") as? Int32 else {
            print("No value found for key ISSite in the .plist file.")
            return
        }
        
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
                    && package.packageType != ISEPackageType.mapData {

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
                    
                    self.startLocation()
                    
                }, andUpdateProgressHandler: { (packageType: ISEPackageType, download: Bool, progress: Int32, total: Int32) in
                    
                    let totalProgress: Float = (Float(progress) / Float(total)) * 100
                    
                    var package: String = String();
                    
                    switch (packageType.rawValue) {
                    case 1:
                        package = "mapdata"
                        break
                    case 3:
                        package = "location"
                        break
                    case 0:
                        break
                    default:
                        package = "default"
                        break
                    }
                    print("Downloading package : \(package) - \(totalProgress)%")
                })
                
                self.startLocation()
            } else {
                if let errorMessage = error?.message {
                    print("Start insiteo SDK ERROR : \(errorMessage)")
                }
            }
            
        })
    }
    
    // MARK : Location
    
    func startLocation() {
        
        if Insiteo.currentSite().hasPackage(ISEPackageType.location)
        && Insiteo.currentSite().hasPackage(ISEPackageType.mapData){
            ISLocationProvider.sharedInstance().start(with: self)
        }
        
    }
    
    func stopLocation() {
        ISLocationProvider.sharedInstance().stopLocation()
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
