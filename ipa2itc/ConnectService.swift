//
//  ConnectService.swift
//  ipa2itc
//
//  Created by Emlyn Murphy on 10/29/14.
//  Copyright (c) 2014 Nitemotif. All rights reserved.
//

import Foundation

let iTunesConnectServiceURL: NSURL! = NSURL(string: "https://contentdelivery.itunes.apple.com/WebObjects/MZLabelService.woa/json/MZITunesProducerService")

private func generateJSONRPCID() -> String {
    let usLocale = NSLocale(localeIdentifier: "en_US")
    let jsonRPCIDDateFormatter = NSDateFormatter()
    jsonRPCIDDateFormatter.dateFormat = "yyyyMMddHHmmss'-'SSS"
    return jsonRPCIDDateFormatter.stringFromDate(NSDate())
}

public class ConnectService {
    private let username: String
    private let password: String
    private let session = NSURLSession.sharedSession()

    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    public func lookupSoftwareApplications(completionHandler: ([String: Int]?) -> ()) {
        let requestBodyDictionary = [
            "jsonrpc": "2.0",
            "method": "lookupSoftwareApplications",
            "id": generateJSONRPCID(),
            "params": [
                "Application": "ipa2itc",
                "Version": "\(versionString) (\(versionBuild))",
                "Password": password,
                "Username": username,
                "OSIdentifier": NSProcessInfo.processInfo().operatingSystemVersionString
            ]
        ]
        
        var returnValue: [String: Int]?
        
        var error: NSError?
        let requestBodyData = NSJSONSerialization.dataWithJSONObject(requestBodyDictionary, options: NSJSONWritingOptions.allZeros, error: &error)
        
        if requestBodyData == nil {
            if let description = error?.description {
                println("Error serializing JSON data: \(description).")
                completionHandler(returnValue)
            }
            else {
                println("Error serializing JSON data.")
                completionHandler(returnValue)
            }
        }
        
        let request = NSMutableURLRequest(URL: iTunesConnectServiceURL)
        request.HTTPBody = requestBodyData
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let dataTask = session.dataTaskWithRequest(request) {
            (data: NSData!, response: NSURLResponse!, error: NSError!) in
            
            if data == nil {
                println("Error looking up software applications: \(error.localizedDescription).")
                completionHandler(returnValue)
                return
            }
            
            var jsonError: NSError?
            if let jsonDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.allZeros, error: &jsonError) as? [String: AnyObject] {
                if let result = jsonDictionary["result"] as? [String: AnyObject] {
                    if let apps = result["Applications"] as? [[String: AnyObject]] {
                        returnValue = reduce(apps, [String:Int]()) {
                            (result, app) in
                            
                            let bundleID: String! = app["bundleId"] as? String
                            let appleID: Int! = app["adamId"] as? Int
                            var nextResult = result
                            
                            if bundleID != nil && appleID != nil {
                                nextResult[bundleID] = appleID
                            }
                            
                            return nextResult
                        }
                        
                        completionHandler(returnValue)
                        return
                    }
                }
            }
            else {
                if let description = error?.localizedDescription {
                    println("Error parsing response: \(description)")
                }
                else {
                    println("Error parsing response.")
                }
                
                completionHandler(returnValue)
                return
            }
        }
        
        dataTask.resume()
    }

    public func lookupSoftwareApplications() -> [String: Int]? {
        let synchronousSemaphore = dispatch_semaphore_create(0)
        var returnValue: [String: Int]?
        
        lookupSoftwareApplications {
            results in
            returnValue = results
            dispatch_semaphore_signal(synchronousSemaphore)
        }
        
        dispatch_semaphore_wait(synchronousSemaphore, DISPATCH_TIME_FOREVER)
        
        return returnValue
    }
}
