//
//  Uploader.swift
//  ipa2itc
//
//  Created by Emlyn Murphy on 10/27/14.
//  Copyright (c) 2014 Nitemotif. All rights reserved.
//

import Cocoa

let iTunesConnectServiceURL: NSURL! = NSURL(string: "https://contentdelivery.itunes.apple.com/WebObjects/MZLabelService.woa/json/MZITunesProducerService")

private func generateJSONRPCID() -> String {
    let usLocale = NSLocale(localeIdentifier: "en_US")
    let jsonRPCIDDateFormatter = NSDateFormatter()
    jsonRPCIDDateFormatter.dateFormat = "yyyyMMddHHmmss'-'SSS"
    return jsonRPCIDDateFormatter.stringFromDate(NSDate())
}

public class Uploader {
    private let developerDirectoryURL: NSURL!
    private let transporterURL: NSURL!
    private let username: String
    private let password: String
    private var sku: String?
    
    private init?(developerDirectoryURL: NSURL?, username: String, password: String) {
        self.developerDirectoryURL = developerDirectoryURL
        self.username = username
        self.password = password
        
        if self.developerDirectoryURL == nil {
            return nil
        }
        
        if self.developerDirectoryURL.pathComponents.count == 0 {
            return nil
        }
        
        let transporterPathComponents = ["Applications", "Application Loader.app", "Contents", "MacOS", "itms", "bin", "iTMSTransporter"]
        transporterURL = reduce(transporterPathComponents, self.developerDirectoryURL.URLByDeletingLastPathComponent!) {
            (url, pathComponent) -> NSURL in
            return url.URLByAppendingPathComponent(pathComponent)
        }
        
        var error: NSError?
        if self.transporterURL.checkResourceIsReachableAndReturnError(&error) == false {
            if let description = error?.localizedDescription {
                println("Can't access iTMSTransporter: \(description)")
            }
            else {
                println("Can't access iTMSTransporter.")
            }
            
            return nil
        }
    }
    
    public convenience init?(pathToDeveloperDirectory: String, username: String, password: String) {
        if let developerDirectoryURL = NSURL(fileURLWithPath: pathToDeveloperDirectory) {
            self.init(developerDirectoryURL: developerDirectoryURL, username: username, password: password)
            
            var error: NSError?
            if self.developerDirectoryURL.checkResourceIsReachableAndReturnError(&error) == false {
                if let description = error?.localizedDescription {
                    println("Can't access developer directory: \(description)")
                }
                else {
                    println("Can't access developer directory.")
                }
                
                return nil
            }
        }
        else {
            self.init(developerDirectoryURL: nil, username: username, password: password)
            return nil
        }
    }
    
    public convenience init?(username: String, password: String) {
        let xcodeSelectTask = NSTask()
        xcodeSelectTask.launchPath = "/usr/bin/xcode-select"
        xcodeSelectTask.arguments = ["-p"]
        
        let xcodeSelectOutputPipe = NSPipe()
        xcodeSelectTask.standardOutput = xcodeSelectOutputPipe
        
        xcodeSelectTask.launch()
        xcodeSelectTask.waitUntilExit()
        
        if xcodeSelectTask.terminationStatus != 0 {
            println("Base xcode-select exit status: \(xcodeSelectTask.terminationStatus)")
            self.init(developerDirectoryURL: nil, username: username, password: password)
            return nil
        }
        
        let xcodeSelectTaskData = xcodeSelectOutputPipe.fileHandleForReading.readDataToEndOfFile()
        let outputString: NSString! = NSString(data: xcodeSelectTaskData, encoding: NSUTF8StringEncoding)
        
        if outputString == nil {
            println("Error reading from xcode-select pipe.")
            self.init(developerDirectoryURL: nil, username: username, password: password)
            return nil
        }

        self.init(pathToDeveloperDirectory: outputString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()),
            username: username, password: password)
    }
    
    private func lookupSoftwareApplications() -> [String: Int]? {
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
                return nil
            }
            else {
                println("Error serializing JSON data.")
                return nil
            }
        }
        
        let session = NSURLSession.sharedSession()
        
        let request = NSMutableURLRequest(URL: iTunesConnectServiceURL)
        request.HTTPBody = requestBodyData
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let dataTaskSemaphore = dispatch_semaphore_create(0)
        
        let dataTask = session.dataTaskWithRequest(request) {
            (data: NSData!, response: NSURLResponse!, error: NSError!) in
            
            if data == nil {
                println("Error looking up software applications: \(error.localizedDescription).")
                dispatch_semaphore_signal(dataTaskSemaphore)
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
                        
                        dispatch_semaphore_signal(dataTaskSemaphore)
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
                
                dispatch_semaphore_signal(dataTaskSemaphore)
                return
            }
        }
        
        dataTask.resume()
        dispatch_semaphore_wait(dataTaskSemaphore, DISPATCH_TIME_FOREVER)
        
        return returnValue
    }
    
    public func uploadPackageAtURL(packageURL: NSURL) {
        let transporterTask = NSTask()
        transporterTask.launchPath = transporterURL.path!
        transporterTask.arguments = ["-m", "upload", "-delete", "-u", username, "-s", password, "-f", packageURL]
        
        if sku == nil {
            if let softwareApplications = lookupSoftwareApplications() {
                if let appleID = softwareApplications["com.nitemotif.Hive"] {
                    println("Hive Apple ID: \(appleID)")
                }
                else {
                    println("Could not find application in iTunes Connect.")
                }
            }
        }
    }
}
