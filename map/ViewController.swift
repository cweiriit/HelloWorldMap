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
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.AuthorizedAlways ||
            status == CLAuthorizationStatus.AuthorizedWhenInUse    {
                manager.startUpdatingLocation()
        }
    }
    
    func locationManagerDidPauseLocationUpdates(manager: CLLocationManager!) {
    }
    
    func locationManagerDidResumeLocationUpdates(manager: CLLocationManager!) {
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!, fromLocation oldLocation: CLLocation!) {
        calculateDistances(newLocation)
    }
    
    func calculateDistances(aLocation : CLLocation?)   {
        var newLocation = aLocation
        if newLocation == nil && locationManager != nil   {
            newLocation = locationManager!.location
        }
        for (key, location) : (String, CWMapLocation) in theLocations    {
            location.distance(newLocation!)
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
        
        theTable?.reloadData()
        //theTable?.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
    }
    
    func locationManager(manager: CLLocationManager!, didDetermineState state: CLRegionState, forRegion region: CLRegion!) {
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
    
    func mapViewDidFinishLoadingMap(mapView: MKMapView!) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))   {
            var locations : [CWMapLocation]  = CWMapLocation.getLocs()
            
            for location : CWMapLocation in locations   {
                dispatch_async(dispatch_get_main_queue())   {
                    mapView.addAnnotation(location.annotation())
                }
                self.theLocations[location.name] = location
                self.theLocationsArray.append(location)
            }
            
            self.locationManager = CLLocationManager()
            self.locationManager!.delegate   = self
            self.locationManager!.desiredAccuracy    = kCLLocationAccuracyKilometer
            self.locationManager!.distanceFilter     = 500
            
            if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.NotDetermined  {
                self.locationManager!.requestWhenInUseAuthorization()
            }
            
            dispatch_async(dispatch_get_main_queue())   {
                if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedAlways ||
                    CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedWhenInUse    {
                        self.locationManager!.startUpdatingLocation()
                        self.calculateDistances(nil)
                }
                else    {
                    self.theTable!.reloadData()
                }
                
                
            }
        }
    }
    
    /*
    func distanceTo(location : CWMapLocation) -> CLLocationDistance   {
        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedAlways || CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedWhenInUse && CLLocationManager.locationServicesEnabled()    {
            var currentLocation = locationManager!.location
            return location.distance(currentLocation)
        }
        
        return CLLocationDistance.infinity
    }   */
    
    
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        var location : CWMapLocation    = theLocations[view.annotation.title!]!
        var message = location.address()
        
        var distMsg = location.distanceString()
        if distMsg != nil   {
            message += "\n" + distMsg!
        }
        
        performSegueWithIdentifier("pushDetail", sender: location)
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section != 0 {
            return 0
        }
        else    {
            return theLocations.count
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
        
        if location != nil {
            if let detailVC = segue.destinationViewController as? DetailViewController  {
                detailVC.location   = location
            }
        }
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
}

