//
//  BSPaymentViewController.swift
//  BluesnapSDK
//
//  Created by Shevie Chen on 21/05/2017.
//  Copyright © 2017 Bluesnap. All rights reserved.
//

import UIKit

class BSPaymentViewController: UIViewController, UITextFieldDelegate, BSCcInputLineDelegate {

    
    // MARK: private properties
    
    fileprivate var withShipping = false
    fileprivate var shippingScreen: BSShippingViewController!
    fileprivate var cardType : String?
    fileprivate var activityIndicator : UIActivityIndicatorView?
    fileprivate var firstTime : Bool = true
    fileprivate var firstTimeShipping : Bool = true
    fileprivate var payButtonText : String?
    fileprivate var zipTopConstraintOriginalConstant : CGFloat?
    fileprivate var paymentRequest : BSCcPaymentRequest!
    fileprivate var fullBilling = false
    fileprivate var purchaseFunc: (BSBasePaymentRequest!)->Void = {
        paymentRequest in
        print("purchaseFunc should be overridden")
    }
    fileprivate var countryManager = BSCountryManager()
    
    // MARK: - Outlets
    
    @IBOutlet weak var payButton: UIButton!
    
    @IBOutlet weak var subtotalUILabel: UILabel!
    @IBOutlet weak var taxAmountUILabel: UILabel!
    @IBOutlet weak var taxDetailsView: UIView!
    
    @IBOutlet weak var ccInputLine: BSCcInputLine!
    
    @IBOutlet weak var nameInputLine: BSInputLine!
    @IBOutlet weak var emailInputLine: BSInputLine!
    @IBOutlet weak var streetInputLine: BSInputLine!
    @IBOutlet weak var zipInputLine: BSInputLine!
    @IBOutlet weak var cityInputLine: BSInputLine!
    @IBOutlet weak var stateInputLine: BSInputLine!
    
    @IBOutlet weak var shippingSameAsBillingView: UIView!
    @IBOutlet weak var shippingSameAsBillingSwitch: UISwitch!
    
    @IBOutlet weak var zipTopConstraint: NSLayoutConstraint!
    
    // MARK: init
    
    public func initScreen(paymentRequest : BSCcPaymentRequest!, fullBilling: Bool, purchaseFunc: @escaping (BSBasePaymentRequest!)->Void) {
        
        self.firstTime = true
        self.firstTimeShipping = true
        self.paymentRequest = paymentRequest
        self.fullBilling = fullBilling
        self.purchaseFunc = purchaseFunc
    }
    
    // MARK: Keyboard functions
    
    let scrollOffset : Int = -64 // this is the Y of scrollView
    var movedUp = false
    var fieldBottom : Int?
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var fieldsView: UIView!
    
    override func viewDidLayoutSubviews()
    {
        let scrollViewBounds = scrollView.bounds
        //let containerViewBounds = fieldsView.bounds
        
        var scrollViewInsets = UIEdgeInsets.zero
        scrollViewInsets.top = scrollViewBounds.size.height/2.0;
        scrollViewInsets.top -= fieldsView.bounds.size.height/2.0;
        
        scrollViewInsets.bottom = scrollViewBounds.size.height/2.0
        scrollViewInsets.bottom -= fieldsView.bounds.size.height/2.0;
        scrollViewInsets.bottom += 1
        
        scrollView.contentInset = scrollViewInsets
    }
    
    @IBAction func editingDidBegin(_ sender: BSBaseTextInput) {
        
        fieldBottom = Int(sender.frame.origin.y + sender.frame.height)
    }
    
    private func scrollForKeyboard(direction: Int) {
        
        self.movedUp = (direction > 0)
        let y = 200*direction
        let point : CGPoint = CGPoint(x: 0, y: y)
        self.scrollView.setContentOffset(point, animated: false)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        
        var moveUp = false
        if let fieldBottom = fieldBottom {
            let userInfo = notification.userInfo as! [String: NSObject] as NSDictionary
            let keyboardFrame = userInfo.value(forKey: UIKeyboardFrameEndUserInfoKey) as! CGRect
            let keyboardHeight = Int(keyboardFrame.height)
            let viewHeight : Int = Int(self.view.frame.height)
            let offset = fieldBottom + keyboardHeight - scrollOffset
            //print("fieldBottom:\(fieldBottom), keyboardHeight:\(keyboardHeight), offset:\(offset), viewHeight:\(viewHeight)")
            if (offset > viewHeight) {
                moveUp = true
            }
        }
        
        if !self.movedUp && moveUp {
            scrollForKeyboard(direction: 1)
        } else if self.movedUp && !moveUp {
            scrollForKeyboard(direction: 0)
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        
        if self.movedUp {
            scrollForKeyboard(direction: 0)
        }
    }
    
    func registerTapToHideKeyboard() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        self.view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        
        self.ccInputLine.dismissKeyboard()
        self.nameInputLine.dismissKeyboard()
        self.emailInputLine.dismissKeyboard()
        self.zipInputLine.dismissKeyboard()
        self.streetInputLine.dismissKeyboard()
        self.cityInputLine.dismissKeyboard()
    }

    // MARK: BSCcInputLineDelegate methods
    
    
    func startEditCreditCard() {
        hideShowFields()
    }
    
    func endEditCreditCard() {
        hideShowFields()
    }

    func willCheckCreditCard() {
    }
    
    func didCheckCreditCard(ccDetails: BSCcDetails, error: BSErrors?) {
        if error == nil {
            paymentRequest.ccDetails = ccDetails
            if let issuingCountry = ccDetails.ccIssuingCountry {
                self.updateWithNewCountry(countryCode: issuingCountry, countryName: "")
            }
        }
    }
    
    func didSubmitCreditCard(ccDetails: BSCcDetails, error: BSErrors?) {

        if let navigationController = self.navigationController {
            
            let viewControllers = navigationController.viewControllers
            let topController = viewControllers[viewControllers.count-1]
            let inShippingScreen = shippingScreen != nil && topController == shippingScreen
            
            if inShippingScreen {
                BSViewsManager.stopActivityIndicator(activityIndicator: shippingScreen.activityIndicator)
            } else {
                self.stopActivityIndicator()
            }
            
            if error == nil {
                paymentRequest.ccDetails = ccDetails
                // return to merchant screen
                let merchantControllerIndex = viewControllers.count - (inShippingScreen ? 4 : 3)
                _ = navigationController.popToViewController(viewControllers[merchantControllerIndex], animated: false)
                // execute callback
                self.purchaseFunc(self.paymentRequest)
            } else {
                // error
                if inShippingScreen {
                    _ = navigationController.popViewController(animated: false)
                }
            }
        }
    }
    
    
    func showAlert(_ message : String) {
        let alert = BSViewsManager.createErrorAlert(title: "Oops", message: message)
        present(alert, animated: true, completion: nil)
    }

    
    // MARK: - UIViewController's methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ccInputLine.delegate = self
        
        emailInputLine.fieldKeyboardType = .emailAddress
        activityIndicator = BSViewsManager.createActivityIndicator(view: self.view)
        if let zipTopConstraint = self.zipTopConstraint {
            zipTopConstraintOriginalConstant = zipTopConstraint.constant
        }
        
        /*NotificationCenter.default.addObserver(
            self,
            selector:  #selector(deviceDidRotate),
            name: .UIDeviceOrientationDidChange,
            object: nil
        )*/
        registerTapToHideKeyboard()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.navigationController!.isNavigationBarHidden = false
        
        self.withShipping = paymentRequest.getShippingDetails() != nil
        shippingSameAsBillingView.isHidden = !self.withShipping || !self.fullBilling
        
        // set the "shipping same as billing" to be true if no shipping name is supplied
        if self.firstTime == true {
            shippingSameAsBillingSwitch.isOn = self.paymentRequest.getShippingDetails()?.name ?? "" == ""
        }
        
        updateTexts()
        
        taxDetailsView.isHidden = self.paymentRequest.getTaxAmount() == 0
         
        if self.firstTime == true {
            self.firstTime = false
            if let billingDetails = self.paymentRequest.getBillingDetails() {
                self.nameInputLine.setValue(billingDetails.name)
                self.emailInputLine.setValue(billingDetails.email)
                self.zipInputLine.setValue(billingDetails.zip)
                if fullBilling {
                    self.streetInputLine.setValue(billingDetails.address)
                    self.cityInputLine.setValue(billingDetails.city)
                }
            }
            nameInputLine.hideError()
            emailInputLine.hideError()
            streetInputLine.hideError()
            zipInputLine.hideError()
            cityInputLine.hideError()
            stateInputLine.hideError()
            ccInputLine.reset()
        }
        hideShowFields()
    }
    
    override func viewDidAppear(_ animated: Bool) {

        super.viewDidAppear(animated)
        if ccInputLine.ccnIsOpen == true {
            self.ccInputLine.focusOnCcnField()
        }
        //adjustToPageRotate()
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        ccInputLine.closeOnLeave()
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: self.view.window)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: self.view.window)
    }


    /*private func adjustToPageRotate() {
        
        DispatchQueue.main.async{
            
            self.ccInputLine.deviceDidRotate()
            self.nameInputLine.deviceDidRotate()
            self.emailInputLine.deviceDidRotate()
            self.streetInputLine.deviceDidRotate()
            self.zipInputLine.deviceDidRotate()
            self.cityInputLine.deviceDidRotate()
            self.stateInputLine.deviceDidRotate()
            
            self.deviceDidRotate()
            
            self.viewDidLayoutSubviews()
        }
    }*/
    
    private func isShippingSameAsBilling() -> Bool {
        return !shippingSameAsBillingView.isHidden && self.shippingSameAsBillingSwitch.isOn
    }
    
    private func hideShowFields() {
        
        if self.ccInputLine.ccnIsOpen {
            // hide everything
            nameInputLine.isHidden = true
            emailInputLine.isHidden = true
            streetInputLine.isHidden = true
            cityInputLine.isHidden = true
            zipInputLine.isHidden = true
            stateInputLine.isHidden = true
            shippingSameAsBillingView.isHidden = true
            taxDetailsView.isHidden = true
        } else {
            nameInputLine.isHidden = false
            emailInputLine.isHidden = false
            let hideFields = !self.fullBilling
            streetInputLine.isHidden = hideFields
            let countryCode = self.paymentRequest.getBillingDetails().country ?? ""
            updateZipByCountry(countryCode: countryCode)
            updateFlagImage(countryCode: countryCode)
            cityInputLine.isHidden = hideFields
            updateState()
            shippingSameAsBillingView.isHidden = !self.withShipping || !self.fullBilling
            taxDetailsView.isHidden = self.paymentRequest.getAmount() == 0
            updateZipFieldLocation()
        }
    }
    
    /*func deviceDidRotate() {
    }*/

    private func updateState() {
        
        if (fullBilling) {
            BSValidator.updateState(addressDetails: paymentRequest.getBillingDetails(), countryManager: countryManager, stateInputLine: stateInputLine)
        } else {
            stateInputLine.isHidden = true
        }
    }
    
    private func updateTexts() {
        
        let toCurrency = paymentRequest.getCurrency() ?? ""
        let subtotalAmount = paymentRequest.getAmount() ?? 0.0
        let taxAmount = (paymentRequest.getTaxAmount() ?? 0.0)
        let amount = subtotalAmount + taxAmount
        let currencyCode = (toCurrency == "USD" ? "$" : toCurrency)
        payButtonText = String(format:"Pay %@ %.2f", currencyCode, CGFloat(amount))
        updatePayButtonText()
        subtotalUILabel.text = String(format:" %@ %.2f", currencyCode, CGFloat(subtotalAmount))
        taxAmountUILabel.text = String(format:" %@ %.2f", currencyCode, CGFloat(taxAmount))
    }

    private func updatePayButtonText() {
        
        if (self.withShipping && !isShippingSameAsBilling()) {
            payButton.setTitle("Shipping >", for: UIControlState())
        } else {
            payButton.setTitle(payButtonText, for: UIControlState())
        }
    }
    
    func submitPaymentFields() {
        
        self.ccInputLine.submitPaymentFields()
    }
    
    private func gotoShippingScreen() {
        
        if (self.shippingScreen == nil) {
            if let storyboard = storyboard {
                self.shippingScreen = storyboard.instantiateViewController(withIdentifier: "BSShippingDetailsScreen") as! BSShippingViewController
            }
        }
        let subTotalText = self.taxDetailsView.isHidden ? nil : subtotalUILabel.text
        let taxText = self.taxDetailsView.isHidden ? nil : taxAmountUILabel.text
        shippingScreen.initScreen(paymentRequest: paymentRequest, payText: self.payButtonText, subTotalText: subTotalText, taxText: taxText, submitPaymentFields: submitPaymentFields, countryManager: countryManager, firstTime: firstTimeShipping)
        firstTimeShipping = false
        self.navigationController?.pushViewController(self.shippingScreen, animated: true)
    }
    
    
    private func updateWithNewCountry(countryCode : String, countryName : String) {
        
        paymentRequest.getBillingDetails().country = countryCode
        updateZipByCountry(countryCode: countryCode)
        updateState()
        
        // load the flag image
        updateFlagImage(countryCode: countryCode.uppercased())
    }

    private func updateZipByCountry(countryCode : String) {
        
        let hideZip = self.countryManager.countryHasNoZip(countryCode: countryCode)
        self.zipInputLine.labelText = BSValidator.getZipLabelText(countryCode: countryCode, forBilling: true)
        self.zipInputLine.fieldKeyboardType = BSValidator.getZipKeyboardType(countryCode: countryCode)
        self.zipInputLine.isHidden = hideZip
        self.zipInputLine.hideError()
        //self.streetInputLine.fieldKeyboardType = .numbersAndPunctuation
    }
    
    private func updateWithNewState(stateCode : String, stateName : String) {
        
        paymentRequest.getBillingDetails().state = stateCode
        self.stateInputLine.setValue(stateName)
    }
    
    private func updateFlagImage(countryCode : String) {
        
        // load the flag image
        if let image = BSViewsManager.getImage(imageName: countryCode.uppercased()) {
            nameInputLine.image = image
        }
    }

    private func updateZipFieldLocation() {
        
        if !zipInputLine.isHidden {
            zipTopConstraint.constant = zipTopConstraintOriginalConstant ?? 1
        } else {
            zipTopConstraint.constant = -1 * emailInputLine.frame.height
        }
    }
    
    // MARK: menu actions
    
    private func updateCurrencyFunc(oldCurrency : BSCurrency?, newCurrency : BSCurrency?) {
        
        paymentRequest.changeCurrency(oldCurrency: oldCurrency, newCurrency: newCurrency)
    }
    
    @IBAction func MenuClick(_ sender: UIBarButtonItem) {
        
        let menu : UIAlertController = BSViewsManager.openPopupMenu(paymentRequest: paymentRequest, inNavigationController: self.navigationController!, updateCurrencyFunc: updateCurrencyFunc, errorFunc: { self.showAlert("An error occurred; please try again") })
        present(menu, animated: true, completion: nil)
    }
    
    // MARK: button actions
    
    @IBAction func shippingSameAsBillingValueChanged(_ sender: Any) {
        
        updatePayButtonText()
    }
    
    @IBAction func clickPay(_ sender: UIButton) {
        
        if (validateForm()) {
            
            if (withShipping && !isShippingSameAsBilling()) {
                gotoShippingScreen()
            } else {
                startActivityIndicator()
                submitPaymentFields()
            }
        } else {
            //return false
        }
    }

    
    // MARK: Validation methods
    
    func validateForm() -> Bool {
        
        let ok1 = validateName(ignoreIfEmpty: false)
        let ok2 = ccInputLine.validate()
        var result = ok1 && ok2
        
        if fullBilling {
            let ok1 = validateEmail(ignoreIfEmpty: false)
            let ok2 = validateCity(ignoreIfEmpty: false)
            let ok3 = validateStreet(ignoreIfEmpty: false)
            let ok4 = validateCity(ignoreIfEmpty: false)
            let ok5 = validateZip(ignoreIfEmpty: false)
            let ok6 = validateState(ignoreIfEmpty: false)
            result = result && ok1 && ok2 && ok3 && ok4 && ok5 && ok6
        } else {
            let ok1 = validateEmail(ignoreIfEmpty: true)
            let ok2 = zipInputLine.isHidden ? true : validateZip(ignoreIfEmpty: false)
            result = result && ok1 && ok2
        }
        
        if result && isShippingSameAsBilling() {
            // copy billing details to shipping
            if let shippingDetails = self.paymentRequest.getShippingDetails(), let billingDetails = self.paymentRequest.getBillingDetails() {
                shippingDetails.address = billingDetails.address
                shippingDetails.city = billingDetails.city
                shippingDetails.country = billingDetails.country
                shippingDetails.name = billingDetails.name
                shippingDetails.state = billingDetails.state
                shippingDetails.zip = billingDetails.zip
            }
        }
        
        return result
    }
    
    func validateName(ignoreIfEmpty : Bool) -> Bool {
        
        let result : Bool = BSValidator.validateName(ignoreIfEmpty: ignoreIfEmpty, input: nameInputLine, addressDetails: paymentRequest.getBillingDetails())
        return result
    }
    
    func validateEmail(ignoreIfEmpty : Bool) -> Bool {
        
        let result : Bool = BSValidator.validateEmail(ignoreIfEmpty: ignoreIfEmpty, input: emailInputLine, addressDetails: paymentRequest.getBillingDetails())
        return result
    }
    
    func validateStreet(ignoreIfEmpty : Bool) -> Bool {
        
        let result : Bool = BSValidator.validateStreet(ignoreIfEmpty: ignoreIfEmpty, input: streetInputLine, addressDetails: paymentRequest.getBillingDetails())
        return result
    }
    
    func validateCity(ignoreIfEmpty : Bool) -> Bool {
        
        let result : Bool = BSValidator.validateCity(ignoreIfEmpty: ignoreIfEmpty, input: cityInputLine, addressDetails: paymentRequest.getBillingDetails())
        return result
    }

    func validateZip(ignoreIfEmpty : Bool) -> Bool {
        
        if (zipInputLine.isHidden) {
            paymentRequest.getBillingDetails().zip = ""
            zipInputLine.setValue("")
            return true
        }
        
        // make zip optional for cards other than visa/discover
        var ignoreEmptyZip = ignoreIfEmpty
        let ccType = self.ccInputLine.getCardType().lowercased()
        if !ignoreIfEmpty && !fullBilling && ccType != "visa" && ccType != "discover" {
            ignoreEmptyZip = true
        }
        
        let result = BSValidator.validateZip(ignoreIfEmpty: ignoreEmptyZip, input: zipInputLine, addressDetails: paymentRequest.getBillingDetails())
        return result
    }
    
    func validateState(ignoreIfEmpty : Bool) -> Bool {
        
        let result : Bool = BSValidator.validateState(ignoreIfEmpty: ignoreIfEmpty, input: stateInputLine, addressDetails: paymentRequest.getBillingDetails())
        return result
    }

    
    // MARK: activity indicator methods
    
    func startActivityIndicator() {
        BSViewsManager.startActivityIndicator(activityIndicator: self.activityIndicator, blockEvents: true)
    }
    func stopActivityIndicator() {
        BSViewsManager.stopActivityIndicator(activityIndicator: self.activityIndicator)
    }

    
    // MARK: real-time formatting and Validations on text fields
    
    @IBAction func nameEditingChanged(_ sender: BSInputLine) {
        
        BSValidator.nameEditingChanged(sender)
    }
    
    @IBAction func nameEditingDidEnd(_ sender: BSInputLine) {
        _ = validateName(ignoreIfEmpty: true)
    }

    @IBAction func countryFlagClick(_ sender: BSInputLine) {
        
        // open the country screen
        let selectedCountryCode = paymentRequest.getBillingDetails().country ?? ""
        BSViewsManager.showCountryList(
            inNavigationController: self.navigationController,
            animated: true,
            countryManager: countryManager,
            selectedCountryCode: selectedCountryCode,
            updateFunc: updateWithNewCountry)
    }

    @IBAction func emailEditingChanged(_ sender: BSInputLine) {
        BSValidator.emailEditingChanged(sender)
    }
    
    @IBAction func emailEditingDidEnd(_ sender: BSInputLine) {
        _ = validateEmail(ignoreIfEmpty: true)
    }
    
    @IBAction func streetEditingChanged(_ sender: BSInputLine) {
        BSValidator.addressEditingChanged(sender)
    }
    
    @IBAction func streetEditingDidEnd(_ sender: BSInputLine) {
        _ = validateStreet(ignoreIfEmpty: true)
    }
    
    @IBAction func streetEditingDidBegin(_ sender: BSInputLine) {
        
        editingDidBegin(sender)
        if streetInputLine.getValue() == "" {
            streetInputLine.fieldKeyboardType = .numbersAndPunctuation
        } else {
            streetInputLine.fieldKeyboardType = .default
        }
    }
    
    @IBAction func cityEditingChanged(_ sender: BSInputLine) {
        BSValidator.cityEditingChanged(sender)
    }
    
    @IBAction func cityEditingDidEnd(_ sender: BSInputLine) {
        _ = validateCity(ignoreIfEmpty: true)
    }
    
    @IBAction func zipEditingChanged(_ sender: BSInputLine) {
        BSValidator.zipEditingChanged(sender)
    }
    
    @IBAction func zipEditingDidEnd(_ sender: BSInputLine) {
        _ = validateZip(ignoreIfEmpty: true)
    }
    
    @IBAction func stateClick(_ sender: BSInputLine) {
        
        // open the state screen
        BSViewsManager.showStateList(
            inNavigationController: self.navigationController,
            animated: true,
            countryManager: countryManager,
            addressDetails: paymentRequest.getBillingDetails(),
            updateFunc: updateWithNewState)
    }

    // MARK: Prevent rotation, support only Portrait mode
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return UIInterfaceOrientation.portrait
    }

}
