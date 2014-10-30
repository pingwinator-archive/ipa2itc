//
//  Keychain.swift
//  ipa2itc
//
//  Created by Emlyn Murphy on 10/30/14.
//  Copyright (c) 2014 Nitemotif. All rights reserved.
//

import Foundation

private let _sharedInstance = Keychain()
private let serverName = "itunesconnect.apple.com"

public class Keychain {
    public class var sharedInstance: Keychain {
        return _sharedInstance
    }
    
    public func passwordForUsername(username: String) -> String? {
        var passwordLength: UInt32 = 0
        var passwordData: UnsafeMutablePointer<Void> = nil
        let result = SecKeychainFindInternetPassword(nil, UInt32(countElements(serverName)), serverName, 0, nil, UInt32(countElements(username)), username, 0, nil, 0, SecProtocolType(kSecProtocolTypeHTTPS), SecAuthenticationType(kSecAuthenticationTypeAny), &passwordLength, &passwordData, nil)
        
        if result != 0 {
            return nil
        }

        return String(bytesNoCopy: passwordData, length: Int(passwordLength), encoding: NSUTF8StringEncoding, freeWhenDone: true)
    }
}
