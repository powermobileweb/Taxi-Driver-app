//
//  DriverHandler.swift
//  TaxiDriver
//
//  Created by Rashid on 26/04/2018.
//  Copyright © 2018 PowerMobile. All rights reserved.
//

import Foundation
import FirebaseDatabase

protocol UberController : class {
    func acceptedUber(lat: Double, long: Double)
    func riderCanceledUber()
    func taxiCancled()
    func updateRiderLocation(lat: Double, long: Double)
}

class DriverHandler {
    
    private static let _instance = DriverHandler()
    
    weak var delegate : UberController?
    
    var rider = ""
    var driver = ""
    var driver_id = ""
    
    static var Instance : DriverHandler {
        return _instance
    }
    
    func observeMessagesForDriver () {
        DBProvider.instance.requestRef.observe(DataEventType.childAdded){(snapshot : DataSnapshot) in
            if let data = snapshot.value as? NSDictionary {
                if let latitude = data[Constance.LATITUDE] as? Double {
                    if let longitude = data[Constance.LONGITUED] as? Double {
                        // infome the driver
                        self.delegate?.acceptedUber(lat: latitude, long: longitude)
                    }
                }
                if let name = data[Constance.NAME] as? String {
                    self.rider = name
                }
            }
            
            //rider canceled  request
            DBProvider.instance.requestRef.observe(DataEventType.childRemoved, with: { (snapshot:DataSnapshot) in
                if let data = snapshot.value as? NSDictionary {
                    if let name = data[Constance.NAME] as? String {
                        if name == self.rider {
                            self.rider = ""
                            self.delegate?.riderCanceledUber()
                            
                        }
                    }
                }
            })
        }
        //Rider location updating
        DBProvider.instance.requestRef.observe(DataEventType.childChanged) { (snapshot : DataSnapshot) in
            if let data = snapshot.value as? NSDictionary {
                if let lat = data[Constance.LATITUDE] as? Double{
                    if let long = data[Constance.LONGITUED] as? Double{
                        self.delegate?.updateRiderLocation(lat: lat, long: long)
                    }
                }
            }
        }
        
        //driver accept uber
        DBProvider.instance.requestAcceptedRef.observe(DataEventType.childAdded) { (snapshot: DataSnapshot) in
            if let data = snapshot.value as? NSDictionary {
                if let name = data[Constance.NAME] as? String {
                    if name == self.driver {
                        self.driver_id = snapshot.key
                    }
                }
            }
        }
        
     
        
        //Driver caneled the taxi
        DBProvider.instance.requestAcceptedRef.observe(DataEventType.childRemoved) { (snapshot : DataSnapshot) in
            if let data = snapshot.value as? NSDictionary {
                if let name = data[Constance.NAME] as? String {
                    if name == self.driver {
                        self.delegate?.taxiCancled()
                    }
                }
            }
        }
        
    }//observeMessagesForDriver
    
    func requestAccepted(latitude: Double, longitude: Double){
        let data : Dictionary<String, Any> = [Constance.NAME : driver, Constance.LATITUDE : latitude, Constance.LONGITUED : longitude]
        DBProvider.instance.requestAcceptedRef.childByAutoId().setValue(data)
    }//request uber
    
    func cancelTaxiForDriver(){
        DBProvider.instance.requestAcceptedRef.child(driver_id).removeValue()
    }
    
    func updateDriverLocation(lat: Double, long: Double){
        DBProvider.instance.requestAcceptedRef.child(driver_id).updateChildValues([Constance.LATITUDE : lat, Constance.LONGITUED : long])
        
        
    }
    
}

