//
//  StudentInfo.swift
//  UdaMapper
//
//  Created by Atul Acharya on 6/26/15.
//  Copyright (c) 2015 Atul Acharya. All rights reserved.
//

import Foundation

struct StudentInfo: Printable {
    
    var objectId:   String?
    var uniqueKey:  String?
    var firstName:  String
    var lastName:   String
    var mapString:  String?
    var mediaURL:   String?
    var latitude:   Double?
    var longitude:  Double?
    
    // pretty print; take care of null URLs etc
    var description: String {
        var s1 =  " [Student:   \(firstName) \(lastName) (ID:"
        if let _ = objectId  { s1 += " \(objectId!)" } else { s1 += " nil" }
        s1  += ", Key:"
        if let _ = uniqueKey { s1 += " \(uniqueKey!)" } else { s1 += " nil"}
        s1  += ")\n"
        
        var s2 =  "  mediaURL:  "
        if let _ = mediaURL  { s2 += "[\(mediaURL!)]\n" } else { s2 += "[nil]\n" }
        var s3 =  "  mapString: "
        if let _ = mapString { s3 += "[\(mapString!)]\n"} else { s3 += "[nil]\n" }
        var s4 =  "  lat, long: "
        if let _ = latitude  { s4 += "(\(latitude!)," } else { s4 += "(nil," }
        if let _ = longitude { s4 += "\(longitude!))" } else { s4 += "nil)\n"}
        
        return s1 + s2 + s3 + s4
    }

    
    // Inits
    init(var uniqueKey:String, var firstName: String, var lastName: String) {
        self.uniqueKey = uniqueKey
        self.firstName = firstName
        self.lastName  = lastName
    }
    
    init(var objectId: String, var uniqueKey: String, var firstName: String, var lastName: String, var mapString:  String, var mediaURL:   String, var latitude:   Double, var longitude:  Double) {
        self.init(uniqueKey: uniqueKey, firstName: firstName, lastName: lastName)
        self.objectId   = objectId
        self.mapString  = mapString
        self.mediaURL   = mediaURL
        self.latitude   = latitude
        self.longitude  = longitude
    }
    
    init(dictionary: [String:AnyObject]) {
        
        objectId    = dictionary[UdacityClient.JsonBody.objectId]   as! String?
        uniqueKey   = dictionary[UdacityClient.JsonBody.uniqueKey]  as! String?
        firstName   = dictionary[UdacityClient.JsonBody.firstName]  as! String
        lastName    = dictionary[UdacityClient.JsonBody.lastName]   as! String
        
        mapString   = dictionary[UdacityClient.JsonBody.mapString]  as! String?
        mediaURL    = dictionary[UdacityClient.JsonBody.mediaURL]   as! String?
        latitude    = dictionary[UdacityClient.JsonBody.latitude]   as! Double?
        longitude   = dictionary[UdacityClient.JsonBody.longitude]  as! Double?
    }
    
    // Helper - return an array of StudentInfo, given an array of dicts (e.g. from JSON response)
    static func studentsFromResults(results: [[String:AnyObject]]) -> [StudentInfo] {
        var students = [StudentInfo]()
        
        for result in results {
            students.append(StudentInfo(dictionary: result))
        }
        
        return students
    }
    
    
}