//
//  SubscriptionChargeUITests.swift
//  BluesnapSDKExampleUITests
//
//  Created by Sivani on 11/04/2019.
//  Copyright © 2019 Bluesnap. All rights reserved.
//

import Foundation
import XCTest
import Foundation
import PassKit
import BluesnapSDK

class SubscriptionChargeNewShopperUITests: CheckoutBaseTester {
    
    /* -------------------------------- Subscription common tests ---------------------------------------- */

    func subscriptionViewsCommomTester(checkoutFullBilling: Bool, checkoutWithEmail: Bool, checkoutWithShipping: Bool, trialPeriodDays: Int? = nil){
        setUpForCheckoutSdk(fullBilling: checkoutFullBilling, withShipping: checkoutWithShipping, withEmail: checkoutWithEmail, isSubscription: true, trialPeriodDays: trialPeriodDays)
        
        // check cc line visibility (including error messages)
        paymentHelper.checkNewCCLineVisibility()
        
        // check Inputs Fields visibility (including error messages)
        paymentHelper.checkInputsVisibility(sdkRequest: sdkRequest, shopperDetails: sdkRequest.shopperConfiguration.billingDetails)
        
        // check Store Card view visibility
        paymentHelper.checkStoreCardVisibility(shouldBeVisible: true)
        
        // check that the Store Card is mandatory
        paymentHelper.checkStoreCardMandatory()
        
        if (checkoutWithShipping) {
            // check pay button when shipping same as billing is on
            paymentHelper.checkPayButton(sdkRequest: sdkRequest, shippingSameAsBilling: isShippingSameAsBillingOn, subscriptionHasPriceDetails: trialPeriodDays == nil)
            
            setShippingSameAsBillingSwitch(shouldBeOn: false)
            
            // check pay button when shipping same as billing is off
            paymentHelper.checkPayButton(sdkRequest: sdkRequest, shippingSameAsBilling: isShippingSameAsBillingOn, subscriptionHasPriceDetails: trialPeriodDays == nil)
            
            // continue to shipping screen
            setStoreCardSwitch(shouldBeOn: true)
            gotoShippingScreen()
            
            // check Inputs Fields visibility (including error messages)
            shippingHelper.checkInputsVisibility(sdkRequest: sdkRequest, shopperDetails: sdkRequest.shopperConfiguration.shippingDetails)
            
            // check shipping pay button
            shippingHelper.checkPayButton(sdkRequest: sdkRequest, subscriptionHasPriceDetails: trialPeriodDays == nil)
        }
        
        else {
            paymentHelper.checkPayButton(sdkRequest: sdkRequest, shippingSameAsBilling: false, subscriptionHasPriceDetails: trialPeriodDays == nil)
        }
    }
    
    
    /* -------------------------------- Subscription views tests ---------------------------------------- */

    func testViewsNoFullBillingNoShippingNoEmail_withoutPriceDetails() {
        subscriptionViewsCommomTester(checkoutFullBilling: false, checkoutWithEmail: false, checkoutWithShipping: false, trialPeriodDays: 30)
    }
    
    func testViewsNoFullBillingNoShippingNoEmail_withPriceDetails() {
        subscriptionViewsCommomTester(checkoutFullBilling: false, checkoutWithEmail: false, checkoutWithShipping: false)
    }
    
    func testViewsFullBillingWithShippingWithEmail_withoutPriceDetails() {
        subscriptionViewsCommomTester(checkoutFullBilling: true, checkoutWithEmail: true, checkoutWithShipping: true, trialPeriodDays: 28)
    }
    
    func testViewsFullBillingWithShippingWithEmail_withPriceDetails() {
        subscriptionViewsCommomTester(checkoutFullBilling: true, checkoutWithEmail: true, checkoutWithShipping: true)
    }
    
    /* -------------------------------- Subscription end-to-end flow tests ---------------------------------------- */
    
    func testFlowNoFullBillingNoShippingNoEmail() {
        newCardBasicCheckoutFlow(fullBilling: false, withShipping: false, withEmail: false, storeCard: true, isSubscription: true)
    }
    
    func testFlowFullBillingWithShippingWithEmail() {
        newCardBasicCheckoutFlow(fullBilling: true, withShipping: true, withEmail: true, storeCard: true, isSubscription: true)
    }
    
    func testFlowShippingSameAsBilling() {
        newCardBasicCheckoutFlow(fullBilling: true, withShipping: true, withEmail: true, shippingSameAsBilling: true, storeCard: true, isSubscription: true)
    }
}
