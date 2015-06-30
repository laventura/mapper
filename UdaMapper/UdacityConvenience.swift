//
//  UdacityConvenience.swift
//  UdaMapper
//
//  Created by Atul Acharya on 6/26/15.
//  Copyright (c) 2015 Atul Acharya. All rights reserved.
//

import Foundation
import UIKit

/*  Annoyance:
    For NSURLSessionTasks, rename the resume() function to start(),
    which is what Apple should have called it
*/
extension NSURLSessionTask {
    func start() {
        self.resume()
    }
}

extension UdacityClient {
    
    
    // Authenticate to Udacity; get this Users's account
    func authenticateUdacityWithViewController(hostViewController: LoginViewController, completionHandler: (success: Bool, errorString: String?) -> Void) {
     
        /* 1. TODO: Check network connectivity !!
            If no connectivity, indicate on the LoginVC
        */
        
        
        //
        if (hostViewController.usernameField.text != nil && hostViewController.passwordField.text != nil) {
            hostViewController.showIndicator(true)  // indicate status on VC
            // 3. get a new Session ID
            self.getSessionID(hostViewController.usernameField.text, password: hostViewController.passwordField.text) { (result, error) -> Void in
                
                if (result != nil) {
                    // 4. get this Users's account info
                    self.getUserData(self.uniqueKey!) { theAccount, errorString in
                        
                        if theAccount != nil {
                            // println("=> Logged in: \(theAccount)")
                            hostViewController.showIndicator(false)
                            completionHandler(success: true, errorString: nil)
                        }
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        //
                        hostViewController.showIndicator(false) // indicate status on VC
                        completionHandler(success: false, errorString: "Could not authenticate user/password")
                    })
                }
                
            }
            
        }
        
    } // func
    
    // POST - create a Student Location Info
    func saveStudentLocation(student: StudentInfo, completionHander: (result: Bool?, error: NSError?)->Void) {
        var method = Methods.StudentLocations
        
        // NOTE: jsonBody does NOT include objectId (for the "first creation" of new location (obviously)
        // all subsequent updates include the objId
        let jsonBody: [String:AnyObject] = [
            JsonBody.uniqueKey: student.uniqueKey!,
            JsonBody.firstName: student.firstName,
            JsonBody.lastName:  student.lastName,
            JsonBody.mapString: student.mapString!,
            JsonBody.mediaURL:  student.mediaURL!,
            JsonBody.latitude:  student.latitude!,
            JsonBody.longitude: student.longitude!
        ]
        
        let task = taskForPOSTMethod(method, isParse: true, parameters: nil, jsonBody: jsonBody) { (JSONResult, error) -> Void in
            
            if let error = error {
                completionHander(result: false, error: error)
            } else {
                if let results = JSONResult.valueForKey(JsonResponse.ObjectId) as? String {
                    completionHander(result: true, error: nil)
                } else {
                    completionHander(result: nil,
                        error: NSError(domain: "saveStudentLocaiton", code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "Couldn't parse response from saveStudentLocation"]))
                }
                
            }
        }
    } // func
    
    // Update existing Student Location Info
    func updateStudentLocation(student: StudentInfo, completionHander: (result: Bool?, error: NSError?)->Void) {
        
        // append the Student's obj id... for the Update method
        var method = Methods.StudentLocations + "/" + student.objectId!
        
        let jsonBody: [String:AnyObject] = [
            JsonBody.uniqueKey: student.uniqueKey!,
            JsonBody.firstName: student.firstName,
            JsonBody.lastName:  student.lastName,
            JsonBody.objectId:  student.objectId!,
            JsonBody.mapString: student.mapString!,
            JsonBody.mediaURL:  student.mediaURL!,
            JsonBody.latitude:  student.latitude!,
            JsonBody.longitude: student.longitude!
        ]
        
        let task = taskForPOSTMethod(method, isParse: true, parameters: nil, jsonBody: jsonBody) { (JSONResult, error) -> Void in
            
            if let error = error {
                completionHander(result: false, error: error)
            } else {
                if let results = JSONResult.valueForKey(JsonResponse.UpdatedAt) as? String {
                    completionHander(result: true, error: nil)
                } else {
                    completionHander(result: nil,
                        error: NSError(domain: "updateStudentLocation", code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "Couldn't parse response from updateStudentLocation"]))
                }
                
            }
        }

        
    } // func
    
    // Search Student Location. Needs uniqueKey
    func searchStudentLocation(uniqueKey: String, completionHander: (result: StudentInfo?, error: String?)->Void) {
        var parameters = [String:AnyObject]()
        // Todo: fix kludge below!!
        
        // https://api.parse.com/1/classes/StudentLocation?where=%7B%22uniqueKey%22%3A%22XYZXYZ%22%7D       // CORRECT
        // https://api.parse.com/1/classes/StudentLocation?where=%257B%2522uniqueKey%2522%253A%2522XYZXYZ%2522%257D // INCORRECT

        // NOTE: Query Format is:  "?where={"uniqueKey":"XYZXYZ"}"
        
        var method = Methods.StudentLocations + "?where=" + "%7B%22uniqueKey%22%3A%22\(uniqueKey)%22%7D"    // KLUDGE!!
        
        let task = taskForGETMethod(method, isParse: true, parameters: nil) { (JSONResult, error) -> Void in
         
            if let error = error {
                completionHander(result: nil, error: "Search query error: \(error)")
            } else {
                if let results = JSONResult.valueForKey(JsonResponse.Results) as? [[String:AnyObject]] {
                    var student: StudentInfo?
                    if results.count > 0 {
                        student = StudentInfo(dictionary: results[results.count-1]) // get the last (hopefully latest) record
                        UdacityClient.sharedInstance().account = student    // save
                    } else {
                        student = nil
                    }
                    completionHander(result: student, error: nil)
                } else {
                    completionHander(result: nil, error: "Failure with search query")
                }
                
            }
            
        }
        
    } // func
    
    // Get Student Locations - fetching for limit number of records, and starting with 'skip'
    func getStudentLocations(let limit:Int, let skip:Int, completionHandler: (result: [StudentInfo]?, error: String?)->Void) {
        
        // Parameters
        var parameters = [String:AnyObject]()
        parameters["limit"] = limit
        parameters["skip"]  = skip
        var method  = Methods.StudentLocations
        
        // 2. make the GET request
        let task = taskForGETMethod(method, isParse: true, parameters: parameters) { (JSONResult, error) -> Void in
            
            // send value to handler
            if let erorr = error {
                completionHandler(result: nil, error: "Failure getting Student Locations")
            } else {
                if let results = JSONResult.valueForKey(JsonResponse.Results) as? [[String:AnyObject]] {
                    var studentArray = StudentInfo.studentsFromResults(results)
                    if let _ = self.students {
                        self.students! += studentArray
                    } else {
                        self.students   = studentArray
                    }
                    completionHandler(result: studentArray, error: nil)
                } else {
                    completionHandler(result: nil, error: "Couldnt find student results array in response")
                }
            }
        }
    } // func
    
    
    // Get Student data. Dont need sessionID; pass in our uniqueKey to Udacity
    func getUserData(uniqueKey: String, completionHandler: (result: StudentInfo?, error: String?) -> Void) {
        var method = Methods.UserData + uniqueKey
        
        // var parameters  = [String:AnyObject]()
        
        let task = taskForGETMethod(method, isParse: false, parameters: nil) { (JSONResult , error) -> Void in
            
            if let error = error {
                completionHandler(result: nil, error: "Couldn't get User info")
            } else {
                if let lastname = JSONResult.valueForKey(JsonResponse.User)?.valueForKey(JsonResponse.LastName) as? String {
                    if let firstname = JSONResult.valueForKey(JsonResponse.User)?.valueForKey(JsonResponse.FirstName) as? String {
                        if let userKey = JSONResult.valueForKey(JsonResponse.User)?.valueForKey(JsonResponse.Key) as? String {
                            self.account = StudentInfo(uniqueKey: userKey, firstName: firstname, lastName: lastname)
                            completionHandler(result: self.account!, error: nil)
                        }
                    }
                } else {
                    completionHandler(result: nil, error: "Failure getting User info")
                }
            }
            
        } // task
        
    } // func
    
    
    
    
    // Get a new Udacity Session ID; store sessionID and Key, and return sessionID in completion handler
    func getSessionID(username: String, password: String, completionHandler: (result: String?, error: NSError?) -> Void) {
        
        // Parameters
        var method                              = Methods.AuthNewSession
        let userCredentials: [String:AnyObject] = [JsonBody.username: username, JsonBody.password: password]
        let jsonBody: [String:AnyObject]        = [JsonBody.udacity: userCredentials]
        
        // make request; goes to Udacity, not Parse
        let task = taskForPOSTMethod(method, isParse: false, parameters: nil, jsonBody: jsonBody) { (JSONresult, error) -> Void in
            
            // pass on to completion handler
            if let error = error {
                completionHandler(result: nil, error: error)
            } else {
                if let results = JSONresult.valueForKey(JsonResponse.Session)?.valueForKey(JsonResponse.Id) as? String {
                    self.sessionID = results    // Store the Session Id
                    // println("## Session id:\(self.sessionID!)")
                    if let key = JSONresult.valueForKey(JsonResponse.Account)?.valueForKey(JsonResponse.Key) as? String {
                        self.uniqueKey = key
                        // println("## Uniq Key:\(self.uniqueKey!)")
                    }
                    completionHandler(result: results, error: nil)
                } else {
                    completionHandler(result: nil, error: NSError(domain: "getSessionID parsing", code: 0, userInfo: [NSLocalizedDescriptionKey : "Could not parse"]))
                }
                
            }
        }
    
    } // end func
    
    
} // extension
