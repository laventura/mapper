//
//  LoginViewController.swift
//  UdaMapper
//
//  Created by Atul Acharya on 6/27/15.
//  Copyright (c) 2015 Atul Acharya. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var newAccountButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var infoLabel: UILabel!
    
    var gestureRecognizer: UITapGestureRecognizer!
    
    // TODO: add Reachability vars
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // hide
        infoLabel.hidden = true
        activityIndicator.hidden = true
        
        gestureRecognizer = UITapGestureRecognizer(target: self, action: "handleTap:")
        gestureRecognizer.numberOfTapsRequired = 1
        
        // TODO: Reachability inits here
        
        
    }
    
    override func viewWillAppear(animated: Bool) {
        
        self.addTapGestureRecognizer()
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
    @IBAction func loginPressed(sender: UIButton) {
        self.view.endEditing(true)
        if  usernameField.text != nil && usernameField.text != "" &&
            passwordField.text != nil && passwordField.text != "" {
                UdacityClient.sharedInstance().authenticateUdacityWithViewController(self) { (success, errorString) -> Void in
                    if success {
                        self.completeLogin()
                    } else {
                        self.showInfo(errorString!)
                    }
                    
                }
        }
    }

    
    @IBAction func newAccountButtonPressed(sender: UIButton) {
        showInfo("Opening browser to Udacity...")
        var request = NSURLRequest(URL: NSURL(string: "https://www.udacity.com/account/auth#!/signup")!)
        UIApplication.sharedApplication().openURL(request.URL!)
    }
    
    
    
    func completeLogin() {
        println("## completeLogin: called")
        showIndicator(false)
        
        // TODO: Launch the TabBarController
        dispatch_async(dispatch_get_main_queue(), {
            self.infoLabel.text = ""
            let controller = self.storyboard!.instantiateViewControllerWithIdentifier("MainTabBarController") as! UITabBarController
            self.presentViewController(controller, animated: true, completion: nil)
        })
    }
    
    func showError(message: String?) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if let error = message {
                println("LoginVC: error: \(error)")
                self.showInfo(error)
            }
            
        })
    }
    
    // Turn ActivityIndicator ON/OFF
    func showIndicator(turnOn: Bool) {
        if turnOn {
            activityIndicator.hidden = false
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
            activityIndicator.hidden = true
        }
    }
    
    // Display an informational msg on the infoLabel; msg disappears after a short while
    func showInfo(message: String) {
        infoLabel.hidden = false
        infoLabel.text = message
        
        let delay = 2.5 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
                    self.infoLabel.hidden = true
        }
    }
    
    //Displays an alert with the OK button and a message
    func showAlert(message:String){
        var alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }


}
