//
//  LocationViewController.swift
//  UdaMapper
//
//  Created by Atul Acharya on 6/29/15.
//  Copyright (c) 2015 Atul Acharya. All rights reserved.
//

import UIKit
import MapKit

class LocationViewController: UIViewController {
    
    var gestureRecognizer: UITapGestureRecognizer!
    var doUpdate    = false // pass thru from TableVC or MapVC

    @IBOutlet weak var locationField: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var findMapButton: UIButton!
    
    let segueID = "segueToLinkViewController"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        gestureRecognizer = UITapGestureRecognizer(target: self, action: "handleTap:")
        gestureRecognizer.numberOfTapsRequired = 1
        
        self.navigationItem.title = "Enter Location"

        self.navigationController?.navigationBar.translucent = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: "cancelPressed")
        self.navigationItem.hidesBackButton = true          // make it false??
        self.navigationController?.toolbar.hidden = true

        activityIndicator.hidden = true
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
    func cancelPressed() {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let id = segue.identifier {
            if id == segueID {
                let destinationController = segue.destinationViewController as! LinkViewController
                destinationController.locationText = locationField.text
            }
        }
    }


}
