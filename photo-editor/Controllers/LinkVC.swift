//
//  LinkVC.swift
//  photo-editor
//
//  Created by Andrey Atroshchenko on 30.07.2022.
//

import Foundation
import UIKit

class LinkVC: UIViewController {
    
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var urlView: UIView!
    @IBOutlet weak var urlTextF: UITextField!
    @IBOutlet weak var stickerView: UIView!
    @IBOutlet weak var stickerTextF: UITextField!
    
    var delegate: LinkDelegate?
    var selectedTextViewId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        urlView.layer.cornerRadius = 6
        urlView.clipsToBounds = true
        
        urlView.layer.borderColor = UIColor(hexString: "#A0A4A8").cgColor
        urlView.layer.borderWidth = 1
        
        stickerView.layer.cornerRadius = 6
        stickerView.clipsToBounds = true
        
        stickerView.layer.borderColor = UIColor(hexString: "#A0A4A8").cgColor
        stickerView.layer.borderWidth = 1
        
        urlTextF.delegate = self
        stickerTextF.delegate = self
        
    }
    
    @IBAction func cancelButtonAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func doneButtonAction(_ sender: Any) {
        
        guard var linkString = urlTextF.text, linkString.count > 0 else {
            showAlert(title: "Ссылка недействительна", body: nil)
            return
        }
        
        if !linkString.contains("http") {
            linkString = "http://" + linkString
        }
        
        guard let linkURL = URL(string: linkString), UIApplication.shared.canOpenURL(linkURL) else {
            showAlert(title: "Ссылка недействительна", body: nil)
            return
        }
        
        delegate?.setData(link: linkURL, text: stickerTextF.text, textViewID: selectedTextViewId ?? "")
        
        self.dismiss(animated: true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

extension LinkVC:UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        switch textField {
        case urlTextF:
            urlView.layer.borderColor = UIColor.white.cgColor
        case stickerTextF:
            stickerView.layer.borderColor = UIColor.white.cgColor
        default: break
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        switch textField {
        case urlTextF:
            urlView.layer.borderColor = UIColor(hexString: "#A0A4A8").cgColor
        case stickerTextF:
            stickerView.layer.borderColor = UIColor(hexString: "#A0A4A8").cgColor
        default: break
        }
    }
}
