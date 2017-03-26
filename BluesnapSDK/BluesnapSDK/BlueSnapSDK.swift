//
//  BlueSnap.swift
//  BlueSnap
//
//

import Foundation

@objc open class BlueSnapSDK: NSObject {
	
	// MARK: - Constants
	
	fileprivate static let bundleIdentifier = "com.bluesnap.BluesnapSDK"
	fileprivate static let storyboardName = "BlueSnap"
	fileprivate static let currencyListStoryboardId = "CurrencyListStoryboardId"
	fileprivate static let summaryScreenStoryboardId = "SummaryScreenStoryboardId"
	
	// MARK: - UI Controllers
	
	fileprivate static var currencyList: RatesCurrencyList!
	fileprivate static var summaryScreen: BSSummaryScreen!

	// MARK: - Show drop-down list with currencies
	
	open class func showCurrencyList(_ sender: UIButton, inViewController: UIViewController, animated: Bool) {

		if currencyList == nil {
			let storyboard = UIStoryboard(name: storyboardName, bundle: Bundle(identifier: bundleIdentifier))
			currencyList = storyboard.instantiateViewController(withIdentifier: currencyListStoryboardId) as! RatesCurrencyList
		}
		
		currencyList.sender = sender
		currencyList.modalPresentationStyle = .popover
		currencyList.presentationController?.delegate = inViewController as! UIPopoverPresentationControllerDelegate
		currencyList.popoverPresentationController?.sourceRect = sender.convert(sender.bounds, to: inViewController.view)
		currencyList.popoverPresentationController?.sourceView = inViewController.view
		inViewController.present(currencyList, animated: true, completion: nil)
	}
	
	// MARK: - Show summary screen
	
	open class func showSummaryScreen(_ rawValue: CGFloat, toCurrency: String, inNavigationController: UINavigationController!, animated: Bool) {
		
		if summaryScreen == nil {
			let storyboard = UIStoryboard(name: storyboardName, bundle: Bundle(identifier: bundleIdentifier))
			summaryScreen = storyboard.instantiateViewController(withIdentifier: summaryScreenStoryboardId) as! BSSummaryScreen
		}
		
		summaryScreen.rawValue = rawValue
		summaryScreen.toCurrency = toCurrency
		
		inNavigationController.pushViewController(summaryScreen, animated: true)
	}
}
