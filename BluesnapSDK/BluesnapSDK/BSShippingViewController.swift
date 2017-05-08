//
//  ShippingViewController.swift
//  BluesnapSDK
//
//  Created by Shevie Chen on 03/04/2017.
//  Copyright © 2017 Bluesnap. All rights reserved.
//

import UIKit

class BSShippingViewController: UIViewController {
    
    // MARK: shipping data as input and output
    //internal var storyboard : UIStoryboard?

    internal var paymentDetails : BSPaymentDetails!
    internal var payText : String!
    internal var submitPaymentFields : () -> BSResultCcDetails? = { return nil }
    
    // MARK: outlets
    
    @IBOutlet weak var nameUITextField: UITextField!
    @IBOutlet weak var emailUITextField: UITextField!
    @IBOutlet weak var addressUITextField: UITextField!
    @IBOutlet weak var cityUITextField: UITextField!
    @IBOutlet weak var zipUITextField: UITextField!
    @IBOutlet weak var stateUITextField: UITextField!
    @IBOutlet weak var stateUILabel: UILabel!
    @IBOutlet weak var countryFlagButton: UIButton!
    
    
    @IBOutlet weak var nameErrorUILabel: UILabel!
    @IBOutlet weak var emailErrorUILabel: UILabel!
    @IBOutlet weak var addressErrorUILabel: UILabel!
    @IBOutlet weak var cityErrorUILabel: UILabel!
    @IBOutlet weak var zipErrorUILabel: UILabel!
    @IBOutlet weak var stateErrorUILabel: UILabel!
    
    @IBOutlet weak var payUIButton: UIButton!
    
    // MARK: private properties
    var countryManager = BSCountryManager()
    
    // MARK: - UIViewController's methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let shippingDetails = self.paymentDetails.getShippingDetails() {
            nameUITextField.text = shippingDetails.name
            emailUITextField.text = shippingDetails.email
            addressUITextField.text = shippingDetails.address
            cityUITextField.text = shippingDetails.city
            zipUITextField.text = shippingDetails.zip
            if (shippingDetails.country == "") {
                shippingDetails.country = Locale.current.regionCode ?? ""
            }
            //let countryName = countryManager.getCountryName(countryCode: shippingDetails.country!) ?? ""
            updateState()
            payUIButton.setTitle(payText, for: UIControlState())
        }
    }
    
    @IBAction func SubmitClick(_ sender: Any) {
        
        if (validateForm()) {
            
            _ = navigationController?.popViewController(animated: true)
            _ = submitPaymentFields()
            
        } else {
            //return false
        }
    }
    
    
    // MARK: Validation methods
    
    func validateForm() -> Bool {
        
        let ok1 = validateName(ignoreIfEmpty: false)
        let ok2 = validateEmail(ignoreIfEmpty: false)
        let ok3 = validateAddress(ignoreIfEmpty: false)
        let ok4 = validateCity(ignoreIfEmpty: false)
        let ok5 = validateCountryAndZip(ignoreIfEmpty: false)
        let ok6 = validateState(ignoreIfEmpty: false)
        return ok1 && ok2 && ok3 && ok4 && ok5 && ok6
    }
    
    func validateName(ignoreIfEmpty : Bool) -> Bool {
        
        let newValue = nameUITextField.text ?? ""
        if let shippingDetails = self.paymentDetails.getShippingDetails() {
            shippingDetails.name = newValue
        }
        var result : Bool = true
        if (ignoreIfEmpty && newValue.characters.count == 0) {
            // ignore
        } else if (newValue.characters.count < 4) {
            nameErrorUILabel.text = "Please fill Card holder name"
            nameErrorUILabel.isHidden = false
            result = false
        } else {
            nameErrorUILabel.isHidden = true
            result = true
        }
        return result
    }

    func validateEmail(ignoreIfEmpty : Bool) -> Bool {
        
        let newValue = emailUITextField.text ?? ""
        if let shippingDetails = self.paymentDetails.getShippingDetails() {
            shippingDetails.email = newValue
        }
        var result : Bool = true
        if (ignoreIfEmpty && newValue.characters.count == 0) {
            // ignore
        } else if (!newValue.isValidEmail) {
            emailErrorUILabel.text = "Please fill a valid email address"
            emailErrorUILabel.isHidden = false
            result = false
        } else {
            emailErrorUILabel.isHidden = true
            result = true
        }
        return result
    }
    
    func validateAddress(ignoreIfEmpty : Bool) -> Bool {
        
        let newValue = addressUITextField.text ?? ""
        if let shippingDetails = self.paymentDetails.getShippingDetails() {
            shippingDetails.address = newValue
        }
        var result : Bool = true
        if (ignoreIfEmpty && newValue.characters.count == 0) {
            // ignore
        } else if (newValue.characters.count < 3) {
            addressErrorUILabel.text = "Please fill a valid address"
            addressErrorUILabel.isHidden = false
            result = false
        } else {
            addressErrorUILabel.isHidden = true
            result = true
        }
        return result
    }
    
    func validateCity(ignoreIfEmpty : Bool) -> Bool {
        
        let newValue = cityUITextField.text ?? ""
        if let shippingDetails = self.paymentDetails.getShippingDetails() {
            shippingDetails.city = newValue
        }
        var result : Bool = true
        if (ignoreIfEmpty && newValue.characters.count == 0) {
            // ignore
        } else if (newValue.characters.count < 3) {
            cityErrorUILabel.text = "Please fill a valid city"
            cityErrorUILabel.isHidden = false
            result = false
        } else {
            cityErrorUILabel.isHidden = true
            result = true
        }
        return result
    }
    
    func validateCountryAndZip(ignoreIfEmpty : Bool) -> Bool {
        
        var result : Bool = true
        if validateCountryByZip(ignoreIfEmpty: ignoreIfEmpty) {
        
            let newValue : String = zipUITextField.text ?? ""
            if let shippingDetails = self.paymentDetails.getShippingDetails() {
                shippingDetails.zip = newValue
            }
            if (ignoreIfEmpty && newValue.characters.count == 0) {
                // ignore
            } else if (newValue.characters.count < 3) {
                zipErrorUILabel.text = "Please fill a valid zip code"
                zipErrorUILabel.isHidden = false
                result = false
            } else {
                zipErrorUILabel.isHidden = true
                result = true
            }
        } else {
            result = false
        }
        return result
    }
    
    func validateCountryByZip(ignoreIfEmpty : Bool) -> Bool {
        
        let newValue = self.paymentDetails.getShippingDetails()?.country ?? ""
        var result : Bool = true
        if (ignoreIfEmpty && newValue.characters.count == 0) {
            // ignore
        } else if (newValue.characters.count < 2) {
            zipErrorUILabel.text = "Please choosen a country"
            zipErrorUILabel.isHidden = false
            result = false
        } else {
            zipErrorUILabel.isHidden = true
            result = true
        }
        return result
    }
    
    func validateState(ignoreIfEmpty : Bool) -> Bool {
        
        let newValue = stateUITextField.isHidden ? "" : stateUITextField.text ?? ""
        if let shippingDetails = self.paymentDetails.getShippingDetails() {
            shippingDetails.state = newValue
        }
        var result : Bool = true
        if ((ignoreIfEmpty || stateUITextField.isHidden) && newValue.characters.count == 0) {
            // ignore
        } else if (newValue.characters.count < 2) {
            stateErrorUILabel.text = "Please fill a valid state"
            stateErrorUILabel.isHidden = false
            result = false
        } else {
            stateErrorUILabel.isHidden = true
            result = true
        }
        return result
    }

    
    // MARK: real-time formatting and Validations on text fields
    
    @IBAction func nameEditingChanged(_ sender: UITextField) {
        
        var input : String = sender.text ?? ""
        input = input.removeNoneAlphaCharacters.cutToMaxLength(maxLength: 100)
        sender.text = input
    }
    
    @IBAction func emailEditingChanged(_ sender: UITextField) {
        
        var input : String = sender.text ?? ""
        input = input.removeNoneEmailCharacters.cutToMaxLength(maxLength: 1200)
        sender.text = input
    }
    
    @IBAction func addressEditingChanged(_ sender: UITextField) {
        
        var input : String = sender.text ?? ""
        input = input.cutToMaxLength(maxLength: 100)
        sender.text = input
    }
    
    @IBAction func cityEditingChanged(_ sender: UITextField) {
        
        var input : String = sender.text ?? ""
        input = input.removeNoneAlphaCharacters.cutToMaxLength(maxLength: 50)
        sender.text = input
    }
    
    @IBAction func zipEditingChanged(_ sender: UITextField) {
        
        var input : String = sender.text ?? ""
        input = input.cutToMaxLength(maxLength: 20)
        sender.text = input
    }
    
    @IBAction func countryEditingChanged(_ sender: UITextField) {
        
        var input : String = sender.text ?? ""
        input = input.removeNoneAlphaCharacters.cutToMaxLength(maxLength: 2)
        sender.text = input
    }
    
    @IBAction func stateEditingChanged(_ sender: UITextField) {
        
        sender.text = "" // prevent typing - open pop-up insdtead
        self.statetouchDown(sender)
    }
    
    @IBAction func nameEditingDidEnd(_ sender: UITextField) {
        _ = validateName(ignoreIfEmpty: true)
    }
    
    @IBAction func emailEditingDidEnd(_ sender: UITextField) {
        _ = validateEmail(ignoreIfEmpty: true)
    }
    
    @IBAction func addressEditingDidEnd(_ sender: UITextField) {
        _ = validateAddress(ignoreIfEmpty: true)
    }
    
    @IBAction func cityEditingDidEnd(_ sender: UITextField) {
        _ = validateCity(ignoreIfEmpty: true)
    }
    
    @IBAction func zipEditingDidEnd(_ sender: UITextField) {
        _ = validateCountryAndZip(ignoreIfEmpty: true)
    }
    
    
    // enter country field - open the country screen
    @IBAction func changeCountry(_ sender: Any) {
        
        let selectedCountryCode = paymentDetails.getShippingDetails()?.country ?? ""
        BSViewsManager.showCountryList(
            inNavigationController: self.navigationController,
            animated: true,
            countryManager: countryManager,
            selectedCountryCode: selectedCountryCode,
            updateFunc: updateWithNewCountry)
    }
    
    // enter state field - open the state screen
    @IBAction func statetouchDown(_ sender: Any) {
        
        self.stateUITextField.resignFirstResponder()

        let selectedCountryCode = paymentDetails.getShippingDetails()?.country ?? ""
        let selectedStateCode = paymentDetails.getShippingDetails()?.state ?? ""
        BSViewsManager.showStateList(
            inNavigationController: self.navigationController,
            animated: true,
            countryManager: countryManager,
            selectedCountryCode: selectedCountryCode,
            selectedStateCode: selectedStateCode,
            updateFunc: updateWithNewState)
    }
    

    // MARK: private functions
    
    private func updateWithNewCountry(countryCode : String, countryName : String) {
        
        if let shippingDetails = paymentDetails.getShippingDetails() {
            shippingDetails.country = countryCode
        }
        // load the flag image
        if let image = BSViewsManager.getImage(imageName: countryCode.uppercased()) {
            self.countryFlagButton.imageView?.image = image
        }
    }
    
    private func updateState() {
        let selectedCountryCode = paymentDetails.getShippingDetails()?.country ?? ""
        let selectedStateCode = paymentDetails.getShippingDetails()?.state ?? ""
        var hideState : Bool = true
        if let states = countryManager.countryStates(countryCode: selectedCountryCode){
            stateUITextField.text = states[selectedStateCode]
            hideState = false
        }
        stateUITextField.isHidden = hideState
        stateUILabel.isHidden = hideState
        stateErrorUILabel.isHidden = true
    }
    
    private func updateWithNewState(stateCode : String, stateName : String) {
        
        if let shippingDetails = paymentDetails.getShippingDetails() {
            shippingDetails.state = stateCode
        }
        self.stateUITextField.text = stateName
    }

}
