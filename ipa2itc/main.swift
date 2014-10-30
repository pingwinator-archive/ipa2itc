//
//  main.swift
//  ipa2itc
//
//  Created by Emlyn Murphy on 10/20/14.
//  Copyright (c) 2014 Nitemotif. All rights reserved.
//

public let versionString = "1.0"
public let versionBuild = 1

import Foundation

func processArguments(arguments: [String]) -> [String: String]? {
    var argumentQueue = arguments[1..<countElements(arguments)]
    var argumentIndex = 0
    var parsedArguments = [String: String]()
    
    func nextArgument() -> String {
        argumentIndex++
        return argumentQueue.removeAtIndex(0)
    }
    
    while argumentQueue.count > 0 {
        let currentArgument = nextArgument()
        
        if currentArgument.hasPrefix("-") {
            switch currentArgument.substringFromIndex(advance(currentArgument.startIndex, 1)) {
            case "u":
                if argumentQueue.count == 0 {
                    println("Argument \(argumentIndex) Error: expected username after -u.")
                    return nil
                }
                
                parsedArguments["username"] = nextArgument()
                
                if parsedArguments["username"] != nil && parsedArguments["username"]!.hasPrefix("-") {
                    println("Argument \(argumentIndex) Error: expected username after -u.")
                    return nil
                }
                
            case "p":
                if argumentQueue.count == 0 {
                    println("Argument \(argumentIndex) Error: expected password after -p.")
                    return nil
                }
                
                parsedArguments["password"] = nextArgument()
                
                if parsedArguments["password"] != nil && parsedArguments["password"]!.hasPrefix("-") {
                    println("Argument \(argumentIndex) Error: expected password after -p.")
                    return nil
                }
                
            default:
                return nil
            }
        }
        else {
            if countElements(argumentQueue) == 0 {
                parsedArguments["path"] = currentArgument
            }
            else {
                println("Argument \(argumentIndex) Error: arguments after package path.")
                return nil
            }
        }
    }
    
    if parsedArguments["path"] == nil {
        println("Error: no package path.")
        return nil
    }
    
    return parsedArguments
}

let arguments: [String: String]! = processArguments(NSProcessInfo.processInfo().arguments as [String])

if arguments == nil || arguments["username"] == nil || arguments["password"] == nil || arguments["path"] == nil {
    println("Usage:")
    println("ipa2itc -u username -p password file")
    exit(0)
}

let username = arguments["username"]!
let password = arguments["password"]!
let packageURL: NSURL! = NSURL(fileURLWithPath: arguments["path"]!)!

if let package = StorePackage(fileURL: packageURL) {
    let connectService = ConnectService(username: username, password: password)
    
    if let appPackage = ApplicationPackage(fileURL: packageURL) {
        if let softwareApplications = connectService.lookupSoftwareApplications() {
            if let bundleIdentifier = appPackage.bundleIdentifier {
                if let appleID = softwareApplications[bundleIdentifier] {
                    package.appleID = appleID
                }
                else {
                    println("Could not find application in iTunes Connect.")
                }
            }
            else {
                println("Could not find bundle identifier in IPA.")
            }
        }
        
        if let shortBundleVersion = appPackage.shortBundleVersion {
            package.shortBundleVersion = shortBundleVersion
        }
        
        if let bundleVersion = appPackage.bundleVersion {
            package.bundleVersion = bundleVersion
        }
        
        if let uploader = Uploader(username: username, password: password) {
            if let temporaryPackageURL = package.writeTemporaryPackage() {
                uploader.uploadPackageAtURL(temporaryPackageURL)
                
                if let temporaryFolderURL = temporaryPackageURL.URLByDeletingLastPathComponent {
                    var error: NSError?
                    
                    if NSFileManager.defaultManager().removeItemAtURL(temporaryFolderURL, error: &error) == false {
                        if let description = error?.description {
                            println("Error deleting temporary folder: \(description).")
                        }
                        else {
                            println("Error deleting temporary folder.")
                        }
                    }
                }
            }
        }
    }
}
