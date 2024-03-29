//
//  StorePackage.swift
//  ipa2itc
//
//  Created by Emlyn Murphy on 10/20/14.
//  Copyright (c) 2014 Nitemotif. All rights reserved.
//

import Foundation

let packageVersion = "software5.2"

public class StorePackage: Printable {
    public let fileURL: NSURL
    public var vendorID: String?
    public var appleID: Int?
    public var shortBundleVersion: String?
    public var bundleVersion: String?
    public var bundleIdentifier: String?
    
    public var hasIdentifier: Bool {
        return vendorID != nil || appleID != nil
    }
    
    public init?(fileURL: NSURL) {
        self.fileURL = fileURL

        var error: NSError?
        if self.fileURL.checkResourceIsReachableAndReturnError(&error) == false {
            return nil
        }
    }
    
    public var description: String {
        if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
            return string
        }
        else {
            return ""
        }
    }
    
    private var checksum: String? {
        let data: NSData! = NSData(contentsOfURL: fileURL)
        
        if data == nil {
            return nil
        }
        
        var context = UnsafeMutablePointer<CC_MD5_CTX>.alloc(sizeof(CC_MD5_CTX))
        
        CC_MD5_Init(context)
        CC_MD5_Update(context, data.bytes, UInt32(data.length))
        
        let length = Int(CC_MD5_DIGEST_LENGTH) * sizeof(Byte)
        var output = UnsafeMutablePointer<Byte>.alloc(length)
        CC_MD5_Final(output, context)
        
        let hashData = NSData(bytes: output, length: Int(CC_MD5_DIGEST_LENGTH))
        output.destroy()
        context.destroy()
        
        var bytes = Array<Byte>(count: Int(CC_MD5_DIGEST_LENGTH), repeatedValue: Byte(0))
        hashData.getBytes(&bytes)
        
        var hashString = NSMutableString()
        
        for i in 0 ..< Int(CC_MD5_DIGEST_LENGTH) {
            hashString.appendFormat("%02x", bytes[i])
        }
        
        return hashString
    }
    
    public var data: NSData {
        let packageElement = NSXMLNode.elementWithName("package") as NSXMLElement
        
        let versionAttribute = NSXMLNode.attributeWithName("version", stringValue: packageVersion) as NSXMLNode
        packageElement.addAttribute(versionAttribute)
        
        let namespaceAttribute = NSXMLNode.attributeWithName("xmlns", stringValue: "http://apple.com/itunes/importer") as NSXMLNode
        packageElement.addAttribute(namespaceAttribute)
        
        let softwareAssetsElement = NSXMLNode.elementWithName("software_assets") as NSXMLElement
        packageElement.addChild(softwareAssetsElement)

        if let appleID = appleID {
            let appleIDAttribute = NSXMLNode.attributeWithName("apple_id", stringValue: "\(appleID)") as NSXMLNode
            softwareAssetsElement.addAttribute(appleIDAttribute)
        }
        else if let vendorID = vendorID {
            let vendorIDAttribute = NSXMLNode.attributeWithName("vendor_id", stringValue: vendorID) as NSXMLNode
            softwareAssetsElement.addAttribute(vendorIDAttribute)
        }
        
        if let shortBundleVersion = shortBundleVersion {
            let shortBundleVersionAttribute = NSXMLNode.attributeWithName("bundle_short_version_string", stringValue: shortBundleVersion) as NSXMLNode
            softwareAssetsElement.addAttribute(shortBundleVersionAttribute)
        }
        
        if let bundleVersion = bundleVersion {
            let bundleVersionAttribute = NSXMLNode.attributeWithName("bundle_version", stringValue: bundleVersion) as NSXMLNode
            softwareAssetsElement.addAttribute(bundleVersionAttribute)
        }
        
        if let bundleIdentifier = bundleIdentifier {
            let bundleIdentifierAttribute = NSXMLNode.attributeWithName("bundle_identifier", stringValue: bundleIdentifier) as NSXMLNode
            softwareAssetsElement.addAttribute(bundleIdentifierAttribute)
        }
        
        let assetElement = NSXMLElement.elementWithName("asset") as NSXMLElement
        softwareAssetsElement.addChild(assetElement)
        
        let bundleTypeAttribute = NSXMLElement.attributeWithName("type", stringValue: "bundle") as NSXMLNode
        assetElement.addAttribute(bundleTypeAttribute)
        
        let dataFileElement = NSXMLElement.elementWithName("data_file") as NSXMLElement
        assetElement.addChild(dataFileElement)
        
        let fileNameElement = NSXMLElement.elementWithName("file_name") as NSXMLElement
        dataFileElement.addChild(fileNameElement)
        
        let fileNameTextNode = NSXMLNode.textWithStringValue(fileURL.lastPathComponent) as NSXMLNode
        fileNameElement.addChild(fileNameTextNode)
        
        var error: NSError?
        let fileAttributes = NSFileManager.defaultManager().attributesOfItemAtPath(fileURL.path!, error: &error)
        
        if fileAttributes == nil {
            if let description = error?.localizedDescription {
                println("Error checking file size: \(description).")
            }
            else {
                println("Error checking file size.")
            }
        } else {
            if let size = fileAttributes![NSFileSize] as? NSNumber {
                let sizeElement = NSXMLElement.elementWithName("size") as NSXMLElement
                dataFileElement.addChild(sizeElement)
                
                let sizeTextNode = NSXMLNode.textWithStringValue("\(size)") as NSXMLNode
                sizeElement.addChild(sizeTextNode)
            }
        }
        
        if let checksum = checksum {
            let checksumElement = NSXMLElement.elementWithName("checksum") as NSXMLElement
            dataFileElement.addChild(checksumElement)
            
            let checksumTextNode = NSXMLNode.textWithStringValue(checksum) as NSXMLNode
            checksumElement.addChild(checksumTextNode)
        }
        
        let document = NSXMLDocument(rootElement: packageElement)
        document.characterEncoding = "UTF-8"

        return document.XMLDataWithOptions(Int(NSXMLNodePrettyPrint))
    }
    
    public func writeTemporaryPackage() -> NSURL? {
        let packageName: String! = fileURL.lastPathComponent.stringByDeletingPathExtension.stringByAppendingPathExtension("itmsp")
        
        if packageName == nil {
            return nil
        }
        
        let temporaryPackageURL: NSURL! = NSURL.fileURLWithPath(NSTemporaryDirectory())?.URLByAppendingPathComponent(NSProcessInfo.processInfo().globallyUniqueString).URLByAppendingPathComponent(packageName)

        if temporaryPackageURL == nil {
            return nil
        }
        
        var error: NSError?
        if NSFileManager.defaultManager().createDirectoryAtURL(temporaryPackageURL, withIntermediateDirectories: true, attributes: nil, error: &error) == false {
            if let description = error?.localizedDescription {
                println("Error creating directory: \(description)")
            }
            else {
                println("Error creating directory.")
            }
            
            return nil
        }
        
        let destinationURL = temporaryPackageURL.URLByAppendingPathComponent(fileURL.lastPathComponent)
        error = nil
        
        if NSFileManager.defaultManager().copyItemAtURL(fileURL, toURL: destinationURL, error: &error) == false {
            if let description = error?.localizedDescription {
                println("Error copying file: \(description)")
            }
            else {
                println("Error copying file.")
            }
            
            return nil
        }
        
        let contentXMLURL = temporaryPackageURL.URLByAppendingPathComponent("metadata.xml")
        error = nil
        
        description.writeToURL(contentXMLURL, atomically: true, encoding: NSUTF8StringEncoding, error: &error)
        
        return temporaryPackageURL
    }
}
