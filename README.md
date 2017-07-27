

# BlueSnap IOS SDK

The BlueSnap IOS SDK is intended to give IOS application developers an easy tool for managing the check-out payment details without having to be PCI compliant, and without having to create the billing/shipping UI and functionality.

We provide a simple start function that begins the whole process, and calls your app back when the shopper has approved the purchase.

The example app we provide shows you how to use all the functionality.

Please note that this SDK is for obtaining the payment details from the shopper. Before that you need to obtain a token from BlueSnap server API, and after you get the payment details, you need to call BlueSnap API again to complete the purchase. To learn more about BlueSnap API go to http://developers.bluesnap.com/.

The SDK is written in Swift 3, using xCode 8.
 
## Checkout Flow Options

The SDK offers you several types of purchase flows when you use our UI:

 - **With shipping** - includes an extra page for the shopper to fill out shipping details
 - **Full billing** - you can choose to ask the shopper only for minimal details (like name and CC details), or if you choose, get the full billing address and email as well.
 - **Do it yourself** - if you do not want to use our UI, you can use just the functionality that submits the PCI details to BlueSnap, and handle all the rest yourself. We also provide UI components for collecting the CC details and several helper classes.

## Where to start

If you are a top-to-bottom person, skip ahead to the section that explains the sample app and look at the code. Look up functions as you go along.

If you are a bottom-to-top person, read on about the data structures and classes we offer you.
## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 1.1.0+ is required to build this SDK

To integrate BluesnapSDK into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'BluesnapSDK', '~> 0.3'
end
```

Then, run the following command:

```bash
$ pod install
```
>Use the .xcworkspace file to open your project in Xcode.


### Objective C Applications
This SDK is written in Swift, If your application is written in Objective-C than you might need to embed swift runtime library. Please follow the link below to set up your project accordingly:
https://developer.apple.com/library/content/qa/qa1881/_index.html

# Data Structures

In the BlueSnap IOS SDK project you have a Model group which contains the data structures we use.
 
## BSToken (in BSToken.swift)

BSToken is the simplest one. It contains the token you got from BlueSnap, and the domain (for example: "https://api.bluesnap.com/")

    public class BSToken {
	    internal var tokenStr: String! = ""
	    internal var serverUrl: String! = ""
	    public init(tokenStr : String!, serverUrl : String!) {
	        self.tokenStr = tokenStr
	        self.serverUrl = serverUrl
	    }
	    public func getTokenStr() -> String! {
	        return self.tokenStr
	    }
	    public func getServerUrl() -> String! {
        	return self.serverUrl
    	    }
	}

The SDK holds a function for obtaining a token from our Sandbox environment for quick testing purposes.
 
## BSBaseAddressDetails, BSBillingAddressDetails, BSShippingAddressDetails (in BSPurchaseDataModel.swift)

These classes hold the shopper details for either billing or shipping. 
Optional/Mandatory:
State is mandfatopry only if the country has state (USA, Canada and Brazil).
Zip is mandatory except for countries that have no postal/zip code.
If you choose not to use the full billing option - only name, country and zip are filled, email is optional.
For full billing details, everything is mandatory except email which is optional.
For shipping details all field are mandatory except phone which is optional.

    public class BSBaseAddressDetails {
    
    	public init() {}
    
    	public var name : String! = ""
    	public var address : String?
    	public var city : String?
    	public var zip : String?
    	public var country : String?
    	public var state : String?
    
    	public func getSplitName() -> (firstName: String, lastName: String)? {
        	return BSStringUtils.splitName(name)
    	}
    }

    public class BSBillingAddressDetails : BSBaseAddressDetails {
    
    	public override init() { super.init() }
    	public var email : String?
    }

    public class BSShippingAddressDetails : BSBaseAddressDetails {
    
    	public override init() { super.init() }
    	public var phone : String?
    }


## BSPaymentType

This enum differentiates between the payment method the shopper chose. It will contain Credit-card, Apple-Pay, PayPal and more.

    public enum BSPaymentType {
    	case CreditCard
    	case ApplePay
	}

## BSResultPaymentDetails (in BSPurchaseDataModel.swift)

This is a base class for the payment-specific details like BSResultApplePayDetails and BSResultCcDetails.

    public class BSResultPaymentDetails {
	    var paymentType : BSPaymentType!
    }

## BSResultCcDetails (in BSPurchaseDataModel.swift)

This class inherits BSResultPaymentDetails, and holds the result of submitting Credit Card details to BlueSnap - this data is not secure.

    public class BSResultCcDetails : BSResultPaymentDetails {
	    var ccType : String?
	    var last4Digits : String?
	    var ccIssuingCountry : String?
    }

## BSResultApplePayDetails (in BSPurchaseDataModel.swift)

This class inherits BSResultPaymentDetails, and holds the result of submitting Apple-Pay details to BlueSnap.

    public class BSResultApplePayDetails : BSResultPaymentDetails {
    }

## BSPaymentRequest (in BSPurchaseDataModel.swift)

The central data structure is this class, which holds shopper data that is both input and output. You can provide any data you know about the shopper (like name or email), so we can pre-populate the input fields to make the purchase easier. This is an abbreviated version of the class:

    public class BSpaymentRequest : NSObject {
    
    // These 3 fields are input + output (they may change if shopper changes currency)
    var amount : Double! = 0.0
    var taxAmount : Double! = 0.0
    var currency : String! = "USD"
    
    // These fields are output, but may be supplied as input as well
    var billingDetails : BSBillingAddressDetails! = BSBillingAddressDetails()
    var shippingDetails : BSShippingAddressDetails?
    
    // Output only - result of submitting the payment details to BlueSnap server
    var resultPaymentDetails : BSResultPaymentDetails?

    // MARK: Change currency methods
    
    /*
    Set amounts will reset the currency and amounts, including the original
    amounts.
    */
    public func setAmountsAndCurrency(amount: Double!, taxAmount: Double?, currency: String) {
        ...
    }
	/*
    Change currency will also change the amounts according to the change rates
    */
    public func changeCurrency(oldCurrency: BSCurrency?, newCurrency : BSCurrency?) {
        ...
    }
    
    // MARK: getters and setters
    ...
}


# Main Functionality - BlueSnapSDK class

The class BlueSnapSDK is the one that holds the functions you want to call to use our custom check-out. Let's explain each one.

## setBsToken
This function sets the token we will use when calling BlueSnap server API. It must be set at the beginning of the flow with a valid token obtained from your server, by calling BlueSnap server to generate a token.
Signature:
> open class func setBsToken(bsToken: BSToken!)
 
The token expires after 20 minutes, so be sure to generate a new one for each purchase, and also listen for the token expiration event to generate a new one if needed. More explanation below.

## showCheckoutScreen
This is the main function, and actually the only one you need to use normally (after setBsToken): once you call it, the SDK starts the check-out flow of choosing payment method and on to getting the shopper details.

Parameters:

 - inNavigationController: your viewController's navigationController (to be able to navigate back)
 - animated: how to navigate to the new screen
 - paymentRequest: object that holds the shopper and payment details; shopper name and shipping details may be pre-filled
 - withShipping: if true, the shopper will be asked to supply shipping details
 - fullBilling: if true, we collect full billing address; otherwise only name and optionally zip code
 - purchaseFunc: callback; will be called when the shopper hits "Pay" and all the data is ready

Signature:
> open class func showCheckoutScreen(
        inNavigationController: UINavigationController!,
        animated: Bool,
        paymentRequest: BSPaymentRequest!,
        withShipping: Bool,
        fullBilling : Bool,
        purchaseFunc: @escaping (BSPaymentDetails!)->Void)
 
## submitCcDetails
Submit Payment fields:
If you do not want to use our check-out page, you can implement your own.
You need to generate a token, and then call this function to submit the CC details you collected from the shopper to BlueSnap [instead of returning them to your server (which is less secure) and then passing them to BlueSnap when you create the transaction]. Just pass the 3 CC fields to this function and you can forget about them :)

Parameters:

 - ccNumber: Credit card number
 - expDate: CC expiration date in format MM/YYYY
 - cvv: CC security code (CVV)
 - completion: callback with either result details if OK, or error details if not OK

Signature:
> open class func submitCcDetails(ccNumber: String, expDate: String, cvv: String, completion : @escaping (BSResultCcDetails?,BSErrors?)->Void)
 
## createSandboxTestToken
Returns a token for BlueSnap Sandbox environment; useful for tests.
In your real app, the token should be generated on the server side and passed to the app, so that the app will not expose the username/password

Signature:
>open class func getSandboxTestToken() throws -> BSToken?
 

# Handling Token Expiration

Under the model file BSToken.swift you will find this extension, which holds the notification name we use for notifying a stale token:
public extension Notification.Name {
    static let bsTokenExpirationNotification = Notification.Name("bsTokenExpirationNotification")
}

If you look at the example app ViewCiontroller.swift, you will see at the bottom the functions that handle the token.
listenForBsTokenExpiration() - this function is called to start listening to the event;
bsTokenExpired() - this function handles the error by generating a new token.
 
Whhen the user gets an error, if you re-generate a token and he tries to submit again - the second submit (with the new token) will succeed. Otherwise your poor shopper will continue getting errors :)
 
 
# Helper Classes
We provide several classes that give some functionality you can use if you want to build your own checkout flow or re-use our code in any way.
 
## String Utils and Validations
**BSStringUtils** supplies string helper functions like removeWhitespaces, removeNoneDigits, etc.
**BSValidator** provides lots of validation functions like isValidEmail, getCcLengthByCardType, formatCCN, getCCTypeByRegex, etc.
The code is self-explanatory and has comments where needed.
 
## Handling currencies and rates
In our UI we allow the shopper to change the used currency. In case you need this functionality in your app, we provide easy methods to do that.
### Currency Data Structures
We have 2 data structures (see BSCurrencyModel.swift|): BSCurrency holds a single currency, and  BSCurrencies holds all the currencies.
>public class BSCurrency {
    internal var name : String!
    internal var code : String!
    internal var rate: Double!
...
}
public class BSCurrencies {
   ...
    public func getCurrencyByCode(code : String!) -> BSCurrency? {
        ...
    }
    public func getCurrencyIndex(code : String) -> Int? {
        ...
    }
    public func getCurrencyRateByCurrencyCode(code : String!) -> Double? {
        ...
    }
}
 
### Currency Functionality (in BlueSnapSDK class):

**getCurrencyRates**

This function returns a list of currencies and their rates from BlueSnap server

Parameters:
 - throws BSApiErrors

Signature:
> open class func getCurrencyRates() throws -> BSCurrencies?
 
**showCurrencyList**

This function navigates to the currency list, allow changing current selection.

Parameters:
 - inNavigationController: your viewController's navigationController (to be able to navigate back)
 - animated: how to navigate to the new screen
 - selectedCurrencyCode: 3 characters of the current language code (uppercase)
 - updateFunc: callback; will be called each time a new value is selected
 - errorFunc: callback; will be called if we fail to get the currencies

Signature:
>open class func showCurrencyList(
        inNavigationController: UINavigationController!,
        animated: Bool,
        selectedCurrencyCode : String!,
        updateFunc: @escaping (BSCurrency?, BSCurrency?)->Void,
        errorFunc: @escaping()->Void)
 
 
## Custom UI Controls
If you want to build your own UI, you may find our custom controls useful, in themselves or to inherit from them and adjust to your own functionality.

There are a lot of comments inside the code, explaining how to use them and what each function does.

All 3 are @IBDesignable UIViews, so you can easily check them out: simply drag a UIView into your Storyboard, change the class name to one of these below, and start playing with the inspectable properties.

### BSBaseTextInput
BSBaseTextInput is a UIView that holds a text field and optional image; you can customize almost every part of it. It is less useful in itself, seeing it?s a base class for the following 2 controls.
### BSInputLine
BSInputLine is a UIView that holds a label, text field and optional image; you can customize almost every part of it.
### BSCcInputLine
BSCcInputLine is a UIView that holds the credit card fields (Cc number, expiration date and CVV); besides a cool look & feel it also handles its own validations and submits the secured data to the BlueSnap server, so that your application does not have to handle it.

       
# Apple Pay integration

Accepting payments with apple pay using Bluesnap iOS SDK is easy, you don't need to deal with encrypted credit card details or any sensitive information in your server side. The SDK checkout screen includes an Apple Pay button that will be displayed if the device supports apple pay.
In order to enable it in your app few steps has to be taken.

>1. Obtain an Apple Merchant ID using the Apple Developer Website, you'll find it under the Registering a Merchant ID page.
>2. Download a CSR from bluesnap
>3. Generate a certificate with that CSR and upload it to BlueSnap
>4. Enable apple pay Capabilities in Xcode project settings
>5. Select the Merchant ID that you created in Apple Dashboard
>6. Pass your Merchant ID to BlueSnap SDK by calling:
    `    BlueSnapSDK.setApplePayMerchantIdentifier(merchantId: "merchant.com.example")`
    
After a user complete the checkout and pays with apple pay the SDK will call your completion callback, with the PaymentRequest containing the result of the purchase.

Calling paymentRequest.getResultPaymentDetails() will return a BSResultApplePayDetails that can be used to complete the transaction in your server.
You'll find a sample of this HTTP call in DemoTransactions.swift, you should implement those calls in your *server*.
 

# Sample App - explained

The sample app shows the various stages you need to implement (everything is in class ViewController):

 1. Get a token from the BlueSnap server ? normally, you need to do this in your server-side implementation (so as not to expose your BlueSnap username/pass in the app code). In the sample app we create a token from BlueSnap Sandbox environment, with dummy credentials. Call BLueSnapSDK.setToken() to set it.
 2. Initialize the input to the checkout flow: create an instance of BSPaymentRequest and fill the parts you may know already of the shopper.
 3. Call BlueSnapSDK.showCheckoutScreen() with callback for completion
 4. In that callback you need to call your application server to complete the purchase using BlueSnap API. In the sample app you'll find an implementation of those calls, those are demonstration purpose only and should be made in your server side.

And that?s it!
 
*Note*: our pages do not support landscape mode, so in order to make sure the screen does not rotate with the device (and look bad), you need to add this code to your application's AppDelegate.swift file:

    // MARK: Prevent auto-rotate
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask(rawValue: UIInterfaceOrientationMask.portrait.rawValue)
    }


