//
//  UdacityClient.swift
//  UdaMapper
//
//  Created by Atul Acharya on 6/26/15.
//  Copyright (c) 2015 Atul Acharya. All rights reserved.
//

import Foundation
import UIKit

class UdacityClient: NSObject {
    
    /* shared session */
    var session:    NSURLSession
    
    var sessionID:  String?
    var uniqueKey:  String?
    var students:   [StudentInfo]?
    var account:    StudentInfo?
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    /* Singleton */
    class func sharedInstance() -> UdacityClient {
        struct Singleton {
            static var _sharedInstance = UdacityClient()
        }
        return Singleton._sharedInstance
    }
    
    
    // MARK: - POST method - common for Udacity and Parse
    func taskForPOSTMethod(method: String, isParse: Bool, parameters: [String : AnyObject]?, jsonBody: [String:AnyObject], completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {

        // println("(POST: method: [\(method)])")
        
        /* 1. Set the parameters */
        var urlString:String = ""
        if var mutableParameters = parameters {
            urlString = method + UdacityClient.escapedParameters(mutableParameters)
        }else{
            urlString = method
        }
        
        // println("## POST urlString: [\(urlString)]")
        
        /* 2/3. Build the URL and configure the request */
        
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        
        
        var jsonError: NSError? = nil
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if isParse {
            request.addValue(UdacityClient.AppKeys.ParseAppID, forHTTPHeaderField: UdacityClient.Header.XParseHeader)
            request.addValue(UdacityClient.AppKeys.APIKey, forHTTPHeaderField: UdacityClient.Header.XAPIHeader)
        } else {  // Udacity only
            request.addValue("application/json", forHTTPHeaderField: "Accept")
        }

        // set the Body
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(jsonBody, options: nil, error: &jsonError)
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in

            /* 5 & 6. Parse and use the data */
            if let error = downloadError {
                let newError = UdacityClient.errorForData(data, response: response, error: error)
                completionHandler(result: nil, error: downloadError)
            } else {
                var myData = data
                if (!isParse) {
                    // For Udacity calls: Remove first 5 bytes, per the spec
                    myData = data.subdataWithRange(NSMakeRange(5, data.length-5))
                }
                UdacityClient.parseJSONWithCompletionHandler(myData, completionHandler: completionHandler)
            }
        }
        
        
        /* 7: start request */
        task.start()
        
        return task
    
    }
    
    
    
    // MARK: - GET method
    func taskForGETMethod(method: String, isParse: Bool, parameters: [String : AnyObject]?, completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
 
        // println("(GET: method: [\(method)])")

        
        /* 1. Set the parameters */
        var urlString: String = ""
        if var mutableParameters = parameters {
            urlString = method + UdacityClient.escapedParameters(mutableParameters)
        } else {
            urlString = method
        }

        /* 2/3. Build the URL and configure the request */
        
        // println("## GET urlString: [\(urlString)]")
        
        //let url = NSURL(string: urlString)!
        let myUrl = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: myUrl)
        
        
        if isParse {
            request.addValue(UdacityClient.AppKeys.ParseAppID, forHTTPHeaderField: UdacityClient.Header.XParseHeader)
            request.addValue(UdacityClient.AppKeys.APIKey, forHTTPHeaderField: UdacityClient.Header.XAPIHeader)
        }
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            /* 5 & 6. Parse and use the data */
            if let error = downloadError {
                let newError = UdacityClient.errorForData(data, response: response, error: error)
                completionHandler(result: nil, error: downloadError)
            } else {
                var myData = data
                if (!isParse) {
                    // For Udacity calls: Remove first 5 bytes, per the spec
                    myData = data.subdataWithRange(NSMakeRange(5, data.length-5))
                }
                UdacityClient.parseJSONWithCompletionHandler(myData, completionHandler: completionHandler)
            }
        }

        /* 7. Start the request */
        task.start()
    
        return task
    }
    
    // MARK:  - PUT method
    // example - PUT StudentLocation
    func taskForPUTMethod(method: String, parameters: [String : AnyObject]?, jsonBody: [String:AnyObject], completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
 
        // println("(PUT: method: [\(method)])")

        
        /* 1. Set the parameters */
        var urlString:String = ""
        if var mutableParameters = parameters {
            urlString = method + UdacityClient.escapedParameters(mutableParameters)
        }else{
            urlString = method
        }
 
        // println("## PUT urlString: [\(urlString)]")

        /* 2/3. Build the URL and configure the request */
        
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        
        
        var jsonError: NSError? = nil
        request.HTTPMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(UdacityClient.AppKeys.ParseAppID, forHTTPHeaderField: UdacityClient.Header.XParseHeader)
        request.addValue(UdacityClient.AppKeys.APIKey, forHTTPHeaderField: UdacityClient.Header.XAPIHeader)

        // set the Body
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(jsonBody, options: nil, error: &jsonError)
        
        /* 4 - make the request */
        let task = session.dataTaskWithRequest(request) { data, response, downloadError in
         
            /* 5 & 6 - parse and use the data in completeion handler */
            if let error = downloadError {
                let newError = UdacityClient.errorForData(data, response: response, error: error)
            } else {
                UdacityClient.parseJSONWithCompletionHandler(data, completionHandler: completionHandler)
            
            }
        }
        
        /* 7. start the task */
        // Note that we've renamed the "resume()" func to "start()"
        task.start()
        
        return task
    }

    
    
    // MARK: - Helpers
    
    /* Helper: Substitute the key for the value that is contained within the method name */
    class func subtituteKeyInMethod(method: String, key: String, value: String) -> String? {
        if method.rangeOfString("{\(key)}") != nil {
            return method.stringByReplacingOccurrencesOfString("{\(key)}", withString: value)
        } else {
            return nil
        }
    }
    
    /* Helper: Given a response with error, see if a status_message is returned, otherwise return the previous error */
    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
        
        if let parsedResult = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: nil) as? [String : AnyObject] {
            
            if let errorMessage = parsedResult[UdacityClient.JsonResponse.StatusMessage] as? String {
                
                let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                
                return NSError(domain: "UdaMapper", code: 1, userInfo: userInfo)
            }
        }
        
        return error
    }
    

    
    /* Helper: Given raw JSON, return a usable Foundation object */
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsingError: NSError? = nil
        
        let parsedResult: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError)
        
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            completionHandler(result: parsedResult, error: nil)
        }
    }
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }

    
}
