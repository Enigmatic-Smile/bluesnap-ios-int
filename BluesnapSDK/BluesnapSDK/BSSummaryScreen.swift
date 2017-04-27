
import UIKit

class BSSummaryScreen: UIViewController {

	// MARK: - Public properties
	
    internal var purchaseData : PurchaseData!
    internal var bsToken: BSToken!
    
    // MARK: private properties
    
    fileprivate var withShipping = false
    fileprivate var shippingScreen: BSShippingViewController!
    
    // MARK: Constants
    
    fileprivate let privacyPolicyURL = "http://home.bluesnap.com/ecommerce/legal/privacy-policy/"
    fileprivate let refundPolicyURL = "http://home.bluesnap.com/ecommerce/legal/refund-policy/"
    fileprivate let termsURL = "http://home.bluesnap.com/ecommerce/legal/terms-and-conditions/"
    fileprivate let nameInvalidMessage = "Please fill Card holder name"
    fileprivate let ccnInvalidMessage = "Please fill a valid Credirt Card number"
    fileprivate let cvvInvalidMessage = "Please fill a valid CVV number"
    fileprivate let expInvalidMessage = "Please fill a valid exiration date"
    fileprivate let doValidations = true;
	
	// MARK: - Data
	
    fileprivate var payButtonText : String?
	
	// MARK: - Outlets
    
    @IBOutlet weak var payButton: UIButton!
    @IBOutlet weak var nameUiTextyField: UITextField!
    @IBOutlet weak var cardUiTextField: UITextField!
    @IBOutlet weak var ExpYYUiTextField: UITextField!
    @IBOutlet weak var ExpMMUiTextField: UITextField!
    @IBOutlet weak var cvvUiTextField: UITextField!
    @IBOutlet weak var ccnErrorUiLabel: UILabel!
    @IBOutlet weak var nameErrorUiLabel: UILabel!
    @IBOutlet weak var expErrorUiLabel: UILabel!
    @IBOutlet weak var cvvErrorUiLabel: UILabel!
    @IBOutlet weak var subtotalUILabel: UILabel!
    @IBOutlet weak var taxAmountUILabel: UILabel!
    @IBOutlet weak var menuWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var menuCurrencyButton: UIButton!

    
	// MARK: - UIViewController's methods


    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationController!.isNavigationBarHidden = false

        self.withShipping = purchaseData.getShippingDetails() != nil
        updateTexts()
        
        // hide menu
        menuWidthConstraint.constant = 0
	}
    
    
    // MARK: private methods
    
    private func updateTexts() {
        
        let toCurrency = purchaseData.getCurrency() ?? ""
        let subtotalAmount = purchaseData.getAmount() ?? 0.0
        let taxAmount = (purchaseData.getTaxAmount() ?? 0.0) + (purchaseData.getTaxPercent() ?? 0.0) * subtotalAmount / 100.0
        let amount = subtotalAmount + taxAmount
        let currencyCode = (toCurrency == "USD" ? "$" : toCurrency)
        payButtonText = String(format:"Pay %@ %.2f", currencyCode, CGFloat(amount))
        if (self.withShipping) {
            payButton.setTitle("Shipping ->", for: UIControlState())
        } else {
            payButton.setTitle(payButtonText, for: UIControlState())
        }
        subtotalUILabel.text = String(format:" %@ %.2f", currencyCode, CGFloat(subtotalAmount))
        taxAmountUILabel.text = String(format:" %@ %.2f", currencyCode, CGFloat(taxAmount))
    }
    
    private func updateViewWithNewCurrency(oldCurrency : BSCurrency?, newCurrency : BSCurrency?) {
        
            purchaseData.changeCurrency(oldCurrency: oldCurrency, newCurrency: newCurrency)
    }
    
    private func getCurrentYear() -> Int! {
        let date = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        return year
    }
    
    private func getExpYearAsYYYY() -> String! {
        
        let yearStr = String(getCurrentYear())
        let p = yearStr.index(yearStr.startIndex, offsetBy: 2)
        let first2Digits = yearStr.substring(with: yearStr.startIndex..<p)
        let last2Digits = self.ExpYYUiTextField.text ?? ""
        return "\(first2Digits)\(last2Digits)"
    }
    
    private func getExpDateAsMMYYYY() -> String! {
        
        let mm = self.ExpMMUiTextField.text ?? ""
        let yyyy = getExpYearAsYYYY()
        return "\(mm)/\(yyyy)"
    }

    private func submitPaymentFields() -> BSResultCcDetails? {
        
        var result : BSResultCcDetails?
        
        let ccn = self.cardUiTextField.text ?? ""
        let cvv = self.cvvUiTextField.text ?? ""
        let exp = self.getExpDateAsMMYYYY() ?? ""
        do {
            result = try BSApiManager.submitCcDetails(bsToken: self.bsToken, ccNumber: ccn, expDate: exp, cvv: cvv)
            self.purchaseData.setCcDetails(ccDetails: result)
            
        } catch let error as BSCcDetailErrors {
            if (error == BSCcDetailErrors.invalidCcNumber) {
                ccnErrorUiLabel.text = ccnInvalidMessage
                ccnErrorUiLabel.isHidden = false
            } else if (error == BSCcDetailErrors.invalidExpDate) {
                expErrorUiLabel.text = expInvalidMessage
                expErrorUiLabel.isHidden = false
            } else if (error == BSCcDetailErrors.invalidCvv) {
                cvvErrorUiLabel.text = cvvInvalidMessage
                cvvErrorUiLabel.isHidden = false
            }
        } catch {
            NSLog("Unexpected error submitting Payment Fields to BS")
        }
        return result
    }
    
    private func gotoShippingScreen() {
        
        if (self.shippingScreen == nil) {
            if let storyboard = storyboard {
                self.shippingScreen = storyboard.instantiateViewController(withIdentifier: "ShippingDetailsScreen") as! BSShippingViewController
                if let shippingDetails = purchaseData.getShippingDetails() {
                    shippingDetails.name = self.nameUiTextyField.text ?? ""
                }
                self.shippingScreen.purchaseData = self.purchaseData
            }
        }
        self.shippingScreen.payText = self.payButtonText
        self.navigationController?.pushViewController(self.shippingScreen, animated: true)
    }
    
    // MARK: menu actions
    
    @IBAction func menuCurrecyAction(_ sender: Any) {
        
        BlueSnapSDK.showCurrencyList(
            inNavigationController: self.navigationController,
            animated: true,
            bsToken: bsToken,
            selectedCurrencyCode: purchaseData.getCurrency(),
            updateFunc: updateViewWithNewCurrency)

    }
    
    @IBAction func MenuClick(_ sender: UIBarButtonItem) {
        
        // hide/show the menu
        if (menuWidthConstraint.constant <= 0) {
            let title = "Currency - " + purchaseData.currency
            menuCurrencyButton.setTitle(title, for: UIControlState())
            menuWidthConstraint.constant = 150
        } else {
            menuWidthConstraint.constant = 0
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // if navigating to the web view - set the right URL
        if let id = segue.identifier {
            var url : String?
            if id == "webViewPrivacyPolicy" {
                url = privacyPolicyURL
            } else if id == "webViewRefundPolicy" {
                url = refundPolicyURL
            } else if id == "webViewTerms" {
                url = termsURL
            }
            if let url = url {
                let controller = segue.destination as! BSWebViewController
                controller.url = url
            }
        }
    }

    // MARK: button actions
    
    @IBAction func clickPay(_ sender: UIButton) {
        
        if (validateForm()) {
            
            if (withShipping) {
                gotoShippingScreen()
            } else {
                if let result = submitPaymentFields() {
                    // call callback
                    print("Should close window here and call the callback; result: \(result)")
                }
            }
        } else {
            //return false
        }
    }
    

    // MARK: Validation methods
    
    func validateForm() -> Bool {
        
        let ok1 = validateName(ignoreIfEmpty: false)
        let ok2 = validateCCN(ignoreIfEmpty: false)
        let ok3 = validateExpMM(ignoreIfEmpty: false)
        let ok4 = validateExpYY(ignoreIfEmpty: false)
        let ok5 = validateCvv(ignoreIfEmpty: false)
        return ok1 && ok2 && ok3 && ok4 && ok5
    }
    
    func validateCvv(ignoreIfEmpty : Bool) -> Bool {
        
        var ok : Bool = true;
        if (doValidations) {
            let newValue = cvvUiTextField.text ?? ""
            if newValue.characters.count == 0 && ignoreIfEmpty {
                // ignore
            } else if newValue.characters.count < 3 {
                ok = false
            }
        }
        if ok {
            cvvErrorUiLabel.isHidden = true
        } else {
            cvvErrorUiLabel.text = cvvInvalidMessage
            cvvErrorUiLabel.isHidden = false
        }
        return ok
    }
    
    func validateName(ignoreIfEmpty : Bool) -> Bool {
        
        var ok : Bool = true;
        if (doValidations) {
            let newValue = nameUiTextyField.text?.trimmingCharacters(in: .whitespaces) ?? ""
            nameUiTextyField.text = newValue
            if newValue.characters.count == 0 && ignoreIfEmpty {
                // ignore
            } else if !newValue.isValidName {
                ok = false
            }
        }
        if ok {
            nameErrorUiLabel.isHidden = true
        } else {
            nameErrorUiLabel.text = nameInvalidMessage
            nameErrorUiLabel.isHidden = false
        }
        return ok
    }
    
    func validateCCN(ignoreIfEmpty : Bool) -> Bool {
        
        var ok : Bool = true;
        let newValue = cardUiTextField.text ?? ""
        if (doValidations) {
            if newValue.characters.count == 0 && ignoreIfEmpty {
                // ignore
            } else if !newValue.isValidCCN {
                ok = false
            }
        }
        if ok {
            ccnErrorUiLabel.isHidden = true
            let cardType = newValue.getCCType()
            NSLog("cardType= \(cardType)")
        } else {
            ccnErrorUiLabel.text = ccnInvalidMessage
            ccnErrorUiLabel.isHidden = false
        }
        return ok
    }
    
    func validateExpMM(ignoreIfEmpty : Bool) -> Bool {
        
        var ok : Bool = true
        if (doValidations) {
            let inputMM = ExpMMUiTextField.text ?? ""
            if inputMM.characters.count == 0 && ignoreIfEmpty {
                // ignore
            } else if (inputMM.characters.count < 2) {
                ok = false
            } else if !inputMM.isValidMonth {
                ok = false
            }
        }
        if (ok) {
            expErrorUiLabel.isHidden = true
        } else {
            expErrorUiLabel.text = expInvalidMessage
            expErrorUiLabel.isHidden = false
        }
        return ok
    }
    
    func validateExpYY(ignoreIfEmpty : Bool) -> Bool {

        var ok : Bool = true
        if (doValidations) {
            let inputYY = ExpYYUiTextField.text ?? ""
            if inputYY.characters.count == 0 && ignoreIfEmpty {
                // ignore
            } else if (inputYY.characters.count < 2) {
                ok = false
            } else {
                let currentYearYY = self.getCurrentYear() % 100
                ok = currentYearYY <= Int(inputYY)!
            }
        }
        if (ok) {
            expErrorUiLabel.isHidden = true
        } else {
            expErrorUiLabel.text = expInvalidMessage
            expErrorUiLabel.isHidden = false
        }
        return ok
    }
    
    
    // MARK: real-time formatting and Validations on text fields
    
    @IBAction func nameEditingChanged(_ sender: UITextField) {
        
        var input : String = sender.text ?? ""
        input = input.removeNoneAlphaCharacters.cutToMaxLength(maxLength: 100)
        sender.text = input
    }
    
    @IBAction func ccnEditingChanged(_ sender: UITextField) {
        
        var input : String = sender.text ?? ""
        input = input.removeNoneDigits.cutToMaxLength(maxLength: 21).formatCCN
        sender.text = input
    }
    
    @IBAction func expEditingChanged(_ sender: UITextField) {
        
        var input : String = sender.text ?? ""
        input = input.removeNoneDigits.cutToMaxLength(maxLength: 2)
        sender.text = input
    }
    
    @IBAction func cvvEditingChanged(_ sender: UITextField) {
        
        var input : String = sender.text ?? ""
        input = input.removeNoneDigits.cutToMaxLength(maxLength: 4)
        sender.text = input
    }
    
    @IBAction func nameEditingDidEnd(_ sender: UITextField) {
        _ = validateName(ignoreIfEmpty: true)
    }
    
    @IBAction func cvvEditingDidEnd(_ sender: UITextField) {
        _ = validateCvv(ignoreIfEmpty: true)
    }
    
    @IBAction func expYYEditingDidEnd(_ sender: UITextField) {
        _ = validateExpYY(ignoreIfEmpty: true)
    }
    
    @IBAction func expMMEditingDidEnd(_ sender: UITextField) {
        _ = validateExpMM(ignoreIfEmpty: true)
    }

    @IBAction func cardEditingDidEnd(_ sender: UITextField) {
        _ = validateCCN(ignoreIfEmpty: true)
    }

}

