//
//  TextField.swift
//  PhoneNumberKit
//
//  Created by Roy Marmelstein on 07/11/2015.
//  Copyright © 2015 Roy Marmelstein. All rights reserved.
//

import Foundation
import UIKit

/// Custom text field that formats phone numbers

open class PhoneNumberTextField: UITextField, UITextFieldDelegate {
    
    let phoneNumberKit = PhoneNumberKit()
    
    /// Override setText so number will be automatically formatted when setting text by code
    override open var text: String? {
        set {
            if newValue != nil {
                let formattedNumber = partialFormatter.formatPartial(newValue! as String)
                super.text = formattedNumber
            }
            else {
                super.text = newValue
            }
        }
        get {
            return super.text
        }
    }
    
    /// allows text to be set without formatting
    open func setTextUnformatted(newValue:String?) {
        super.text = newValue
    }
    
    /// Override region to set a custom region. Automatically uses the default region code.
    public var defaultRegion = PhoneNumberKit.defaultRegionCode() {
        didSet {
            partialFormatter.defaultRegion = defaultRegion
        }
    }
    
    public var withPrefix: Bool = true {
        didSet {
            partialFormatter.withPrefix = withPrefix
            if withPrefix == false {
                self.keyboardType = UIKeyboardType.numberPad
            }
            else {
                self.keyboardType = UIKeyboardType.phonePad
            }
        }
    }
    public var isPartialFormatterEnabled = true
    
    public var maxDigits: Int? {
        didSet {
            partialFormatter.maxDigits = maxDigits
        }
    }
    
    let partialFormatter: PartialFormatter

    weak private var _delegate: UITextFieldDelegate?
    
    override open var delegate: UITextFieldDelegate? {
        get {
            return _delegate
        }
        set {
            self._delegate = newValue
        }
    }
    
    //MARK: Status
    
    public var currentRegion: String {
        get {
            return partialFormatter.currentRegion
        }
    }
    
    public var nationalNumber: String {
        get {
            let rawNumber = self.text ?? String()
            return partialFormatter.nationalNumber(from: rawNumber)
        }
    }
    
    public var isValidNumber: Bool {
        get {
            let rawNumber = self.text ?? String()
            do {
                let _ = try phoneNumberKit.parse(rawNumber, withRegion: currentRegion)
                return true
            } catch {
                return false
            }
        }
    }
    
    //MARK: Lifecycle
    
    /**
     Init with frame
     
     - parameter frame: UITextfield F
     
     - returns: UITextfield
     */
    override public init(frame:CGRect)
    {
        self.partialFormatter = PartialFormatter(phoneNumberKit: phoneNumberKit, defaultRegion: defaultRegion, withPrefix: withPrefix)
        super.init(frame:frame)
        self.setup()
    }
    
    /**
     Init with coder
     
     - parameter aDecoder: decoder
     
     - returns: UITextfield
     */
    required public init(coder aDecoder: NSCoder) {
        self.partialFormatter = PartialFormatter(phoneNumberKit: phoneNumberKit, defaultRegion: defaultRegion, withPrefix: withPrefix)
        super.init(coder: aDecoder)!
        self.setup()
    }
    
    func setup(){
        self.autocorrectionType = .no
        self.keyboardType = UIKeyboardType.phonePad
        super.delegate = self
    }
    
    
    // MARK: Phone number formatting
    
    /**
     *  To keep the cursor position, we find the character immediately after the cursor and count the number of times it repeats in the remaining string as this will remain constant in every kind of editing.
     */

    open func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        // allow delegate to intervene
        guard _delegate?.textField?(textField, shouldChangeCharactersIn: range, replacementString: string) ?? true else {
            return false
        }

        guard isPartialFormatterEnabled else {
            return true
        }

        return PhoneNumberInTextFieldFormatting.textField(textField, shouldChangeCharactersIn: range, replacementString: string, using: partialFormatter)
    }
    
    //MARK: UITextfield Delegate
    
    open func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return _delegate?.textFieldShouldBeginEditing?(textField) ?? true
    }
    
    open func textFieldDidBeginEditing(_ textField: UITextField) {
        _delegate?.textFieldDidBeginEditing?(textField)
    }
    
    open func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return _delegate?.textFieldShouldEndEditing?(textField) ?? true
    }
    
    open func textFieldDidEndEditing(_ textField: UITextField) {
        _delegate?.textFieldDidEndEditing?(textField)
    }
    
    open func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return _delegate?.textFieldShouldClear?(textField) ?? true
    }
    
    open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return _delegate?.textFieldShouldReturn?(textField) ?? true
    }
}
