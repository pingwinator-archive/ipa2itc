//
//  ApplicationPackage.swift
//  ipa2itc
//
//  Created by Emlyn Murphy on 10/29/14.
//  Copyright (c) 2014 Nitemotif. All rights reserved.
//

import Foundation

public class ApplicationPackage {
    private let fileURL: NSURL
    public let bundleIdentifier: String?
    public let shortBundleVersion: String?
    public let bundleVersion: String?
    
    public init?(fileURL: NSURL) {
        self.fileURL = fileURL
        
        var error: NSError?
        if self.fileURL.checkResourceIsReachableAndReturnError(&error) == false {
            return nil
        }
        
        let zipFile = ZipFile(fileName: fileURL.path!, mode: ZipFileModeUnzip)
        
        for fileInfo in zipFile.listFileInZipInfos() as [FileInZipInfo] {
            let info = fileInfo as FileInZipInfo
            let pathComponents = fileInfo.name.pathComponents
            
            if pathComponents.count == 3 && pathComponents[0] == "Payload" && pathComponents[1].pathExtension == "app" && pathComponents[2] == "Info.plist" {
                zipFile.locateFileInZip(info.name)
                
                let readStream = zipFile.readCurrentFileInZip()
                let data: NSMutableData! = NSMutableData(length: Int(info.length))
                
                readStream.readDataWithBuffer(data)
                readStream.finishedReading()
                
                var errorString: NSString?
                if let infoPlist = NSPropertyListSerialization.propertyListFromData(data, mutabilityOption: NSPropertyListMutabilityOptions.Immutable, format: UnsafeMutablePointer<NSPropertyListFormat>.null(), errorDescription: &errorString) as? Dictionary<String, AnyObject> {
                    bundleIdentifier = infoPlist["CFBundleIdentifier"] as? String
                    shortBundleVersion = infoPlist["CFBundleShortVersionString"] as? String
                    bundleVersion = infoPlist["CFBundleVersion"] as? String
                }
                else {
                    if let errorString = errorString {
                        println("Error reading Info.plist: \(errorString).")
                    }
                    else {
                        println("Error reading Info.plist.")
                    }
                }
            }
        }
    }
}
