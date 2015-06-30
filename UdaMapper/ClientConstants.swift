//
//  ClientConstants.swift
//  UdaMapper
//
//  Created by Atul Acharya on 6/26/15.
//  Copyright (c) 2015 Atul Acharya. All rights reserved.
//

import Foundation

extension UdacityClient {
    // MARK: API KEYS
    struct AppKeys {
        static let ParseAppID: String  = "QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr"
        static let APIKey: String      = "QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY"
    }
    
    struct Header {
        static let XParseHeader        = "X-Parse-Application-Id"
        static let XAPIHeader          = "X-Parse-REST-API-Key"
    }

    // MARK: - Methods
    struct Methods {
        static let AuthNewSession  = "https://www.udacity.com/api/session"  // POST
        static let LogoutSession   = "https://www.udacity.com/api/session"  // DELETE
        static let UserData        = "https://www.udacity.com/api/users/"   // GET
        static let StudentLocations = "https://api.parse.com/1/classes/StudentLocation" // GET and POST
    }

    struct JsonResponse {
        // General
        static let Results         = "results"
        static let ObjectId        = "objectId"
        static let StatusMessage   = "status_message"
        static let StatusCode      = "status_code"
        static let Session         = "session"
        static let Account         = "account"
        static let Key             = "key"
        static let Id              = "id"
        static let User            = "user"
        static let FirstName       = "first_name"
        static let LastName        = "last_name"
        static let UpdatedAt       = "updatedAt"
        static let CreatedAt       = "createdAt"
        
        // User
        static let USerID          = "id"
        
        // Auth
        static let RequestToken    = "request_token"
        static let SessionId       = "session_id"
    }

    //
    struct JsonBody {
        static let username    = "username"
        static let password    = "password"
        static let objectId    = "objectId"
        static let uniqueKey   = "uniqueKey"
        static let firstName   = "firstName"
        static let lastName    = "lastName"
        static let mapString   = "mapString"
        static let mediaURL    = "mediaURL"
        static let latitude    = "latitude"
        static let longitude   = "longitude"
        static let udacity     = "udacity"
    }

} //