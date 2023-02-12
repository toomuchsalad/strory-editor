//
//  PreviewVC+ToolBar.swift
//  photo-editor
//
//  Created by Andrey Atroshchenko on 27.07.2022.
//

import Foundation
import UIKit

extension PreviewVC {
    
    @objc func keyboardWillShow(notification: NSNotification) {
        
        var exist = false
        for child in self.children {
            if child is ToolBarVC {
                exist = true
            }
        }
        if !exist {
            
            guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue, let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
                return
            }
            
            UserDefaults.standard.setValue(keyboardSize.height, forKey: "keyboardHeight")
            UserDefaults.standard.synchronize()
            
            guard let toolbarVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ToolBarVC") as? ToolBarVC,
                    let alphaSliderVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AlphaSliderVC") as? AlphaSliderVC,
                    let fontSliderVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FontSliderVC") as? FontSliderVC else {
                return
                
            }
            
            toolbarVC.delegate = self
            
            addChild(alphaSliderVC)
            addChild(toolbarVC)
            addChild(fontSliderVC)
            
            UIView.performWithoutAnimation {
                toolbarVC.toolBarType = self.toolBarType
                
                toolbarVC.view.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - keyboardSize.height - 100, width: UIScreen.main.bounds.width, height: 100)
                view.addSubview(toolbarVC.view)
                
                toolbarVC.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
                toolbarVC.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
                toolbarVC.view.heightAnchor.constraint(equalToConstant: 100).isActive = true
                toolbarVC.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
                
                toolbarVC.view.transform = CGAffineTransform(translationX: 0, y: keyboardSize.height+100)
                
                if let activeTextView = self.activeTextView {
                    alphaSliderVC.previousValue = activeTextView.textAlpha
                }
                
                alphaSliderVC.delegate = self
                
                alphaSliderVC.view.frame = CGRect(x: UIScreen.main.bounds.width - 32, y: self.previewView.frame.minY, width: 32, height: self.previewView.frame.height - keyboardSize.height)
                view.addSubview(alphaSliderVC.view)
                
                alphaSliderVC.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
                alphaSliderVC.view.heightAnchor.constraint(equalToConstant: self.previewView.frame.height - keyboardSize.height).isActive = true
                alphaSliderVC.view.widthAnchor.constraint(equalToConstant: 32).isActive = true
                alphaSliderVC.view.topAnchor.constraint(equalTo: self.previewView.topAnchor).isActive = true
                
                alphaSliderVC.view.transform = CGAffineTransform(translationX: 50, y: 0)
                
                if let activeTextView = self.activeTextView {
                    fontSliderVC.previousValue = Float(((activeTextView.font?.pointSize ?? 38) - 16)) / 32
                }
                
                fontSliderVC.delegate = self
                
                fontSliderVC.view.frame = CGRect(x: 0, y: self.previewView.frame.minY, width: 32, height: self.previewView.frame.height - keyboardSize.height)
                view.addSubview(fontSliderVC.view)
                
                fontSliderVC.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
                fontSliderVC.view.heightAnchor.constraint(equalToConstant: self.previewView.frame.height - keyboardSize.height).isActive = true
                fontSliderVC.view.widthAnchor.constraint(equalToConstant: 32).isActive = true
                fontSliderVC.view.topAnchor.constraint(equalTo: self.previewView.topAnchor).isActive = true
                
                fontSliderVC.view.transform = CGAffineTransform(translationX: -50, y: 0)
            }
            
            UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseInOut, animations: {
                toolbarVC.view.transform = .identity
                alphaSliderVC.view.transform = .identity
                fontSliderVC.view.transform = .identity
            }, completion: { _ in
                toolbarVC.didMove(toParent: self)
                alphaSliderVC.didMove(toParent: self)
                fontSliderVC.didMove(toParent: self)
            })
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue, let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        for child in self.children {
            switch child {
            case is ToolBarVC:
                UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseInOut, animations: {
                    child.view.transform = CGAffineTransform(translationX: 0, y: keyboardSize.height + 100)
                }, completion: { _ in
                    child.willMove(toParent: nil)
                    child.view.removeFromSuperview()
                    child.removeFromParent()
                    child.view.transform = .identity
                })
            case is AlphaSliderVC:
                UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseInOut, animations: {
                    child.view.transform = CGAffineTransform(translationX: 50, y: 0)
                }, completion: { _ in
                    child.willMove(toParent: nil)
                    child.view.removeFromSuperview()
                    child.removeFromParent()
                    child.view.transform = .identity
                })
            case is FontSliderVC:
                UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseInOut, animations: {
                    child.view.transform = CGAffineTransform(translationX: -50, y: 0)
                }, completion: { _ in
                    child.willMove(toParent: nil)
                    child.view.removeFromSuperview()
                    child.removeFromParent()
                    child.view.transform = .identity
                })
            default: break
            }
        }
    }
}

extension PreviewVC: ToolBarDelegate {
    
    func textColorDidChanged(color: UIColor) {
        self.activeTextView?.textColor = color
    }
    
    func bgColorDidChanged(color: UIColor) {
        self.activeTextView?.backgroundColor = color
    }
    
    func fontDidChanged(font: UIFont) {
        self.activeTextView?.font = font.withSize(self.activeTextView?.font?.pointSize ?? 32)
        
        if let existTextView = self.activeTextView {
            
            let keyboardHeight = UserDefaults.standard.value(forKey: "keyboardHeight") as? CGFloat ?? 400
            let newSize = existTextView.sizeThatFits(CGSize(width: self.previewView.frame.width - 32, height: self.previewView.frame.height - keyboardHeight))
            let newWidth = min(newSize.width, self.previewView.frame.width - 32)
            let newHeight = min(newSize.height, self.previewView.frame.height - keyboardHeight)
            existTextView.frame = CGRect(x: self.previewView.frame.width/2 - newWidth/2, y: 42, width: newWidth, height: newHeight)
            
        }
    }
    
    func tagDidSelected(username: String) {
        
        guard let activeTextView = self.activeTextView else {
            return
        }
        
        activeTextView.text = "@" + username
        activeTextView.type = .mention
        let newSize = activeTextView.sizeThatFits(CGSize(width: self.previewView.frame.width - 32, height: self.previewView.frame.height/2))
        let newWidth = min(newSize.width, self.previewView.frame.width - 32)
        activeTextView.frame = CGRect(x: self.previewView.frame.width/2 - newWidth/2, y: 50, width: newWidth, height: newSize.height)
    }
    
    func startMentionMode() {
        guard let activeTextView = self.activeTextView else {
            return
        }
        
        activeTextView.text = "@"
        activeTextView.type = .mention
        let newSize = activeTextView.sizeThatFits(CGSize(width: self.previewView.frame.width - 32, height: self.previewView.frame.height/2))
        let newWidth = min(newSize.width, self.previewView.frame.width - 32)
        activeTextView.frame = CGRect(x: self.previewView.frame.width/2 - newWidth/2, y: 50, width: newWidth, height: newSize.height)
    }
    
}

extension PreviewVC: LinkDelegate {
    
    func setData(link: URL, text: String?, textViewID: String) {
        
        guard let existTextView = NewMediaManager.shared.newMedia[mediaIndex].textViews.filter({$0.id == textViewID}).first else {
            return
        }
        
        if let text = text, text.count > 0 {
            
            let fullString = NSMutableAttributedString(string: "")

            // create our NSTextAttachment
            let image1Attachment = NSTextAttachment()
            image1Attachment.image = UIImage(named: "i_link_color")
            image1Attachment.bounds = CGRect(x: 0, y: -7, width: 40, height: 40)

            // wrap the attachment in its own attributed string so we can append it
            let image1String = NSAttributedString(attachment: image1Attachment)

            // add the NSTextAttachment wrapper to our full string, then add some more text.
            fullString.append(image1String)
            fullString.append(NSAttributedString(string: " "))
            fullString.append(NSAttributedString(string: text.uppercased(), attributes: [NSAttributedString.Key.font : existTextView.font ?? UIFont.systemFont(ofSize: 38, weight: .bold)]))

            // draw the result in a label
            existTextView.attributedText = fullString
            
        } else {
            
            let fullString = NSMutableAttributedString(string: "")

            // create our NSTextAttachment
            let image1Attachment = NSTextAttachment()
            image1Attachment.image = UIImage(named: "i_link_color")
            image1Attachment.bounds = CGRect(x: 0, y: -7, width: 40, height: 40)

            // wrap the attachment in its own attributed string so we can append it
            let image1String = NSAttributedString(attachment: image1Attachment)

            // add the NSTextAttachment wrapper to our full string, then add some more text.
            fullString.append(image1String)
            fullString.append(NSAttributedString(string: " "))
            fullString.append(NSAttributedString(string: link.host?.uppercased() ?? "ССЫЛКА", attributes: [NSAttributedString.Key.font : existTextView.font ?? UIFont.systemFont(ofSize: 38, weight: .bold)]))
            
            // draw the result in a label
            existTextView.attributedText = fullString
            
        }
        
        existTextView.drawGradientColor(colors: [UIColor(hexString: "00EAFF").cgColor, UIColor(hexString: "3C8CE7").cgColor])
        existTextView.type = .link
        existTextView.linkURL = link
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            self.textEditMode = false
        }
        
    }
    
}

extension PreviewVC: SliderDegegate {
    
    func setFontSizeVlaue(value: Float) {
        guard let existTextView = NewMediaManager.shared.newMedia[mediaIndex].textViews.filter({$0.id == self.activeTextView?.id ?? ""
        }).first else {
            return
        }
        
//        let maxFontSize = 48
//        let minFontSize = 16
        
        existTextView.font = existTextView.font?.withSize(16 + (CGFloat(value) * 32))
        
        let keyboardHeight = UserDefaults.standard.value(forKey: "keyboardHeight") as? CGFloat ?? 400
        let newSize = existTextView.sizeThatFits(CGSize(width: self.previewView.frame.width - 32, height: self.previewView.frame.height - keyboardHeight))
        let newWidth = min(newSize.width, self.previewView.frame.width - 32)
        let newHeight = min(newSize.height, self.previewView.frame.height - keyboardHeight)
        existTextView.frame = CGRect(x: self.previewView.frame.width/2 - newWidth/2, y: 42, width: newWidth, height: newHeight)
        
        print("FONT VALUE:", value)
    }
    
    func setAlphaValue(alpha: Float) {
        print("Delegate:", alpha)
        
        guard let existTextView = NewMediaManager.shared.newMedia[mediaIndex].textViews.filter({$0.id == self.activeTextView?.id ?? ""
        }).first else {
            return
        }
        
        switch self.toolBarType {
        case .bgColor:
            existTextView.bgAlpha = alpha
        default:
            existTextView.textAlpha = alpha
        }
        
    }
    
}
