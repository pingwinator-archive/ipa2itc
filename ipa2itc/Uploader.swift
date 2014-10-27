//
//  Uploader.swift
//  ipa2itc
//
//  Created by Emlyn Murphy on 10/27/14.
//  Copyright (c) 2014 Nitemotif. All rights reserved.
//

import Cocoa

public class Uploader {
    private let developerDirectoryURL: NSURL!
    private let transporterURL: NSURL!
    
    private init?(developerDirectoryURL: NSURL?) {
        self.developerDirectoryURL = developerDirectoryURL
        
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
    
    public convenience init?(pathToDeveloperDirectory: String) {
        if let developerDirectoryURL = NSURL(fileURLWithPath: pathToDeveloperDirectory) {
            self.init(developerDirectoryURL: developerDirectoryURL)
            
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
            self.init(developerDirectoryURL: nil)
            return nil
        }
    }
    
    public convenience init?() {
        let xcodeSelectTask = NSTask()
        xcodeSelectTask.launchPath = "/usr/bin/xcode-select"
        xcodeSelectTask.arguments = ["-p"]
        
        let xcodeSelectOutputPipe = NSPipe()
        xcodeSelectTask.standardOutput = xcodeSelectOutputPipe
        
        xcodeSelectTask.launch()
        xcodeSelectTask.waitUntilExit()
        
        if xcodeSelectTask.terminationStatus != 0 {
            println("Base xcode-select exit status: \(xcodeSelectTask.terminationStatus)")
            self.init(developerDirectoryURL: nil)
            return nil
        }
        
        let xcodeSelectTaskData = xcodeSelectOutputPipe.fileHandleForReading.readDataToEndOfFile()
        let outputString: NSString! = NSString(data: xcodeSelectTaskData, encoding: NSUTF8StringEncoding)
        
        if outputString == nil {
            println("Error reading from xcode-select pipe.")
            self.init(developerDirectoryURL: nil)
            return nil
        }

        self.init(pathToDeveloperDirectory: outputString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()))
    }
}
