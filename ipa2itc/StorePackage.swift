//
//  StorePackage.swift
//  ipa2itc
//
//  Created by Emlyn Murphy on 10/20/14.
//  Copyright (c) 2014 Nitemotif. All rights reserved.
//

import Cocoa

public class StorePackage {
    public let bundleVersion: String?
    public let shortBundleVersion: String?
    public let bundleIdentifier: String?
    public let fileURL: NSURL
    
    public init(fileURL: NSURL) {
        self.fileURL = fileURL
    }
}
