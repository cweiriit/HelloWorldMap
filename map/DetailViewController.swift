//
//  DetailViewController.swift
//  map
//
//  Created by Clinton Weir on 4/2/15.
//  Copyright (c) 2015 HelloWorld-ClintonW. All rights reserved.
//

import UIKit
import MapKit

class DetailViewController: UIViewController, MKMapViewDelegate {
    var location : CWMapLocation?
    
    @IBOutlet weak var theMap : MKMapView?
    @IBOutlet weak var theTextField : UILabel?
    @IBOutlet weak var theImage : UIImageView?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if location != nil  {
            if theTextField != nil  {
                theTextField!.text  = location!.detailText()
                theTextField!.adjustsFontSizeToFitWidth = true
            }
            
            if theImage != nil  {
                if location!.image != nil   {
                    theImage!.image = location!.image
                }
                else    {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))   {
                        var imageUrl    = NSURL(string: self.location!.imUrl)
                        var imageData : NSData?
                        var image : UIImage?
                        if imageUrl != nil  {
                            imageData   = NSData(contentsOfURL: imageUrl!)
                        }
                        if imageData != nil {
                            image       = UIImage(data: imageData!)
                        }
                        if image != nil {
                            self.location!.image = image!
                            dispatch_async(dispatch_get_main_queue())   {
                                self.theImage!.image = image!
                            }
                        }
                    }
                }
            }
            
            if theMap != nil    {
                theMap!.removeAnnotations(theMap!.annotations)
                theMap!.addAnnotation(location!.annotation())
                var coords  = CLLocationCoordinate2D(latitude: location!.locLat, longitude: location!.locLon)
                theMap!.setRegion(MKCoordinateRegionMake(coords, MKCoordinateSpanMake(0.01, 0.01)), animated: false)
                theMap!.zoomEnabled     = false
                theMap!.scrollEnabled   = false
                theMap!.rotateEnabled   = false
            }
        }
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        var output : MKAnnotationView   = MKAnnotationView(annotation: annotation, reuseIdentifier: nil)
        output.image    = UIImage(contentsOfFile: NSBundle.mainBundle().pathForResource("HWMapMarker", ofType: "png")!)
        return output
    }

    @IBAction func callNumber(sender: UIButton) {
        if location != nil  {
            var numberToCall    = location!.phone.stringByReplacingOccurrencesOfString(" ", withString: "", options: NSStringCompareOptions.allZeros, range: nil)
            
            var url = NSURL(string: "tel://" + numberToCall)
            if url != nil   {
                UIApplication.sharedApplication().openURL(url!)
            }
        }
        
        
    }
    
    @IBAction func getDirections(sender: UIButton) {
        var coords  = CLLocationCoordinate2D(latitude: location!.locLat, longitude: location!.locLon)
        var place : MKPlacemark = MKPlacemark(coordinate: coords, addressDictionary: nil)
        var destination : MKMapItem = MKMapItem(placemark: place)
        destination.name    = location!.name
        var options = NSDictionary(objectsAndKeys: MKLaunchOptionsDirectionsModeDriving, MKLaunchOptionsDirectionsModeKey)
        MKMapItem.openMapsWithItems([destination], launchOptions: options)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
