//
//  MapViewController.swift
//  UdaMapper
//
//  Created by Atul Acharya on 6/28/15.
//  Copyright (c) 2015 Atul Acharya. All rights reserved.
//

import UIKit
import MapKit
import Social


class MapViewController: UIViewController, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    var logoutButton    = UIBarButtonItem()
    var locationButton  = UIBarButtonItem()  // Save Student's location, etc
    var refreshButton   = UIBarButtonItem()
    var tweetButton     = UIBarButtonItem()  // Tweet student info
    var moreButton      = UIBarButtonItem() // more locations
    var doUpdate        = false // whether new or update of Student info entry
    var numStudents     = 0     // num of Students
    var annotations     = [MKPointAnnotation]() // store Pin annotations
    
    let twitterService  = SLServiceTypeTwitter
    

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshButton   = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: "doRefresh")
        locationButton  = UIBarButtonItem(image: UIImage(named: "PinEmpty"), landscapeImagePhone: UIImage(named: "PinEmpty"), style: UIBarButtonItemStyle.Plain, target: self, action: "doNewLocation")
        logoutButton    = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Stop, target: self, action: "doLogout")
        tweetButton     = UIBarButtonItem(image: UIImage(named: "Twitter"), landscapeImagePhone: UIImage(named: "Twitter"), style: UIBarButtonItemStyle.Plain, target: self, action: "doTweet")
        moreButton      = UIBarButtonItem(image: UIImage(named: "Download"), landscapeImagePhone: UIImage(named: "Download"), style: UIBarButtonItemStyle.Plain, target: self, action: "doLoadMoreLocations")
        
        self.navigationItem.hidesBackButton = true
        self.navigationItem.rightBarButtonItems = [locationButton, refreshButton]
        self.navigationItem.leftBarButtonItems  = [logoutButton, tweetButton, moreButton]
        
        self.navigationItem.title = "Map"
        self.mapView.delegate     = self
        
        // Center
        let center = CLLocationCoordinate2D(latitude: 39.8281421, longitude: -98.5796298)   // geo center of US; we need *something*
        let span    = MKCoordinateSpanMake(60, 60)
        let region  = MKCoordinateRegion(center: center, span: span)
        self.mapView.setRegion(region, animated: true)
        // Fetch init results to display
        doLoadMoreLocations()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        // TODO: Reachability - test Network connectivity; proceed if all OK
        
        /*--
        if let _ = UdacityClient.sharedInstance().students {
            self.mapView.removeAnnotations(annotations)     // clear out initial pins
            annotations = []
            self.showAnnotations(UdacityClient.sharedInstance().students!)  // reload
        }
        --*/
        doRefresh()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions
    func doLogout() {
        // TODO: Facebook Logout - for later
        
        UdacityClient.sharedInstance().students = nil
        UdacityClient.sharedInstance().account  = nil
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    func doRefresh() {
        
        let reachability = Reachability.reachabilityForInternetConnection()
        
        // check Network first
        if reachability.isReachable() {
            // fetch more results
            self.mapView.removeAnnotations(annotations)
            numStudents = 0
            annotations = []
            UdacityClient.sharedInstance().students = nil
            doLoadMoreLocations()       // fetch more Locations
        } else {
            showAlert(UdacityClient.Msg.kNetworkUnreachableMsg)
        }
    }
    
    // Post a tweet, if Twitter account enabled on device; do initial text setup
    func doTweet() {
        if SLComposeViewController.isAvailableForServiceType(twitterService) {
            let controller = SLComposeViewController(forServiceType: twitterService)
            
            var initText = "Working on #Udacity #Swift course "
            if let mapS = UdacityClient.sharedInstance().account!.mapString {
                initText += " from \(mapS)"
            }
            initText += "\n"
            controller.setInitialText(initText)
            
            controller.completionHandler = {(result: SLComposeViewControllerResult) in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    switch(result) {
                    case .Cancelled: println("Cancelled tweet")
                    case .Done:
                        println("Successfuly posted tweet!")
                    }
                })
            }
            self.presentViewController(controller, animated: true, completion: nil)
            
        } else {
            showAlert("Twitter account not enabled in Settings")
        }
        
    }

    // Create or Update a Location record
    func doNewLocation() {
        
        let reachability = Reachability.reachabilityForInternetConnection()
        
        // check NW connectivity first
        if reachability.isReachable() {
            
            let myKey = UdacityClient.sharedInstance().account!.uniqueKey!
            UdacityClient.sharedInstance().searchStudentLocation(myKey) { (result, errorStr) -> Void in
                if let errS = errorStr {
                    self.showAlert("Could not query student (key:\(myKey))\nError: \(errS)")
                } else {
                    if result != nil {      // UPDATE existing record
                        // display Alert - allow only when user explicitly says so
                        dispatch_async(dispatch_get_main_queue()) {
                            // show some useful alert, if existing record
                            let mapS = result?.mapString!
                            let lat  = result?.latitude!
                            let long = result?.longitude!
                            var alert = UIAlertController(title: "Location record exists",
                                message: "Current: \(mapS!) (\(lat!),\(long!))\nOverwrite location?",
                                preferredStyle: UIAlertControllerStyle.Alert)
                            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
                            alert.addAction(UIAlertAction(title: "Overwrite", style: UIAlertActionStyle.Default, handler: self.overwrite))
                            
                            self.navigationController!.presentViewController(alert, animated: true, completion: { () -> Void in
                                return()
                            })
                        }
                    } else {        // CREATE NEW record
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.showLocationViewController()
                        })
                        
                    }
                }   // result non-nil
            } // search
        } else {
            showAlert(UdacityClient.Msg.kNetworkUnreachableMsg)
        }
        
    }
    
    // MARK: - MapView
    // OPen the system browser at the Student's mediaURL contained in annotation's subtitle
    // check for malfored URLs
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        
        if control == view.rightCalloutAccessoryView {
            let mediaURL = view.annotation.subtitle!
            // println("  [MapVC: trying URL: \(mediaURL)")
            if let url = NSURL(string: mediaURL) {
                var request = NSURLRequest(URL: url)
                UIApplication.sharedApplication().openURL(request.URL!)
            } else {
                // Handle malformed URL -
                // NOTE: there's a tendency to put spaces in URLs for testing - which will cause malformed URLs
                self.showAlert("Cannot open site:\nMalformed URL:[\(mediaURL)]")
            }
        }
    }
    
    // Here we create a view with a "right callout accessory view".
    // A student's URL is included in the annotation's subtitle
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        let reuseID = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseID) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView!.canShowCallout = true
            pinView!.animatesDrop   = true
            pinView!.pinColor       = .Red
            pinView!.rightCalloutAccessoryView = UIButton.buttonWithType(.DetailDisclosure) as! UIButton
        } else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    
    // MARK: - Helper
    
    // get next batch of Student Info Locations
    func doLoadMoreLocations() {
        
        let reachability = Reachability.reachabilityForInternetConnection()
        
        if reachability.isReachable() {
        
            UdacityClient.sharedInstance().getStudentLocations(100, skip: numStudents) { (result, errorS) -> Void in
                if let errs = errorS {
                    self.showAlert("Couldn't fetch more student locations...")
                } else {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if result != nil {
                            self.numStudents += result!.count
                            self.showAnnotations(result!)
                        }
                        return
                    })
                }
            }
        } else {
            showAlert(UdacityClient.Msg.kNetworkUnreachableMsg)
        }
    }
    
    // Show given array of Student locations onto the map
    func showAnnotations(students:[StudentInfo]) {
        
        for student in students {
            let theLocation = CLLocationCoordinate2D(latitude: student.latitude!, longitude: student.longitude!)
            let annotation = MKPointAnnotation()
            annotation.coordinate = theLocation
            annotation.title = student.firstName + " " + student.lastName
            annotation.subtitle = student.mediaURL
            
            self.annotations += [annotation]
            self.mapView.addAnnotation(annotation)
        }
    }

    
    //Displays an alert with the OK button and a message
    func showAlert(message:String){
        var alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func showLocationViewController() {
        let destinationController = self.storyboard!.instantiateViewControllerWithIdentifier("LocationViewController") as! LocationViewController
        destinationController.doUpdate = self.doUpdate
        
        let tmpNavController = UINavigationController(rootViewController: destinationController)
        
        self.navigationController!.presentViewController(tmpNavController, animated: true) { () -> Void in
            self.navigationController!.popViewControllerAnimated(true)
            return
        }
    }
    
    // allow Overwrite of User Location info
    func overwrite(alert:UIAlertAction!) {
        self.doUpdate = true
        self.showLocationViewController()
    }

    


}
