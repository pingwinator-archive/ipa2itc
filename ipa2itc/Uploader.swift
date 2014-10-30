//
//  Uploader.swift
//  ipa2itc
//
//  Created by Emlyn Murphy on 10/27/14.
//  Copyright (c) 2014 Nitemotif. All rights reserved.
//

import Foundation

public class Uploader {
    private let developerDirectoryURL: NSURL!
    private let transporterURL: NSURL!
    private let username: String
    private let password: String
    
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
    
    public func uploadPackageAtURL(packageURL: NSURL) -> Bool {
        let transporterTask = NSTask()
        let transporterPath: String! = transporterURL.path
        
        if transporterPath == nil {
            println("Can't find path to iTMSTransporter.")
            return false
        }
        
        var error: NSError?
        if packageURL.checkResourceIsReachableAndReturnError(&error) == false {
            if let description = error?.localizedDescription {
                println("Can't access package: \(description).")
            }
            else {
                println("Can't access package.")
            }
            
            return false
        }

        let packagePath: String! = packageURL.path
        
        if packagePath == nil {
            println("Can't find path to package.")
            return false
        }
        
        transporterTask.launchPath = transporterPath
        transporterTask.arguments = ["-m", "upload", "-delete", "-u", username, "-p", password, "-f", packagePath]
        transporterTask.launch()
        transporterTask.waitUntilExit()
        
        if transporterTask.terminationStatus == 0 {
            return true
        }
        else {
            return false
        }
    }
}
