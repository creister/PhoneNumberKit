//
//  PhoneNumberInTextFieldFormatting.swift
//  PhoneNumberKit
//
//  Created by creisterer on 3/15/18.
//  Copyright © 2018 Roy Marmelstein. All rights reserved.
//

import Foundation
import UIKit

public struct PhoneNumberInTextFieldFormatting {

    public static func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String, using partialFormatter: PartialFormatter) -> Bool {

        // This allows for the case when a user autocompletes a phone number:
        if range == NSRange(location: 0, length: 0) && string == " " {
            return true
        }

        guard let text = textField.text else {
            return false
        }

        let textAsNSString = text as NSString
        let changedRange = textAsNSString.substring(with: range) as NSString
        let modifiedTextField = textAsNSString.replacingCharacters(in: range, with: string)

        let filteredCharacters = modifiedTextField.filter {
            return  String($0).rangeOfCharacter(from: nonNumericSet as CharacterSet) == nil
        }
        let rawNumberString = String(filteredCharacters)

        let formattedNationalNumber = partialFormatter.formatPartial(rawNumberString as String)
        var selectedTextRange: NSRange?

        let nonNumericRange = (changedRange.rangeOfCharacter(from: nonNumericSet as CharacterSet).location != NSNotFound)
        if (range.length == 1 && string.isEmpty && nonNumericRange)
        {
            selectedTextRange = selectionRangeForNumberReplacement(textField: textField, formattedText: modifiedTextField)
            textField.text = modifiedTextField
        }
        else {
            selectedTextRange = selectionRangeForNumberReplacement(textField: textField, formattedText: formattedNationalNumber)
            textField.text = formattedNationalNumber
        }
        textField.sendActions(for: .editingChanged)
        if let selectedTextRange = selectedTextRange, let selectionRangePosition = textField.position(from: textField.beginningOfDocument, offset: selectedTextRange.location) {
            let selectionRange = textField.textRange(from: selectionRangePosition, to: selectionRangePosition)
            textField.selectedTextRange = selectionRange
        }

        return false
    }

    private static let nonNumericSet: NSCharacterSet = {
        var mutableSet = NSMutableCharacterSet.decimalDigit().inverted
        mutableSet.remove(charactersIn: PhoneNumberConstants.plusChars)
        return mutableSet as NSCharacterSet
    }()

    private struct CursorPosition {
        let numberAfterCursor: String
        let repetitionCountFromEnd: Int
    }

    private static func extractCursorPosition(from textField: UITextField) -> CursorPosition? {
        var repetitionCountFromEnd = 0
        // Check that there is text in the UITextField
        guard let text = textField.text, let selectedTextRange = textField.selectedTextRange else {
            return nil
        }
        let textAsNSString = text as NSString
        let cursorEnd = textField.offset(from: textField.beginningOfDocument, to: selectedTextRange.end)
        // Look for the next valid number after the cursor, when found return a CursorPosition struct
        for i in cursorEnd ..< textAsNSString.length  {
            let cursorRange = NSMakeRange(i, 1)
            let candidateNumberAfterCursor: NSString = textAsNSString.substring(with: cursorRange) as NSString
            if (candidateNumberAfterCursor.rangeOfCharacter(from: nonNumericSet as CharacterSet).location == NSNotFound) {
                for j in cursorRange.location ..< textAsNSString.length  {
                    let candidateCharacter = textAsNSString.substring(with: NSMakeRange(j, 1))
                    if candidateCharacter == candidateNumberAfterCursor as String {
                        repetitionCountFromEnd += 1
                    }
                }
                return CursorPosition(numberAfterCursor: candidateNumberAfterCursor as String, repetitionCountFromEnd: repetitionCountFromEnd)
            }
        }
        return nil
    }

    // Finds position of previous cursor in new formatted text
    private static func selectionRangeForNumberReplacement(textField: UITextField, formattedText: String) -> NSRange? {
        let textAsNSString = formattedText as NSString
        var countFromEnd = 0
        guard let cursorPosition = extractCursorPosition(from: textField) else {
            return nil
        }

        for i in stride(from: (textAsNSString.length - 1), through: 0, by: -1) {
            let candidateRange = NSMakeRange(i, 1)
            let candidateCharacter = textAsNSString.substring(with: candidateRange)
            if candidateCharacter == cursorPosition.numberAfterCursor {
                countFromEnd += 1
                if countFromEnd == cursorPosition.repetitionCountFromEnd {
                    return candidateRange
                }
            }
        }

        return nil
    }

}
