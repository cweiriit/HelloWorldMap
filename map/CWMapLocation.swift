//
//  CWMapLocation.swift
//  map
//
//  Created by Clinton Weir on 4/1/15.
//  Copyright (c) 2015 HelloWorld-ClintonW. All rights reserved.
//

import UIKit
import MapKit

class CWMapLocation {
    class func getLocs() -> [CWMapLocation]    {
        var parseTask : (NSArray) -> ([CWMapLocation])  = {
            (locationList : NSArray) -> [CWMapLocation] in
            var locs : [CWMapLocation] = []
            
            for var index=0; index<locationList.count; index++  {
                if let location = locationList[index] as? [String : String]    {
                    var aLocation   = CWMapLocation(dict : location)
                    locs.append(aLocation)
                    
                }
            }
            
            return locs
        }
        var fetchTask : () -> ([CWMapLocation])    = {
            () -> [CWMapLocation] in
            var jsonURL   = "http://www.helloworld.com/helloworld_locations.json"
            var helloWorldUrl   = NSURL(string: jsonURL)
            var helloWorldData  = NSData(contentsOfURL: helloWorldUrl!)
            if helloWorldData != nil    {
                var errors : NSError?
                var jsonObject: AnyObject?  = NSJSONSerialization.JSONObjectWithData(helloWorldData!, options: NSJSONReadingOptions.AllowFragments, error: &errors)
                
                if let jsonObj = jsonObject as? NSDictionary  {
                    var object: AnyObject?  = jsonObj.objectForKey("locations")
                    if let locationList = object as? NSArray {
                        NSUserDefaults.standardUserDefaults().setObject(locationList, forKey: "com.helloworld.clintonw.map.jsonCache")
                        return parseTask(locationList)
                    }
                }
            }
            
            return []
        }
        
        var jsonObj: AnyObject?   = NSUserDefaults.standardUserDefaults().objectForKey("com.helloworld.clintonw.map.jsonCache")
        
        
        if let lastJson = jsonObj as? NSArray   {
            /*
            dispatch_async(dispatch_get_main_queue())   {
                fetchTask()
            }   */
            return parseTask(lastJson)
        }
        else    {
            return fetchTask()
        }
    }
    
    var name        : String = "(unnamed)"
    var address1    : String = "(no address)"
    var address2    : String = ""
    var city        : String = "(no city)"
    var state       : String = "ZZ"
    var zipcode     : String = "00000"
    var phone       : String = "(000) 000-0000"
    var fax         : String = "(000) 000-0000"
    var locLat      : Double = 0.0
    var locLon      : Double = 0.0
    var imUrl       : String = ""
    var image       : UIImage?
    
    private(set) var lastDistance : CLLocationDistance = CLLocationDistance.infinity
    
    init(dict : [String : String])    {
        name        = dict["name"]!
        address1    = dict["address"]!
        address2    = dict["address2"]!
        city        = dict["city"]!
        state       = dict["state"]!
        zipcode     = dict["zip_postal_code"]!
        phone       = dict["phone"]!
        fax         = dict["fax"]!
        var locLatString      = dict["latitude"]!
        locLat      = (locLatString as NSString).doubleValue
        var locLonString      = dict["longitude"]!
        locLon      = (locLonString as NSString).doubleValue
        imUrl       = dict["office_image"]!
        
        var imageUrl   = NSURL(string: imUrl)
        if imageUrl != nil {
            var imData  = NSData(contentsOfURL: imageUrl!)
            
            if imData != nil    {
                var anImage = UIImage(data: imData!)
                if anImage != nil   {
                    image   = anImage
                }
            }
        }
    }
    
    func annotation() -> MKPointAnnotation  {
        var anAnnotation = MKPointAnnotation()
        anAnnotation.setCoordinate(CLLocationCoordinate2D(latitude: locLat, longitude: locLon))
        anAnnotation.title  = name
        
        return anAnnotation
    }
    
    func location() -> CLLocation   {
        return CLLocation(latitude: locLat, longitude: locLon)
    }
    
    func detailText() -> String {
        var output = name
        output += "\n" + address()
        
        var distString  = distanceString()
        if distString != nil    {
            output += "\n" + distString!
        }
        
        return output
    }
    
    func distance(fromLocation : CLLocation?) -> CLLocationDistance {
        if fromLocation != nil  {
            var output = location().distanceFromLocation(fromLocation)
            lastDistance    = output
        }
        return lastDistance
    }
    
    func distanceString() -> String?    {
        if lastDistance == CLLocationDistance.infinity  {
            return nil
        }
        
        var dist = Double(lastDistance)
        if dist > 1000  {
            dist /= 100
            dist    = round(dist)
            dist /= 10
            return "\(dist) km away"
        }
        else    {
            dist    = round(dist)
            return "\(dist) m away"
        }
    }
    
    func address() -> String    {
        var output = address1 + "\n"
        
        if countElements(address2) > 0  {
            output += address2 + "\n"
        }
        
        output += city + ", " + state + " " + zipcode
        
        return output
    }
}
