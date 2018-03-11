//
//  BSTokenizeRequest.swift
//  BluesnapSDK
//
//  Created by Shevie Chen on 08/03/2018.
//  Copyright © 2018 Bluesnap. All rights reserved.
//

import Foundation

/**
 Class holds data to be submitted to BLS server under the current token, to be used later for server-to-server actions
 - Specific payment type details are in sub-classes
 - (optional) Price details
 - (optional) Shopper billing details
 - (optional) Shopper shipping details
 - (optional) fraud Session Id
 */
@objc public class BSTokenizeRequest : NSObject {
    public var fraudSessionId: String?
    public var paymentDetails: BSTokenizePaymentDetails?
    public var priceDetails: BSPriceDetails?
    public var billingDetails: BSBillingAddressDetails?
    public var shippingDetails: BSShippingAddressDetails?
}

/**
 Base class for payment details to be submitted to BLS server
 */
@objc public class BSTokenizePaymentDetails : NSObject { }

/**
 Base Credit Card payment details to be submitted to BLS server
 - ccType: Credit Card Type
 - expDate: CC expiration date in format MM/YYYY  (in case of new/existing CC)
 */
@objc public class BSTokenizedBaseCCDetails : BSTokenizePaymentDetails {
    
    public static let LAST_4_DIGITS_KEY = "last4Digits"
    public static let CARD_TYPE_KEY = "ccType"
    public static let ISSUING_COUNTRY_KEY = "issuingCountry"
    
    var ccType: String!
    var expDate: String!
    public init(ccType: String!, expDate: String!) {
        self.ccType = ccType
        self.expDate = expDate
    }
}

/**
 New Credit Card payment details to be submitted to BLS server
 - ccNumber: Full credit card number
 - cvv: credit card security code
 */
@objc public class BSTokenizedNewCCDetails : BSTokenizedBaseCCDetails {
    var ccNumber: String!
    var cvv: String!
    public init(ccNumber: String!, cvv: String!, ccType: String!, expDate: String!) {
        super.init(ccType: ccType, expDate: expDate)
        self.ccNumber = ccNumber
        self.cvv = cvv
    }
}

/**
 Existing Credit Card payment details to be submitted to BLS server
 - lastFourDigits: last for digits of existing credit card number
 */
@objc public class BSTokenizedExistingCCDetails : BSTokenizedBaseCCDetails {
    var lastFourDigits: String!
    public init(lastFourDigits: String!, ccType: String!, expDate: String!) {
        super.init(ccType: ccType, expDate: expDate)
        self.lastFourDigits = lastFourDigits
    }
}

/**
 ApplePay payment details to be submitted to BLS server
 - applePayToken: ApplePay token
 */
@objc public class BSTokenizedApplePayDetails : BSTokenizePaymentDetails {
    var applePayToken: String!
    public init(applePayToken: String!) {
        self.applePayToken = applePayToken
    }
}
