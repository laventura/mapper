//
//  TableViewController.swift
//  UdaMapper
//
//  Created by Atul Acharya on 6/28/15.
//  Copyright (c) 2015 Atul Acharya. All rights reserved.
//

import UIKit
import Social

class TableViewController: UITableViewController, UITableViewDataSource,UITableViewDelegate  {
    
    var logoutButton    = UIBarButtonItem()
    var locationButton  = UIBarButtonItem()  // Save Student's location, etc
    var refreshButton   = UIBarButtonItem()
    var tweetButton     = UIBarButtonItem()  // Tweet student info: Is this the right place??
    var doUpdate        = false // whether new or update of Student info entry
    var numStudents     = 0     // num of Students
    
    let twitterService  = SLServiceTypeTwitter


    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshButton   = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: "doRefresh")
        locationButton  = UIBarButtonItem(image: UIImage(named: "PinEmpty"), landscapeImagePhone: UIImage(named: "PinEmpty"), style: UIBarButtonItemStyle.Plain, target: self, action: "doNewLocation")
        logoutButton    = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Stop, target: self, action: "doLogout")
        tweetButton     = UIBarButtonItem(image: UIImage(named: "Twitter"), landscapeImagePhone: UIImage(named: "Twitter"), style: UIBarButtonItemStyle.Plain, target: self, action: "doTweet")
        
        // try reloading these files first
        UIImage(contentsOfFile: "PinEmpty")
        UIImage(contentsOfFile: "Twitter")

        self.navigationItem.hidesBackButton = true
        self.navigationItem.rightBarButtonItems = [locationButton, refreshButton]
        self.navigationItem.leftBarButtonItems  = [logoutButton, tweetButton]
        
        self.navigationItem.title = "Students"
        
        // TODO: Reachability stuff
    }
    
    // MARK: - Actions
    func doLogout() {
        println("  [TableVC: logout called]")
        
        // TODO: Facebook Logout - for later
        
        UdacityClient.sharedInstance().students = nil
        UdacityClient.sharedInstance().account  = nil
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    // Post new location update; first check if record exists
    func doNewLocation() {
        println("  [TableVC: doNewLocation called]")
        
        // TODO: Reachability test
        
        let myKey = UdacityClient.sharedInstance().account!.uniqueKey!
        UdacityClient.sharedInstance().searchStudentLocation(myKey) { (result, errorStr) -> Void in
            if let errS = errorStr {
                self.showAlert("Could not query student (key:\(myKey))\nError: \(errS)")
            } else {
                if result != nil {      // Update existing record
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
                } else {        // Create New record; segue to LocationVC
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.showLocationViewController()
                    })
                    
                }
                
            }
            
        } // search
        
    }
    
    // Post a tweet, if Twitter account enabled on device
    func doTweet() {
        println("  [TableVC: Tweet called]")
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
            showAlert("Twitter service not enabled in Settings")
        }

        
    }
    
    func doRefresh() {
        // TODO: Reachability stuff - check NW status
        
        // fetch more results
        numStudents = 0
        UdacityClient.sharedInstance().students = nil   // should we?
        loadMoreStudents()
    }
    
    // get next batch of Student Info
    func loadMoreStudents() {
        // TODO: Reachability stuff?
        UdacityClient.sharedInstance().getStudentLocations(100, skip: numStudents) { (result, errorS) -> Void in
            if let errs = errorS {
                self.showAlert("Couldn't fetch more Student Info...")
            } else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if result != nil {
                        if result!.count > 0 {
                            self.tableView.reloadData()
                        }
                    }
                    return
                })
            }
        }
    }


    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let stu = UdacityClient.sharedInstance().students {
            numStudents = stu.count
        }
        return numStudents
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("UDTableViewCell", forIndexPath: indexPath) as! UITableViewCell

        var studentInfo = StudentInfo(uniqueKey: "tmp", firstName: "tmp", lastName: "tmp")
        
        // fetch the student info
        if let aStudent = UdacityClient.sharedInstance().students?[indexPath.row] {
            studentInfo = aStudent
        }
    
        // Configure the cell...
        cell.textLabel?.text = studentInfo.firstName + " " + studentInfo.lastName
        cell.imageView?.image = UIImage(named: "PinFilled")
        
        if (indexPath.row == UdacityClient.sharedInstance().students!.count-1) {
            loadMoreStudents()
        }

        return cell
    }
    
    // Open Browser - at the mediaURL of the selected Student
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println("  [TableVC: selected row: \(indexPath.row)]")
        
        
        let theStudent  = UdacityClient.sharedInstance().students![indexPath.row]
        println(theStudent)

        let mediaUrl    = theStudent.mediaURL!
        if let url  = NSURL(string: mediaUrl)  {    // Ensure url is not malformed
        
            let request     = NSURLRequest(URL: url)
            
            println("  [TableVC: invoking URL: [\(mediaUrl)]]")
            // Finally - open the Browser at the mediaURL location
            // UNCOMMENT NEXTLINE
            UIApplication.sharedApplication().openURL(request.URL!)
                
        } else  {
            self.showAlert("Cannot open site\nMalformed URL: [\(mediaUrl)]")
        }
        
    }


    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return false
    }
    

    
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return false
    }
    
    
    // MARK: - Helper
    
    //Displays an alert with the OK button and a message
    func showAlert(message:String){
        var alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // Segue to LocationVC to create a new/update existing Location Info
    func showLocationViewController() {
        println("... [TableVC] Invoking LocationVC to Create/Update New Location Info")
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
