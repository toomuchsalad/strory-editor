//
//  PreviewVC+TextEdit.swift
//  photo-editor
//
//  Created by Andrey Atroshchenko on 27.07.2022.
//

import Foundation
import UIKit

extension PreviewVC {
    
    func addNewTextView() {
        let textView = AdvancedTextView(frame: CGRect(x: self.previewView.frame.width/2 - 30, y: 50, width: 50, height: 50))
        
        textView.id = UUID().uuidString
        //Text Attributes
        
        textView.textAlignment = .center
        textView.font = UIFont(name: "SF Pro Text Bold", size: 38) ?? UIFont.systemFont(ofSize: 38, weight: .bold)
        textView.textColor = .white
        textView.layer.shadowColor = UIColor.black.cgColor
        textView.layer.shadowOffset = CGSize(width: 1.0, height: 0.0)
        textView.layer.shadowOpacity = 0.2
        textView.layer.shadowRadius = 1.0
        textView.layer.backgroundColor = UIColor.clear.cgColor
        textView.keyboardAppearance = .dark
        textView.layer.cornerRadius = textView.bounds.height/4
        textView.backgroundColor = UIColor(hexString: "040404")
        //
        textView.adjustsFontForContentSizeCategory = true
        textView.autocorrectionType = .no
        textView.delegate = self
        self.previewView.addSubview(textView)
        addGestures(view: textView)
        
        textView.becomeFirstResponder()
        NewMediaManager.shared.newMedia[mediaIndex].textViews.append(textView)
        
        self.activeTextView = textView
    }
    
    func addGestures(view: UIView) {
        //Gestures
        view.isUserInteractionEnabled = true
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.panGesture))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        
        
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotationGesture(_:)))
        rotationGesture.delegate = self
        view.addGestureRecognizer(rotationGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        pinchGesture.delegate = self
        view.addGestureRecognizer(pinchGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapGesture))
        view.addGestureRecognizer(tapGesture)
        
    }
}

extension PreviewVC: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        if textEditMode {
            
            guard let advancedTextView = textView as? AdvancedTextView, let existTextView = NewMediaManager.shared.newMedia[mediaIndex].textViews.filter({$0.id == advancedTextView.id}).first else {
                return
            }
            
            switch existTextView.type {
            case .link:
                existTextView.type = .text
                existTextView.text = ""
                existTextView.font = UIFont.systemFont(ofSize: 38, weight: .medium)
                existTextView.textColor = .white
                existTextView.backgroundColor = .black
            case .mention:
                if existTextView.text == "" {
                    existTextView.text = "@"
                }
            default:
                break
            }
            
            
            if textView.text.count > 0 {
                let keyboardHeight = UserDefaults.standard.value(forKey: "keyboardHeight") as? CGFloat ?? 400
                let newSize = textView.sizeThatFits(CGSize(width: self.previewView.frame.width - 32, height: self.previewView.frame.height - keyboardHeight))
                let newWidth = min(newSize.width, self.previewView.frame.width - 32)
                let newHeight = min(newSize.height, self.previewView.frame.height - keyboardHeight)
                textView.frame = CGRect(x: self.previewView.frame.width/2 - newWidth/2, y: 42, width: newWidth, height: newHeight)
            } else {
                textView.frame =  CGRect(x: self.previewView.frame.width/2 - 30, y: 50, width: 50, height: 50)
            }
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        print(#function)
        
        guard let advancedTextView = textView as? AdvancedTextView, let existTextView = NewMediaManager.shared.newMedia[mediaIndex].textViews.filter({$0.id == advancedTextView.id}).first else {
            return
        }
        
        self.activeTextView = existTextView
        
        if !textEditMode {
            textEditMode = true
        }
        
        print("isScrollEnabled = true")
        existTextView.isScrollEnabled = true
        textView.isScrollEnabled = true
        existTextView.lastTextViewTransform = textView.transform
        existTextView.lastTextViewTransCenter = textView.center
        existTextView.lastSize = textView.frame.size
        textView.superview?.bringSubviewToFront(textView)
        
        UIView.animate(withDuration: 0.3, animations: {
            textView.transform = CGAffineTransform.identity
            let keyboardHeight = UserDefaults.standard.value(forKey: "keyboardHeight") as? CGFloat ?? 400
            let newSize = textView.sizeThatFits(CGSize(width: self.previewView.frame.width - 32, height: self.previewView.frame.height - keyboardHeight))
            let newWidth = min(newSize.width, self.previewView.frame.width - 32)
            let newHeight = min(newSize.height, self.previewView.frame.height - keyboardHeight)
            if textView.text.count > 0 {
                textView.frame = CGRect(x: self.previewView.frame.width/2 - newWidth/2, y: 42, width: newWidth, height: newHeight)
            } else {
                textView.frame =  CGRect(x: self.previewView.frame.width/2 - 30, y: 50, width: 50, height: 50)
            }
            
        })
        
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
        print(#function)
        
        self.activeTextView = nil
        
        guard let advancedTextView = textView as? AdvancedTextView, let existTextView = NewMediaManager.shared.newMedia[mediaIndex].textViews.filter({$0.id == advancedTextView.id}).first else {
            return
        }
        
        print("isScrollEnabled = false")
        existTextView.isScrollEnabled = false
        textView.isScrollEnabled = false
        
        UIView.animate(withDuration: 0.3, animations: {
            
            let newSize = textView.sizeThatFits(CGSize(width: self.previewView.frame.width - 32, height: CGFloat.greatestFiniteMagnitude))
            let newWidth = min(newSize.width, self.previewView.frame.width - 32)
            if textView.text.count > 0 {
                textView.frame = CGRect(x: self.previewView.frame.width/2 - newWidth/2, y: 42, width: newWidth, height: newSize.height)
            } else {
                textView.frame =  CGRect(x: self.previewView.frame.width/2 - 30, y: 50, width: 50, height: 50)
            }
            
            if let lastTextViewTransform = existTextView.lastTextViewTransform, let lastTextViewTransCenter = existTextView.lastTextViewTransCenter {
                textView.transform = lastTextViewTransform
                textView.center = lastTextViewTransCenter
                
            }
        }, completion: { _ in
            textView.setNeedsDisplay()
        })
    }
    
}
