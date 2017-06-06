//
//  BSPurchaseDataModel.swift
//  BluesnapSDK
//
//  Created by Shevie Chen on 18/04/2017.
//  Copyright © 2017 Bluesnap. All rights reserved.
//

import Foundation

public class BSPaymentDetails : NSObject {
    
    // These 3 fields are input + output (they may change if shopper changes currency)
    var amount : Double! = 0.0
    var taxAmount : Double! = 0.0
    var currency : String! = "USD"
    
    // These fields are output, but may be supplied as input as well
    var billingDetails : BSAddressDetails! = BSAddressDetails()
    var shippingDetails : BSAddressDetails?

    // Output only - result of submitting the CC details to BlueSnap server
    var ccDetails : BSResultCcDetails?
    
    
    // These fields hold the original amounts in USD, to keep precision in case of currency change
    internal var originalAmount : Double! = 0.0
    internal var originalTaxAmount : Double! = 0.0
    internal var originalRate : Double?
    
    // MARK: Change currency methods
    
    /*
    Set amounts will reset the currency and amounts, including the original
    amounts.
    */
    public func setAmountsAndCurrency(amount: Double!, taxAmount: Double?, currency: String) {
        
        self.amount = amount
        self.originalAmount = amount
        self.taxAmount = taxAmount
        self.originalTaxAmount = taxAmount ?? 0.0
        self.currency = currency
        self.originalRate = nil
    }
    
    /*
    Change currency will also change the amounts according to the change rates
    */
    public func changeCurrency(oldCurrency: BSCurrency?, newCurrency : BSCurrency?) {
        
        if originalRate == nil {
            if let oldCurrency = oldCurrency {
                originalRate = oldCurrency.getRate() ?? 1.0
            } else {
                originalRate = 1.0
            }
        }
        if let newCurrency = newCurrency {
            self.currency = newCurrency.code
            let newRate = newCurrency.getRate() / originalRate!
            self.amount = originalAmount * newRate
            self.taxAmount = originalTaxAmount * newRate
        }
    }
    
    
    // MARK: getters and setters
    
    public func getAmount() -> Double! {
        return amount
    }
    
    public func getTaxAmount() -> Double! {
        return taxAmount
    }
    
    public func getCurrency() -> String! {
        return currency
    }
    
    public func getBillingDetails() -> BSAddressDetails! {
        return billingDetails
    }
    
    public func getCcDetails() -> BSResultCcDetails? {
        return ccDetails
    }
    
    public func setCcDetails(ccDetails : BSResultCcDetails?) {
        self.ccDetails = ccDetails
    }
    
    public func getShippingDetails() -> BSAddressDetails? {
        return shippingDetails
    }
    
    public func setShippingDetails(shippingDetails : BSAddressDetails?) {
        self.shippingDetails = shippingDetails
    }
}

/**
    Shopper shipping details for purchase
 */
public class BSAddressDetails {
    
    public init() {}
    
    public var name : String! = ""
    public var email : String?
    public var address : String?
    public var city : String?
    public var zip : String?
    public var country : String?
    public var state : String?
    
    public func getSplitName() -> (firstName: String, lastName: String)? {
        return name.splitName
    }
}

/**
 Output non-secured CC details for the purchase
*/
public class BSResultCcDetails {
    
    // these fields are output - result of submitting the CC details to BlueSnap server
    var ccType : String?
    var last4Digits : String?
    var ccIssuingCountry : String?
}

