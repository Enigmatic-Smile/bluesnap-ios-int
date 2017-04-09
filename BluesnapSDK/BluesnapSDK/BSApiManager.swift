//
//  BSApiManager.swift
//  BluesnapSDK
//
// Contains methods that access BlueSnap API
//
//  Created by Shevie Chen on 06/04/2017.
//  Copyright © 2017 Bluesnap. All rights reserved.
//

import Foundation

class BSApiManager  {
    
    // MARK: Constants
    
    static let BS_PRODUCTION_DOMAIN = "https://api.bluesnap.com/"
    static let BS_SANDBOX_DOMAIN = "https://us-qa-fct03.bluesnap.com/" // "https://sandbox.bluesnap.com/"
    static let BS_SANDBOX_TEST_USER = "GCpapi" //"sdkuser"
    static let BS_SANDBOX_TEST_PASS = "Plimus4321" //"SDKuser123"
    
    
    // MARK: Settings
    var bsDomain = BS_PRODUCTION_DOMAIN
    
    
    
    func setBSDomain(domain : String!) {
        bsDomain = domain
    }
    
    // Use this method only in tests to get a token for sandbox
    static func getSandboxBSToken() -> String? {
                
        return getBSToken(domain: BS_SANDBOX_DOMAIN, user: BS_SANDBOX_TEST_USER, password: BS_SANDBOX_TEST_PASS)
    }
    
    static func getBSToken(domain: String, user: String, password: String) -> String? {
        
        // create request
        let authorization = getBasicAuth(user: user, password: password)
        let urlStr = domain + "services/2/payment-fields-tokens"
        let url = NSURL(string: urlStr)!
        var request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        //request.timeoutInterval = 60
        request.setValue("text/xml", forHTTPHeaderField: "Content-Type")
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        request.setValue("0", forHTTPHeaderField: "Content-Length")
        
        // fire request

        var resultData : String?
        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            defer {
                semaphore.signal()
            }
            if error != nil {
                print("error")
                return
            }
            let httpResponse = response as? HTTPURLResponse
            let httpStatusCode:Int = (httpResponse?.statusCode)!
            if (httpStatusCode >= 200 && httpStatusCode <= 299) {
                let location:String = httpResponse?.allHeaderFields["Location"] as! String
                let lastIndexOfSlash = location.range(of:"/", options:String.CompareOptions.backwards, range:nil, locale:nil)!
                resultData = location.substring(with: lastIndexOfSlash.upperBound..<location.endIndex)
            } else {
                print("Http error; status = \(httpStatusCode)")
            }
        }
        task.resume()
        semaphore.wait()
        
        return resultData
    }
    
    static func getBasicAuth(user: String!, password: String!) -> String {
        let loginStr = String(format: "%@:%@", user, password)
        let loginData = loginStr.data(using: String.Encoding.utf8)!
        let base64LoginStr = loginData.base64EncodedString()
        return "Basic \(base64LoginStr)"
    }
    
}
