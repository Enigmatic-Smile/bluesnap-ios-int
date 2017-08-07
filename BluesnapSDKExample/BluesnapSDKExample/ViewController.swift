//
//  ViewController.swift
//  RatesSwiftExample
//
////

import UIKit
import BluesnapSDK

class ViewController: UIViewController {
	
	// MARK: - Outlets
	
	@IBOutlet weak var currencyButton: UIButton!
	@IBOutlet weak var valueTextField: UITextField!
	@IBOutlet weak var convertButton: UIButton!
    @IBOutlet weak var withShippingSwitch: UISwitch!
    @IBOutlet weak var taxTextField: UITextField!
    @IBOutlet weak var resultTextView: UITextView!
    @IBOutlet weak var fullBillingSwitch: UISwitch!
    
    // MARK: private properties
    
    fileprivate var bsToken : BSToken?
    fileprivate var initialData: BSInitialData! = BSInitialData()
 
	// MARK: - UIViewController's methods
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		registerTapToHideKeyboard()
        
        //Init Kount
        //NSLog("Kount Init");
        //BlueSnapSDK.KountInit();
        
        generateAndSetBsToken()
        setApplePayIdentifier()
        listenForBsTokenExpiration()

        resultTextView.text = ""
        
        // Example of using BSImageLibrary
        //if let img = BSImageLibrary.getFlag(countryCode: "US") {
        //}
 	}
	
	override func viewWillAppear(_ animated: Bool) {
        
		super.viewWillAppear(animated)
		self.navigationController?.isNavigationBarHidden = true
	}
	
	// MARK: - Dismiss keyboard
	
    func registerTapToHideKeyboard() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tap)
    }

    func dismissKeyboard() {
        if valueTextField.isFirstResponder {
            valueTextField.resignFirstResponder()
        } else if taxTextField.isFirstResponder {
            taxTextField.resignFirstResponder()
        }
    }

	// MARK: - Actions
	
	@IBAction func convertButtonAction(_ sender: UIButton) {
        
        resultTextView.text = ""
        
        // If you have the shopper details, you can supply initial values like this:
        //setInitialShopperDetails()
        
        // Override the navigation name, so that the next screen navigation item will say "Cancel"
        let backItem = UIBarButtonItem()
        backItem.title = "Cancel"
        navigationItem.backBarButtonItem = backItem

        // open the purchase screen
        fillInitialData()
        BlueSnapSDK.showCheckoutScreen(
            inNavigationController: self.navigationController,
            animated: true,
            initialData: initialData,
            purchaseFunc: completePurchase)
	}
	
	@IBAction func currencyButtonAction(_ sender: UIButton) {
        
        fillInitialData()
        BlueSnapSDK.showCurrencyList(
            inNavigationController: self.navigationController,
            animated: true,
            selectedCurrencyCode: initialData.priceDetails.currency,
            updateFunc: updateViewWithNewCurrency,
            errorFunc: { self.showErrorAlert(message: "Failed to display currency List, please try again") })
	}
	
	// MARK: - UIPopoverPresentationControllerDelegate
	
	func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
		return UIModalPresentationStyle.none
	}
    
    // MARK: private methods
    
    /**
        If you have the shopper details, you can supply initial values to the BlueSnap purchasde flow.
        This is just an exmaple with hard-coded values.
        You can supply partial data as you have it.
    */
    private func setInitialShopperDetails() {
        
        if let billingDetails = initialData.billingDetails {
            billingDetails.name = "John Doe"
            billingDetails.address = "333 elm st"
            billingDetails.city = "New York"
            billingDetails.zip = "532464"
            billingDetails.country = "US"
            billingDetails.state = "MA"
            billingDetails.email = "john@gmail.com"
        }
        if withShippingSwitch.isOn {
            if initialData.shippingDetails == nil {
                initialData.shippingDetails = BSShippingAddressDetails()
            }
            if let shippingDetails = initialData.shippingDetails {
                shippingDetails.name = "Mary Doe"
                shippingDetails.address = "333 elm st"
                shippingDetails.city = "New York"
                shippingDetails.country = "US"
                shippingDetails.state = "MA"
            }
        }
    }
    
    /**
     Show error pop-up
     */
    private func showErrorAlert(message: String) {
        let alert = createErrorAlert(title: "Oops", message: message)
        present(alert, animated: true, completion: nil)
    }

    private func createErrorAlert(title: String, message: String) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in })
        alert.addAction(cancel)
        return alert
        //After you create alert, you show it like this: present(alert, animated: true, completion: nil)
    }

    /**
     Here we adjust the checkout details with the latest amounts from the fields on our view.
    */
    private func fillInitialData() {
        
        let amount = (valueTextField.text! as NSString).doubleValue
        let taxAmount = (taxTextField.text! as NSString).doubleValue
        let currency = currencyButton.titleLabel?.text ?? "USD"
        initialData.priceDetails = BSPriceDetails(amount: amount, taxAmount: taxAmount, currency: currency)
        initialData.withShipping = withShippingSwitch.isOn
        initialData.fullBilling = fullBillingSwitch.isOn
    }
    
    /**
     This function is called by the change currency screen when the user changes the currency.
     Here we update yhje checkout details and the fields in our view according tp the new currency.
    */
    private func updateViewWithNewCurrency(oldCurrency : BSCurrency?, newCurrency : BSCurrency?) {
        
        if let priceDetails = initialData.priceDetails {
            if let newCurrency = newCurrency {
                var oldRate : Double = 1.0
                if let oldCurrency = oldCurrency {
                    oldRate = oldCurrency.getRate() ?? 1.0
                }
                // convert the prices back to $
                priceDetails.amount = priceDetails.amount / oldRate
                priceDetails.taxAmount = priceDetails.taxAmount / oldRate
                
                priceDetails.currency = newCurrency.getCode()
                priceDetails.amount = priceDetails.amount * newCurrency.getRate()
                priceDetails.taxAmount = priceDetails.taxAmount * newCurrency.getRate()
            }
            
            valueTextField.text = String(priceDetails.amount)
            taxTextField.text = String(priceDetails.taxAmount)
            currencyButton.titleLabel?.text = priceDetails.currency
        }
    }
    
    /**
     This is the callback we pass to BlueSnap SDK; it will be called when all the shopper details have been
     enetered, and the secured payment details have been successfully submitted to BlueSnap server.
     In a real app, you would send the checkout details to your app server, which then would call BlueSnap API
     to execute the purchase.
     In this sample app we do it client-to-server, but this is not the way to do it in a real app.
    */
    
    private func completePurchase(paymentRequest: BSBasePaymentRequest!) {
        
        if let paypalPaymentRequest = paymentRequest as? BSPayPalPaymentRequest {
            
            NSLog("PayPal transaction completed Successfully! invoice ID: \(paypalPaymentRequest.payPalInvoiceId ?? "")")
            showThankYouScreen(errorText: nil)
            return // no need to complete purchase via BlueSnap API
        }
        
        // The creation of BlueSnap Demo transaction here should be done in the merchant server!!!
        // This is just for demo purposes
        
        let demo = DemoTreansactions()
        var result: (success: Bool, data: String?) = (false, nil)
        if let applePayPaymentRequest = paymentRequest as? BSApplePayPaymentRequest {
            
            result = demo.createApplePayTransaction(paymentRequest: applePayPaymentRequest, bsToken: bsToken!)
            logResultDetails(result, paymentRequest: applePayPaymentRequest)
            
        } else if let ccPaymentRequest = paymentRequest as? BSCcPaymentRequest {
            
            let ccDetails = ccPaymentRequest.ccDetails
            print("CC Issuing country: \(ccDetails.ccIssuingCountry ?? "")")
            print("CC type: \(ccDetails.ccType ?? "")")
            print("CC last 4 digits: \(ccDetails.last4Digits ?? "")")
            result = demo.createCreditCardTransaction(paymentRequest: ccPaymentRequest, bsToken: bsToken!)
            logResultDetails(result, paymentRequest: ccPaymentRequest)
        }
        
        // Show success/fail screen
        if result.success == true {
            NSLog("BLS transaction created Successfully!\n\n\(result.data!)")
            showThankYouScreen(errorText: nil)
        } else {
            let errorText = result.data ?? ""
            NSLog("An error occurred trying to create BLS transaction.\n\n\(errorText)")
            showThankYouScreen(errorText: errorText)
        }
    }
    
    
    private func showThankYouScreen(errorText: String?) {
        
        // Show thank you screen (ThankYouViewController)
        if let thankYouScreen = storyboard?.instantiateViewController(withIdentifier: "ThankYouViewController") as? ThankYouViewController {
            thankYouScreen.errorText = errorText
            self.navigationController?.pushViewController(thankYouScreen, animated: true)
        } else {
            resultTextView.text = "An error occurred trying to show the Thank You screen."
        }
    }
    
    private func logResultDetails(_ result : (success:Bool, data: String?), paymentRequest: BSBasePaymentRequest!) {
        
        NSLog("--------------------------------------------------------")
        NSLog("Result success: \(result.success)")
        
        NSLog(" amount=\(paymentRequest.getAmount() ?? 0.0)")
        NSLog(" tax=\(paymentRequest.getTaxAmount() ?? 0.0)")
        NSLog(" currency=\(paymentRequest.getCurrency() ?? "")")
        NSLog(" payment type= \(paymentRequest.paymentType)")
        
        if let paymentRequest = paymentRequest as? BSCcPaymentRequest {
            if let billingDetails = paymentRequest.getBillingDetails() {
                NSLog("Result Data: Name:\(billingDetails.name ?? "")")
                if let zip = billingDetails.zip {
                    NSLog(" Zip code:\(zip)")
                }
                if let email = billingDetails.email {
                    NSLog(" Email:\(email)")
                }
                if self.fullBillingSwitch.isOn {
                    NSLog(" Street address:\(billingDetails.address ?? "")")
                    NSLog(" City:\(billingDetails.city ?? "")")
                    NSLog(" Country code:\(billingDetails.country ?? "")")
                    NSLog(" State code:\(billingDetails.state ?? "")")
                }
            }
            
            if let shippingDetails = paymentRequest.getShippingDetails() {
                NSLog("Shipping Data: Name:\(shippingDetails.name ?? "")")
                NSLog(" Phone:\(shippingDetails.phone ?? "")")
                NSLog(" Zip code:\(shippingDetails.zip ?? "")")
                NSLog(" Street address:\(shippingDetails.address ?? "")")
                NSLog(" City:\(shippingDetails.city ?? "")")
                NSLog(" Country code:\(shippingDetails.country ?? "")")
                NSLog(" State code:\(shippingDetails.state ?? "")")
            }
            
        } else if let _ = paymentRequest as? BSApplePayPaymentRequest {
            NSLog("No extra data")
            
        } else if let paymentRequest = paymentRequest as? BSPayPalPaymentRequest {
            NSLog("PayPal invoice ID:\(paymentRequest.payPalInvoiceId ?? "")")
        }
        NSLog("--------------------------------------------------------")
    }
    
    // MARK: BS Token functions
    
    /**
     Create a test BS token and set it in BlueSnapSDK.
     In a real app, you would get the token from your app server.
     */
    func generateAndSetBsToken() {
        
        do {
            //// simulate expired token for first time
            //let simulateTokenExpired = bsToken == nil
            bsToken = try BlueSnapSDK.createSandboxTestToken()
            //if simulateTokenExpired {
            //    bsToken = BSToken(tokenStr: "5e2e3f50e287eab0ba20dc1712cf0f64589c585724b99c87693a3326e28b1a3f_", serverUrl: bsToken?.getServerUrl())
            //}
            BlueSnapSDK.setBsToken(bsToken: bsToken)
        } catch {
            NSLog("Error: Failed to get BS token")
            fatalError()
        }
        NSLog("Got BS token= \(bsToken!.getTokenStr())")
    }

    func setApplePayIdentifier() {
        _ = BlueSnapSDK.setApplePayMerchantIdentifier(merchantId: "merchant.com.example.bluesnap")
    }
    
    /**
     Add observer to the token expired event sent by BlueSnap SDK.
    */
    func listenForBsTokenExpiration() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(bsTokenExpired), name: Notification.Name.bsTokenExpirationNotification, object: nil)
    }
    
    /**
     Called by the observer to the token expired event sent by BlueSnap SDK.
     Here we generate and set a new token, so that when the user tries again, the action will succeed.
     */
    func bsTokenExpired() {
        
        NSLog("Got BS token expiration notification!")
        generateAndSetBsToken()
    }
}

