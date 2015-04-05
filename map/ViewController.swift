//
//  ViewController.swift
//  map
//
//  Created by Clinton Weir on 4/1/15.
//  Copyright (c) 2015 HelloWorld-ClintonW. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var theMap : MKMapView?
    @IBOutlet weak var theTable : UITableView?
    var theLocations : [String : CWMapLocation] = Dictionary()
    var theLocationsArray : [CWMapLocation] = Array()
    var locationManager : CLLocationManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    func locationAuthorized() -> Bool   {
        return (CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedAlways ||
                CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedWhenInUse)
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if locationAuthorized()    {
            manager.startUpdatingLocation()
            calculateDistances(nil)
        }
        else    {
            theTable!.reloadData()
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if let newLocation = locations.last as? CLLocation  {
            calculateDistances(newLocation)
        }
    }
    
    func calculateDistances(aLocation : CLLocation?)   {
        var newLocation = aLocation
        if newLocation == nil && locationManager != nil   {
            newLocation = locationManager!.location
        }
        for (key, location) : (String, CWMapLocation) in theLocations    {
            location.distance(newLocation)
        }
        
        for var index=0; index<theLocationsArray.count; index++ {
            var location1   = theLocationsArray[index]
            var distance1   = location1.lastDistance
            
            for var indey=index+1; indey<theLocationsArray.count; indey++   {
                var location2   = theLocationsArray[indey]
                var distance2   = location2.lastDistance
                
                if distance2 < distance1  {
                    var temp2   = location2
                    theLocationsArray.removeAtIndex(indey)
                    theLocationsArray.insert(temp2, atIndex: index)
                    
                    location1   = location2
                    distance1   = distance2
                }
            }
        }
        
        self.theTable!.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        var output : MKAnnotationView   = MKAnnotationView(annotation: annotation, reuseIdentifier: nil)
        output.image    = UIImage(contentsOfFile: NSBundle.mainBundle().pathForResource("HWMapMarker", ofType: "png")!)
        return output
    }
    
    @IBAction func loadLocations(sender: AnyObject) {
        if theMap == nil    {
            return
        }
        
        var xPos    = theMap!.frame.width/2 - 10
        var yPos    = theMap!.frame.height/2 - 10
        
        var activitySuperview : UIView  = UIView(frame: CGRectMake(0, 0, theMap!.frame.width, theMap!.frame.height))
        activitySuperview.backgroundColor   = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        
        var activity : UIActivityIndicatorView  = UIActivityIndicatorView(frame: CGRectMake(xPos, yPos, 20, 20))
        activity.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        theMap!.addSubview(activitySuperview)
        theMap!.addSubview(activity)
        activity.hidesWhenStopped   = true
        activity.startAnimating()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))   {
            var locations : [CWMapLocation]  = CWMapLocation.getLocs()
            
            dispatch_async(dispatch_get_main_queue())   {
                activity.stopAnimating()
                activitySuperview.removeFromSuperview()
                activity.removeFromSuperview()
            }
            
            if locations.count == 0 {
                return
            }
            if let annotations = self.theMap!.annotations as? [MKAnnotation] {
                self.theMap!.removeAnnotations(annotations)
            }
            
            self.theLocations   = Dictionary()
            self.theLocationsArray  = Array()
            for location : CWMapLocation in locations   {
                dispatch_async(dispatch_get_main_queue())   {
                    self.theMap!.addAnnotation(location.annotation())
                }
                self.theLocations[location.name] = location
                self.theLocationsArray.append(location)
            }
            
            if (UIDevice.currentDevice().systemVersion as NSString).floatValue < 8.0    {
                dispatch_async(dispatch_get_main_queue())   {
                    self.locationManager!.startUpdatingLocation()
                    
                    if self.locationAuthorized()    {
                        self.calculateDistances(nil)
                    }
                    else    {
                        self.theTable!.reloadData()
                    }
                }
            }
            else {
                self.locationManager!.requestWhenInUseAuthorization()
                
                if self.locationAuthorized()    {
                    dispatch_async(dispatch_get_main_queue())   {
                        self.locationManager!.startUpdatingLocation()
                        self.calculateDistances(nil)
                    }
                }
                
                dispatch_async(dispatch_get_main_queue())   {
                    self.theTable!.reloadData()
                }
            }
            
            
        }
    }
    
    func mapViewDidFinishLoadingMap(mapView: MKMapView!) {
        self.locationManager = CLLocationManager()
        self.locationManager!.delegate   = self
        self.locationManager!.desiredAccuracy    = kCLLocationAccuracyKilometer
        self.locationManager!.distanceFilter     = 100

        loadLocations(mapView)
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        var location : CWMapLocation    = theLocations[view.annotation.title!]!
        performSegueWithIdentifier("pushDetail", sender: location)
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return theLocations.count
        }
        else    {
            return 0
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("tableCell", forIndexPath: indexPath) as UITableViewCell
        
        var section = indexPath.section
        var row     = indexPath.row
        var location            = theLocationsArray[row]
        
        
        cell.textLabel!.text    = location.name
        
        var subText    = location.address().stringByReplacingOccurrencesOfString("\n", withString: "; ", options: NSStringCompareOptions.allZeros, range: nil)
        var distMsg = location.distanceString()
        if distMsg != nil   {
            subText += "; " + distMsg!
        }
        cell.detailTextLabel!.text  = subText
        
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var location : CWMapLocation?
        if let annotationview = sender as? MKAnnotationView {
            let annotation  = annotationview.annotation
            location    = theLocations[annotation.title!]
        }
        else if let cell = sender as? UITableViewCell   {
            location    = theLocations[cell.textLabel!.text!]
        }
        else if var theLocation = sender as? CWMapLocation {
            location = theLocation
        }
        
        if location != nil  {
            if let detailVC = segue.destinationViewController as? DetailViewController  {
                detailVC.location   = location
            }
        }
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
}

