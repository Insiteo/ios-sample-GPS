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
        let site : ISUserSite = Insiteo.currentUser().getSiteWithSiteId(Int32(559))
        Insiteo.sharedInstance().start(with: site, andStartHandler: { (error: ISError?, newPackages:[Any]?) in
            
            if error == nil {
                Insiteo.sharedInstance().updateCurrentSite(withWantedPackages: newPackages, andUpdateHandler: { (err: ISError?) in
                    
                    if let errorMessage = err?.message {
                        print("Update site error : \(errorMessage)")
                    } else {
                        print("Update site succes")
                    }
                    
                    self.startLocalisation()
                    
                }, andUpdateProgressHandler: { (packageType: ISEPackageType, download: Bool, progress: Int32, total: Int32) in
                    
                    let totalProgress: Float = (Float(progress) / Float(total)) * 100
                    
                    var package: String = String();
                    
                    switch (packageType.rawValue) {
                    case 1:
                        package = "mapdata"
                        break
                    case 2:
                        package = "tiles"
                        break
                    case 3:
                        package = "localisation"
                        break
                    case 4:
                        package = "itinerary"
                        break
                    case 10:
                        package = "extras"
                        break
                    case 0:
                        break
                    default:
                        package = "temporaire"
                        break
                    }
                    print("Downloading package : \(package) - \(totalProgress)%")
                })
                
                self.startLocalisation()
            } else {
                if let errorMessage = error?.message {
                    print("Start insiteo SDK ERROR : \(errorMessage)")
                }
            }
            
        })
    }
    
    // MARK : Localisation
    
    func startLocalisation() {
        
        if Insiteo.currentSite().hasPackage(ISEPackageType.location) {
            ISLocationProvider.sharedInstance().start(with: self)
        }
        
    }
    
    func stopLocalisation() {
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
