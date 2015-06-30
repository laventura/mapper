//
//  LinkViewController.swift
//  UdaMapper
//
//  Created by Atul Acharya on 6/29/15.
//  Copyright (c) 2015 Atul Acharya. All rights reserved.
//

import UIKit
import MapKit

class LinkViewController: UIViewController {
    
    @IBOutlet weak var urlField: UITextField!
    @IBOutlet weak var splashImageView: UIImageView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var mapView: MKMapView!
    
    var gestureRecognizer: UITapGestureRecognizer!
    var locationText: String?    = nil     // set by LocationVC
    var thePlacemark: MKPlacemark? = nil

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        handleActivityIndicator(false) // hide initially
        gestureRecognizer = UITapGestureRecognizer(target: self, action: "handleTap:")
        gestureRecognizer.numberOfTapsRequired = 1

        self.navigationItem.title = "Your URL"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: "cancel")
        self.navigationItem.hidesBackButton = true
        
        // make the Submit button more visible - change bg
        // submitButton.backgroundColor = UIColor.whiteColor()
        submitButton.setTitle(" Submit URL ", forState: UIControlState.Normal)  // increase the size
        submitButton.alpha = 0.8
        submitButton.layer.cornerRadius = 10.0
        
         splashImageView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.70)
    }

    override func viewWillAppear(animated: Bool) {
        self.addTapGestureRecognizer()
        // show the user's entered location, and center on the map
        self.showInitialMap()
    }
    
    override func viewWillDisappear(animated: Bool) {
        
        self.removeTapGestureRecognizer()
    }
    
    
    // MARK: - Keyboard
    
    func addTapGestureRecognizer() {
        self.view.addGestureRecognizer(gestureRecognizer!)
    }
    
    func removeTapGestureRecognizer() {
        self.view.removeGestureRecognizer(gestureRecognizer!)
    }
    
    func handleTap(recognizer: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    // MARK: - Actions
    func cancel() {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func submitPressed(sender: UIButton) {
        // TODO: network Reachability
        
        // a. check URL not malformed
        if !checkValidURL(urlField.text) {
            showAlert("Invalid URL\n\(urlField.text)\nPlease enter valid URL")
        } else {
            if thePlacemark == nil {
                showAlert("No valid location found. Please enter again.")
            } else {    // let's get the newly entered data...
                UdacityClient.sharedInstance().account?.mapString   = locationText
                UdacityClient.sharedInstance().account?.mediaURL    = urlField.text
                UdacityClient.sharedInstance().account?.longitude   = thePlacemark!.coordinate.longitude
                UdacityClient.sharedInstance().account?.latitude    = thePlacemark!.coordinate.latitude
                
                // println(".. Trying to update: \(UdacityClient.sharedInstance().account!)")
                
                if let objectID = UdacityClient.sharedInstance().account?.objectId {
                    // record exists, update it
                    // println("... LinkVC: record exists... Updating it")
                    UdacityClient.sharedInstance().saveStudentLocation(
                        UdacityClient.sharedInstance().account!) { (result, error) -> Void in
                        
                            if error != nil {
                                dispatch_async(dispatch_get_main_queue(),{
                                    self.showAlert("Could not update Location")
                                })
                            } else if let ok = result { // something returned
                                
                                if ok {     // Successfully updated.
                                    // println(".. Success Updated: \(UdacityClient.sharedInstance().account!)")
                                    dispatch_async(dispatch_get_main_queue(),{
                                        var alert = UIAlertController(title: "Info Updated",
                                            message: "New record:\n" +
                                            "url: \(UdacityClient.sharedInstance().account!.mediaURL!)\n" +
                                            "loc: \(UdacityClient.sharedInstance().account!.mapString!)" ,
                                            preferredStyle: UIAlertControllerStyle.Alert)
                                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: self.cancelAlert))
                                        self.presentViewController(alert, animated: true, completion: nil)
                                    })
                                } else { // not OK
                                    dispatch_async(dispatch_get_main_queue(),{
                                        self.showAlert("Could not update location")
                                    })
                                }
                            }
                    }
                } else { // need to create new record
                    // println("... LinkVC creating new record...")
                    UdacityClient.sharedInstance().saveStudentLocation(
                        UdacityClient.sharedInstance().account!) { (result, error) -> Void in
                        if error != nil {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.showAlert("Could not save location info")
                            })
                        } else if let ok = result { // non null
                            if ok {     // Saved: all OK
                                // println(".. Success created: \(UdacityClient.sharedInstance().account!)")
                                dispatch_async(dispatch_get_main_queue(),{
                                    var alert = UIAlertController(title: "Info Saved",
                                        message: "New record:\n" +
                                            "url: \(UdacityClient.sharedInstance().account!.mediaURL!)\n" +
                                            "loc: \(UdacityClient.sharedInstance().account!.mapString!)" ,
                                        preferredStyle: UIAlertControllerStyle.Alert)
                                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: self.cancelAlert))
                                    self.presentViewController(alert, animated: true, completion: nil)
                                })
                            } else {    // not OK
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    self.showAlert("Could NOT save location")
                                })
                            }
                        }
                        
                    }
                    
                }
                
            }
        }
    } // submit
    
    // Check for valid URL; return false if not
    // Kludge: Brute force conversion to NSURL obj
    func checkValidURL(var urlString: String) -> Bool {
        // a. check ! "Enter..."
        // b. check it's a valid NSURL object

        var rv = false
        if urlString != "" {
            if (count(urlString) < 7) {     // ensure atleast 7 chars
                return false
            }
            // ensure 'http://'
            if ( urlString.substringWithRange(Range<String.Index>(start: advance(urlString.startIndex, 0), end: advance(urlString.startIndex, 7))) != "http://" ) {
                return false
            }
            // ensure valid URL object
            let theUrl = NSURL(string: urlString)
            if let okUrl = theUrl {     // NSURL object ensures that only a valid urlString can convert to a non-null obj
                rv = true   // it's a valid URL
            } else {
                rv = false
            }
        }
        return rv
    }
    
    // Cancel action from an Alert view
    func cancelAlert(var action:UIAlertAction! ){
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    func handleActivityIndicator(show:Bool) {
        if show {   // Unhide
            splashImageView.hidden = false
            activityIndicator.hidden = false
            activityIndicator.startAnimating()
        } else {    // hide indicator
            activityIndicator.stopAnimating()
            activityIndicator.hidden = true
            splashImageView.hidden = true
            
        }
    }
    
    // MARK: - Helper
    
    // Try to geocode the Address user entered in the LocationVC, and show on Map
    func showInitialMap() {
        if let theAddress = locationText {
            var geocoder = CLGeocoder()
            handleActivityIndicator(true)
            geocoder.geocodeAddressString(theAddress, completionHandler: { (placemarks:[AnyObject]!, error:NSError!) -> Void in
                
                if let error = error {
                    var alert = UIAlertController(title: "Fail", message: "Geocoding failed", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: self.cancelAlert))
                    self.presentViewController(alert, animated: true, completion: nil)
                    
                } else {
                    if let aPlacemark = placemarks?[0] as? CLPlacemark {
                        self.mapView.addAnnotation(MKPlacemark(placemark: aPlacemark))
                        self.thePlacemark = MKPlacemark(placemark: aPlacemark)
                        
                        let span = MKCoordinateSpanMake(3, 3)   // tight span
                        let region = MKCoordinateRegion(center: self.thePlacemark!.location.coordinate, span: span)
                        self.mapView.setRegion(region, animated: true)
                        // TODO: setCamera ?
                        self.activityIndicator.startAnimating()
                    }
                }
                self.handleActivityIndicator(false)
            })
            
        }
        
    } // func
    
    //Displays an alert with the OK button and a message
    func showAlert(message:String){
        var alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }


}
