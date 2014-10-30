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

let username = ""
let password = ""
let packageURL = NSURL(fileURLWithPath: "/path/to/app.ipa")!

if let package = StorePackage(fileURL: packageURL) {
    let connectService = ConnectService(username: username, password: password)
    
    if let softwareApplications = connectService.lookupSoftwareApplications() {
        if let appleID = softwareApplications[""] {
            package.appleID = appleID
        }
        else {
            println("Could not find application in iTunes Connect.")
        }
    }
    
    if let appPackage = ApplicationPackage(fileURL: packageURL) {
        if let bundleIdentifier = appPackage.bundleIdentifier {
            println("bundleIdentifier: \(bundleIdentifier)")
        }
        
        if let shortBundleVersion = appPackage.shortBundleVersion {
            println("shortBundleVersion: \(shortBundleVersion)")
        }
        
        if let bundleVersion = appPackage.bundleVersion {
            println("bundleVersion: \(bundleVersion)")
        }
    }

    if let uploader = Uploader(username: username, password: password) {
        if let packageURL = package.writeTemporaryPackage() {
            println("packageURL: \(packageURL.path!)")
            uploader.uploadPackageAtURL(packageURL)
        }
    }
}
