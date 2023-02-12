//
//  MainVC.swift
//  photo-editor
//
//  Created by Andrey Atroshchenko on 26.07.2022.
//

import Foundation
import UIKit

class MainVC: UIViewController {
    
    @IBOutlet weak var newPostButton: UIButton!
    @IBOutlet weak var newStoryButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    @IBAction func newPostButtonAction(_ sender: Any) {
        self.showMediaPickerVC(type: .post)
    }
    
    @IBAction func newStoryButtonAction(_ sender: Any) {
        self.showMediaPickerVC(type: .story)
    }
    
    private func showMediaPickerVC(type:MediaPickerType) {
        guard let mediaPickerVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MediaPickerVC") as? MediaPickerVC else {
            print("MediaPickerVC storyboard name error")
            return
        }
        mediaPickerVC.screenType = type
        mediaPickerVC.modalPresentationStyle = .popover
        
        NewMediaManager.shared.newMedia = []
        
        self.present(mediaPickerVC, animated: true)
    }
    
}
