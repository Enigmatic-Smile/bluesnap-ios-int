//
//  BlueSnap.swift
//  BlueSnap
//
//

import Foundation

@objc open class BlueSnapSDK: NSObject {
	
    // MARK: SDK functions
    
    /**
     Set the token used for BS API
     This needs to be done before calling any of the methods below, and also if you catch notification 
     for token expired
     
     - parameters:
     - bsToken: BlueSnap token, should be fresh and valid
    */
    open class func setBsToken(bsToken : BSToken!) {
        
        BSApiManager.setBsToken(bsToken: bsToken)
    }
    
    /**
     Start the check-out flow, where the shopper payment details are entered.
     
     - parameters:
     - inNavigationController: your viewController's navigationController (to be able to navigate back)
     - animated: how to navigate to the new screen
     - paymentDetails: object that holds the shopper and payment details; shopper name and shipping details may be pre-filled
     - withShipping: if true, the shopper will be asked to supply shipping details
     - fullBilling: if true, we collect full billing address; otherwise only name and optionally zip code
     - purchaseFunc: callback; will be called when the shopper hits "Pay" and all the data is prepared
     */
    open class func showCheckoutScreen(
        inNavigationController: UINavigationController!,
        animated: Bool,
        paymentDetails : BSPaymentDetails!,
        withShipping: Bool,
        fullBilling : Bool,
        purchaseFunc: @escaping (BSPaymentDetails!)->Void) {
        
        adjustPaymentDetails(paymentDetails: paymentDetails,
                             withShipping: withShipping)
        
        BSViewsManager.showStartScreen(inNavigationController: inNavigationController,
                                          animated: animated,
                                          paymentDetails: paymentDetails,
                                          withShipping: withShipping,
                                          fullBilling: fullBilling,
                                          purchaseFunc: purchaseFunc)
    }
    
    /**
     Submit Payment token fields
     If you do not want to use our check-out page, you can implement your own.
     You need to generate a token, and then call this function to submit the CC details to BlueSnap instead of returning them to your server (which is less secure) and then passing them to BlueSnap when you create the transaction.
     - parameters:
     - ccNumber: Credit card number
     - expDate: CC expiration date in format MM/YYYY
     - cvv: CC security code (CVV)
     - completion: callback with either result details if OK, or error details if not OK
     */
    open class func submitCcDetails(ccNumber: String, expDate: String, cvv: String, completion : @escaping (BSResultCcDetails?,BSCcDetailErrors?)->Void) {
        
        BSApiManager.submitCcDetails(ccNumber: ccNumber, expDate: expDate, cvv: cvv, completion: completion)
    }
    
    /**
     Return a list of currencies and their rates from BlueSnap server
     - parameters:
     - throws BSApiErrors
     */
    open class func getCurrencyRates() throws -> BSCurrencies? {
        do {
            let result = try BSApiManager.getCurrencyRates()
            return result
        } catch let error {
            throw error
        }
    }

    /**
     Navigate to the currency list, allow changing current selection.
     
     - parameters:
     - inNavigationController: your viewController's navigationController (to be able to navigate back)
     - animated: how to navigate to the new screen
     - selectedCurrencyCode: 3 characters of the curtrent language code (uppercase)
     - updateFunc: callback; will be called each time a new value is selected
     */
    open class func showCurrencyList(
        inNavigationController: UINavigationController!,
        animated: Bool,
        selectedCurrencyCode : String!,
        updateFunc: @escaping (BSCurrency?, BSCurrency?)->Void) {
        
        BSViewsManager.showCurrencyList(inNavigationController: inNavigationController, animated: animated, selectedCurrencyCode: selectedCurrencyCode, updateFunc: updateFunc)
    }
    
    /**
     Call Kount SDK to initialize device data collection
     - parameters:
     - kountMid: if you have your own Kount MID, send it here; otherwise leave empty
     - fraudSessionID: this unique ID per shopper should be sent later to BlueSnap when creating the transaction
    */
    open class func KountInit(kountMid: Int?, fraudSessionID : String!) {
        //// Configure the Data Collector
        //
        KDataCollector.shared().debug = true
        // TODO Set your Merchant ID
        KDataCollector.shared().merchantID = kountMid ?? 700000
        // TODO Set the location collection configuration
        KDataCollector.shared().locationCollectorConfig = KLocationCollectorConfig.requestPermission
        // For a released app, you'll want to set this to KEnvironment.Production
        KDataCollector.shared().environment = KEnvironment.test
    }
    
    
    // MARK: Utility functions for quick testing
    
    /**
     Returns token for BlueSnap Sandbox environment; useful for tests.
     In your real app, the token should be generated on the server side and passed to the app, so that the app will not expose the username/password
    */
    open class func createSandboxTestToken() throws -> BSToken? {
        do {
            return try BSApiManager.createSandboxBSToken()
        } catch let error {
            throw error
        }
    }
    
    // MARK: Private functions
    
    private class func adjustPaymentDetails(paymentDetails: BSPaymentDetails!,
                                            withShipping: Bool) {
        
        let defaultCountry = NSLocale.current.regionCode ?? "US"
        if (withShipping && paymentDetails.shippingDetails == nil) {
            paymentDetails.setShippingDetails(shippingDetails: BSAddressDetails())
            paymentDetails.getShippingDetails()!.country = defaultCountry
        } else if (!withShipping && paymentDetails.shippingDetails != nil) {
            paymentDetails.setShippingDetails(shippingDetails: nil)
        }
        if paymentDetails.getBillingDetails().country ?? "" == "" {
            paymentDetails.getBillingDetails().country = defaultCountry
        }

    }
    
}
