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
    @IBOutlet weak var taxPercentTextField: UITextField!
    @IBOutlet weak var resultTextView: UITextView!
    @IBOutlet weak var fullBillingSwitch: UISwitch!
    
    // MARK: private properties
    
    fileprivate var bsToken : BSToken?
    fileprivate var checkoutDetails = BSCheckoutDetails()
 
	// MARK: - UIViewController's methods
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
		self.view.addGestureRecognizer(tap)
        
        //Init Kount
        //NSLog("Kount Init");
        //BlueSnapSDK.KountInit();
        
        generateAndSetBsToken()
        listenForBsTokenExpiration()

        resultTextView.text = ""
 	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationController?.isNavigationBarHidden = true
	}
	
	// MARK: - Dismiss keyboard
	
	func dismissKeyboard() {
		valueTextField.resignFirstResponder()
	}

	// MARK: - Actions
	
	@IBAction func convertButtonAction(_ sender: UIButton) {
        
        resultTextView.text = ""
        
        // for debug - supply initial values:
        if fullBillingSwitch.isOn == true {
            if let billingDetails = checkoutDetails.getBillingDetails() {
                billingDetails.name = "John Doe"
                billingDetails.address = "333 elm st"
                billingDetails.city = "New York"
                billingDetails.zip = "532464"
                billingDetails.country = "US"
                billingDetails.state = "MA"
                billingDetails.email = "john@gmail.com"
            }
        }
        if withShippingSwitch.isOn {
            if checkoutDetails.getShippingDetails() == nil {
                checkoutDetails.setShippingDetails(shippingDetails: BSAddressDetails())
            }
            if let shippingDetails = checkoutDetails.getShippingDetails() {
                shippingDetails.name = "Mary Doe"
                shippingDetails.address = "333 elm st"
                shippingDetails.city = "New York"
                shippingDetails.country = "US"
                shippingDetails.state = "MA"
                shippingDetails.email = "mary@gmail.com"
            }
        }
        
        // open the purchase screen
        fillPaymentDetails()
        BlueSnapSDK.showCheckoutScreen(
            inNavigationController: self.navigationController,
            animated: true,
            checkoutDetails: checkoutDetails,
            withShipping: withShippingSwitch.isOn,
            fullBilling: fullBillingSwitch.isOn,
            purchaseFunc: completePurchase)
	}
	
	@IBAction func currencyButtonAction(_ sender: UIButton) {
        
        fillPaymentDetails()
        BlueSnapSDK.showCurrencyList(
            inNavigationController: self.navigationController,
            animated: true,
            selectedCurrencyCode: checkoutDetails.getCurrency(),
            updateFunc: updateViewWithNewCurrency)
	}
	
	// MARK: - UIPopoverPresentationControllerDelegate
	
	func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
		return UIModalPresentationStyle.none
	}
    
    // MARK: private methods
    private func fillPaymentDetails() {
        
        let amount = (valueTextField.text! as NSString).doubleValue
        let taxPercent = (taxPercentTextField.text! as NSString).doubleValue
        let taxAmount = (taxTextField.text! as NSString).doubleValue + (taxPercent * amount / 100.0)
        
        checkoutDetails.setAmountsAndCurrency(amount: amount, taxAmount: taxAmount, currency: checkoutDetails.getCurrency())
    }
    
    private func updateViewWithNewCurrency(oldCurrency : BSCurrency?, newCurrency : BSCurrency?) {
        
        print("before change currency: currency=\(checkoutDetails.getCurrency()), amount = \(checkoutDetails.getAmount())")
        checkoutDetails.changeCurrency(oldCurrency: oldCurrency, newCurrency: newCurrency!)
        print("after change currency: currency=\(checkoutDetails.getCurrency()), amount = \(checkoutDetails.getAmount())")
        valueTextField.text = String(checkoutDetails.getAmount())
        taxTextField.text = String(checkoutDetails.getTaxAmount())
        currencyButton.titleLabel?.text = checkoutDetails.getCurrency()
    }
    
    private func completePurchase(checkoutDetails: BSCheckoutDetails!) {
        print("Here we should call the server to complete the transaction with BlueSnap")
        
        let demo = DemoTreansactions()
        let result : (success:Bool, data: String?) = demo.createCreditCardTransaction(
            checkoutDetails: checkoutDetails,
            bsToken: bsToken!)
        logResultDetails(result)
        if (result.success == true) {
            resultTextView.text = "BLS transaction created Successfully!\n\n\(result.data!)"
        } else {
            let errorDesc = result.data ?? ""
            resultTextView.text = "An error occurred trying to create BLS transaction.\n\n\(errorDesc)"
        }
    }
    
    private func logResultDetails(_ result : (success:Bool, data: String?)) {
        
        NSLog("--------------------------------------------------------")
        NSLog("Result success: \(result.success)")
        if let billingDetails = checkoutDetails.getBillingDetails() {
            NSLog("Result Data: Name:\(billingDetails.name)")
            if let zip = billingDetails.zip {
                NSLog(" Zip code:\(zip)")
            }
            if self.fullBillingSwitch.isOn {
                NSLog(" Email:\(billingDetails.email ?? "")")
                NSLog(" Street address:\(billingDetails.address ?? "")")
                NSLog(" City:\(billingDetails.city ?? "")")
                NSLog(" Country code:\(billingDetails.country ?? "")")
                NSLog(" State code:\(billingDetails.state ?? "")")
            }
        }
        if let shippingDetails = checkoutDetails.getShippingDetails() {
            NSLog("Shipping Data: Name:\(shippingDetails.name)")
            NSLog(" Zip code:\(shippingDetails.zip ?? "")")
            NSLog(" Email:\(shippingDetails.email ?? "")")
            NSLog(" Street address:\(shippingDetails.address ?? "")")
            NSLog(" City:\(shippingDetails.city ?? "")")
            NSLog(" Country code:\(shippingDetails.country ?? "")")
            NSLog(" State code:\(shippingDetails.state ?? "")")
        }
        NSLog("--------------------------------------------------------")
    }
    
    // MARK: BS Token functions
    
    // create a test BS token and set it in BlueSnapSDK
    func generateAndSetBsToken() {
        
        do {
            bsToken = try BlueSnapSDK.createSandboxTestToken()
            BlueSnapSDK.setBsToken(bsToken: bsToken)
        } catch {
            NSLog("Error: Failed to get BS token")
            fatalError()
        }
        NSLog("Got BS token= \(bsToken!.getTokenStr())")
    }
    
    func listenForBsTokenExpiration() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(bsTokenExpired), name: Notification.Name.bsTokenExpirationNotification, object: nil)
    }
    
    func bsTokenExpired() {
        
        NSLog("Got BS token expiration notification!")
        generateAndSetBsToken()
    }
}

