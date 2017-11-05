//
//  BSExistingCcUIView.swift
//  BluesnapSDK
//
//  Created by Shevie Chen on 02/11/2017.
//  Copyright © 2017 Bluesnap. All rights reserved.
//

import Foundation

class BSExistingCcUIView: BSBaseBoxWithShadowView {
    
    // MARK: public properties
    
    var ccType: String = "visa"
    var last4Digits: String = "4567"
    var expiration: String = "11/25"
    
    // MARK: private properties
    
    var imageView : UIImageView = UIImageView()
    var last4DigitsLabel : UILabel = UILabel()
    var expirationLabel : UILabel = UILabel()
    var coverButton : UIButton = UIButton()
    
    // MARK: public functions
    
    public func setCc(ccType: String, last4Digits: String, expiration: String) {
        self.ccType = ccType
        self.last4Digits = last4Digits
        self.expiration = expiration
        setElementAttributes()
    }
    
    /**
     Set the width/height/font-size of the view content; this code may be called many times.
     */
    internal func resizeElements() {
        
        let marginX : CGFloat = 30
        let marginY : CGFloat = 5
        
        let imageWidth : CGFloat = 35
        let imageHeight : CGFloat = 21
        
        let actualHeight : CGFloat = self.frame.height - marginY * 2.0
        let ratioY = actualHeight / imageHeight
        let actualImageWidth : CGFloat = imageWidth * ratioY
        let actualLableWidth = (self.frame.width - 4 * marginX) / 3
        
        imageView.frame = CGRect(x: marginX, y: marginY, width: actualImageWidth, height: actualHeight)
        
        let last4DigitsX = 2 * marginX + actualImageWidth
        last4DigitsLabel.frame = CGRect(x: last4DigitsX, y: marginY, width: actualLableWidth, height: actualHeight)
        
        let expirationLabelX = self.frame.width - marginX - actualLableWidth
        expirationLabel.frame = CGRect(x: expirationLabelX, y: marginY, width: actualLableWidth, height: actualHeight)
        
        coverButton.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
    }
    
    // MARK: UIView override functions
    
    // called at design time (StoryBoard) to init the component
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        //designMode = true
        buildElements()
    }
    
    // called at runtime to init the component
    required public init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        //designMode = false
        buildElements()
    }
    
    override public func draw(_ rect: CGRect) {
        
        super.draw(rect)
        resizeElements()
    }
    
    override public func prepareForInterfaceBuilder() {
        
        super.prepareForInterfaceBuilder()
        setElementAttributes()
        resizeElements()
    }
    
    override public func updateConstraints() {
        
        if (shouldSetupConstraints) {
            // AutoLayout constraints
            shouldSetupConstraints = false
        }
        super.updateConstraints()
    }
    
    // MARK: Internal/private functions
    
    /**
     Create the UI elements for the component
     This code needs to run only once (as opposed to sizes that may change).
     */
    internal func buildElements() {
        
        self.addSubview(self.imageView)
        self.addSubview(self.last4DigitsLabel)
        self.addSubview(self.expirationLabel)
        self.addSubview(self.coverButton)
        //self.backgroundColor = UIColor(red: 248/255, green: 248/255, blue: 248/255, alpha: 1)
        
        setElementAttributes()
        
        coverButton.addTarget(self, action: #selector(BSExistingCcUIView.coverButtonTouchUpInside(_:)), for: .touchUpInside)
    }
    
    
    /**
     set the attributes that are not affected by resizing
     */
    internal func setElementAttributes() {
        
        if let image = BSImageLibrary.getCcIconByCardType(ccType: ccType) {
            self.imageView.image = image
        } else {
            self.imageView.image = nil
        }
        last4DigitsLabel.text = last4Digits
        expirationLabel.text = expiration
    }
    
    func coverButtonTouchUpInside(_ sender: Any) {
        
        sendActions(for: UIControlEvents.touchUpInside)
    }
}
