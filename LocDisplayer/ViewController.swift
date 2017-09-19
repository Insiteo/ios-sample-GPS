//
//  ViewController.swift
//  LocDisplayer
//
//  Created by Florian Lecoeuche on 9/14/17.
//  Copyright © 2017 Florian Lecoeuche. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var currentSiteLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var siteIdTextField: UITextField!
    
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
    
    func startInsiteoSDK() {
        
        print("Start InstieoSDK - Start")
        
        var myDict: NSDictionary?
        
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
            myDict = NSDictionary(contentsOfFile: path)
        }
        
        guard let siteId : Int32 = myDict?.value(forKey: "ISSite") as? Int32 else {
            print("No value found for key ISSite in the .plist file.")
            return
        }
        
        currentSiteLabel.text = siteId.description
        
        let site : ISUserSite = Insiteo.currentUser().getSiteWithSiteId(siteId)
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
                    
                    self.startLocalisation()
                    
                }, andUpdateProgressHandler: { (packageType: ISEPackageType, download: Bool, progress: Int32, total: Int32) in
                    
                    let totalProgress: Float = (Float(progress) / Float(total)) * 100
                    
                    var package: String = String();
                    
                    switch (packageType.rawValue) {
                    case 1:
                        package = "mapdata"
                        break
                    case 3:
                        package = "localisation"
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
        
        print("Start InstieoSDK - End")
        
    }
    
    // Change site
    
    func changeSite(with newSite : Int32) {
        
        print("Changing site - Start")
        
        let site : ISUserSite = Insiteo.currentUser().getSiteWithSiteId(newSite)
        Insiteo.sharedInstance().startAndUpdate(with:site, andStartHandler: { (error: ISError?, tab: [Any]?) in
            
            if let errorMessage = error?.message {
                print("Start handler error : \(errorMessage)")
            }
            
        }, andUpdateHandler: { (error: ISError?) in
            
            if let errorMessage = error?.message {
                print("Update handler error : \(errorMessage)")
            }
            
        }, andUpdateProgressHandler: { (packageType: ISEPackageType, dowload: Bool, progress: Int32, total: Int32) in
            let totalProgress: Float = (Float(progress) / Float(total)) * 100
            
            var package: String = String();
            
            switch (packageType.rawValue) {
            case 1:
                package = "mapdata"
                break
            case 3:
                package = "localisation"
                break
            case 0:
                break
            default:
                package = "temporaire"
                break
            }
            print("Downloading package : \(package) - \(totalProgress)%")
        })
        
        currentSiteLabel.text = newSite.description
        
        print("Changing site - End")
    }
    
    // MARK : Localisation
    
    func startLocalisation() {
        
        if Insiteo.currentSite().hasPackage(ISEPackageType.location)
        && Insiteo.currentSite().hasPackage(ISEPackageType.mapData){
            ISLocationProvider.sharedInstance().start(with: self)
        }
        
    }
    
    func stopLocalisation() {
        ISLocationProvider.sharedInstance().stopLocation()
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
