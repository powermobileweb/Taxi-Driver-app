//
//  HomeVC.swift
//  TaxiDriver
//
//  Created by PowerMobile on 4/2/18.
//  Copyright © 2018 PowerMobile. All rights reserved.
//

import UIKit
import MapKit

class HomeVC: UIViewController, MKMapViewDelegate,CLLocationManagerDelegate, UberController {
   
 
    
 
    @IBOutlet weak var requestOutlet: ButtonStyles!
    @IBOutlet weak var mapView: MKMapView!
    
    //variables
    
    private var locationManager = CLLocationManager()
    private var userLocation : CLLocationCoordinate2D?
    private var riderLocation : CLLocationCoordinate2D?
    
    private var timer = Timer()
    private var acceptedRequest = false
    private var driverCanceledRequest = false

    
    override func viewDidLoad() {
        super.viewDidLoad()
        DriverHandler.Instance.delegate = self
        DriverHandler.Instance.observeMessagesForDriver()
        initializeLocationManager()
        
    }
 
    func initializeLocationManager(){
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locationManager.location?.coordinate{
            userLocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            let region = MKCoordinateRegion(center: userLocation!, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            mapView.setRegion(region, animated: true)
            mapView.removeAnnotations(mapView.annotations)
            if riderLocation != nil{
                if acceptedRequest{
                    let riderAnnotion = MKPointAnnotation()
                    riderAnnotion.coordinate = riderLocation!
                    riderAnnotion.title = "Rider's Location"
                    mapView.addAnnotation(riderAnnotion)
                }
            }
            let annotation = MKPointAnnotation()
            annotation.coordinate = userLocation!
            annotation.title = "Rider Location"
            mapView.addAnnotation(annotation)
            
        }
    }
    func acceptedUber(lat: Double, long: Double) {
        if !acceptedRequest {
            uberRequest(title: "Request a ride", message: "You have a request for Ride at this location Lat\(lat) long \(long)", requestAlive: true)
        }
    }
    func riderCanceledUber() {
        if !driverCanceledRequest {
            DriverHandler.Instance.cancelTaxiForDriver()
            self.acceptedRequest = false
            self.requestOutlet.isHidden = true
            uberRequest(title: "Request Canceled", message: "The rider has canceled the request", requestAlive: false)
            
        }
        driverCanceledRequest = false

        
    }
    
    func updateRiderLocation(lat: Double, long: Double) {
        riderLocation = CLLocationCoordinate2D(latitude: lat, longitude: long)
    }
    
    
    func taxiCancled() {
        acceptedRequest = false
        requestOutlet.isHidden = true
        //invalid timer
        timer.invalidate()
    }
    
    @objc func updateDriverLocation(){
        DriverHandler.Instance.updateDriverLocation(lat: userLocation!.latitude, long: userLocation!.longitude)
        
    }
    
    
    private func uberRequest (title: String, message: String , requestAlive: Bool){
        let alert =  UIAlertController(title: title, message: message, preferredStyle: .alert)

        if requestAlive {
            let accept = UIAlertAction(title: "Accept", style: .default, handler: {(alertAction: UIAlertAction) in
                self.acceptedRequest = true
                self.requestOutlet.isHidden = false
                self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(5), target: self, selector: #selector(HomeVC.updateDriverLocation), userInfo: nil, repeats: true)
                //inform that driver accepted the request
                
                DriverHandler.Instance.requestAccepted(latitude: Double((self.userLocation!.latitude)), longitude: Double((self.userLocation!.longitude)))
                
            })
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(accept)
            alert.addAction(cancel)
        } else {
            let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(ok)
        }
        present(alert, animated: true, completion: nil)

    }
 
//    func alertUser (title: String, message: String){
//        let alert =  UIAlertController(title: title, message: message, preferredStyle: .alert)
//        let ok = UIAlertAction(title: "OK", style: .default, handler: nil)
//        alert.addAction(ok)
//        present(alert, animated: true, completion: nil)
//
//    }
    
    func seguePerform(){
        
        
        if AuthProvider.Instance.logOut() {

            if acceptedRequest {
                requestOutlet.isHidden = true
                DriverHandler.Instance.cancelTaxiForDriver()
                timer.invalidate()
            }
            dismiss(animated: true, completion: nil)
           // performSegue(withIdentifier: "logoutSegue", sender: self)

        } else {
            uberRequest(title: "Error Logout", message: "Could not logout at the moment please tyr later", requestAlive: false)
        }
        
    }
    
   
    
    @IBAction func logoutAction(_ sender: UIBarButtonItem) {
    seguePerform()
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        if acceptedRequest {
            driverCanceledRequest = true
            requestOutlet.isHidden = true
            DriverHandler.Instance.cancelTaxiForDriver()
            //invalid timer
            timer.invalidate()

        }
    }
    
    
}
