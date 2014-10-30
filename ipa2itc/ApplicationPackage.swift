//
//  ApplicationPackage.swift
//  ipa2itc
//
//  Created by Emlyn Murphy on 10/29/14.
//  Copyright (c) 2014 Nitemotif. All rights reserved.
//

import Foundation

public class ApplicationPackage {
    private var fileURL: NSURL
    
    public init?(fileURL: NSURL) {
        self.fileURL = fileURL
        
        var error: NSError?
        if self.fileURL.checkResourceIsReachableAndReturnError(&error) == false {
            return nil
        }
    }
}
