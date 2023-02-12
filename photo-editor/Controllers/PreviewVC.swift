//
//  PreviewVC.swift
//  photo-editor
//
//  Created by Andrey Atroshchenko on 27.07.2022.
//

import Foundation
import UIKit
import AVFoundation

class PreviewVC: UIViewController {
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var previewVideoView: UIView!
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var soundButton: UIButton!
    @IBOutlet weak var textButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var imageTintView: UIView!
    
    @IBOutlet weak var previewCollectionView: UICollectionView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var mainToolsView: UIView!
    
    @IBOutlet weak var textEditToolsView: UIView!
    @IBOutlet weak var textDoneButton: UIButton!
    @IBOutlet weak var textAlignButton: UIButton!
    @IBOutlet weak var textColorButton: UIButton!
    @IBOutlet weak var textBgColorButton: UIButton!
    @IBOutlet weak var textFontButton: UIButton!
    
    @IBOutlet weak var deleteImageView: UIImageView!
    
    @IBOutlet weak var previewRightConst: NSLayoutConstraint!
    @IBOutlet weak var previewLeftConst: NSLayoutConstraint!
    
    var mediaIndex: Int = 0
    var textEditMode: Bool = false {
        didSet {
            if !textEditMode {
                view.endEditing(true)
                toolBarType = .none
            }
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.3) { [self] in
                    imageTintView.alpha = textEditMode ? 1 : 0
                    mainToolsView.alpha = textEditMode ? 0 : 1
                    textEditToolsView.alpha = textEditMode ? 1 : 0
                }
                if self.player != nil {
                    if self.textEditMode {
                        self.player?.pause()
                    } else {
                        self.player?.play()
                    }
                }
            }
            
        }
    }
    var activeTextView: AdvancedTextView?
    var toolBarType: ToolBarType = .none {
        didSet {
            updateTextButons()
            for child in self.children {
                if let vc = child as? ToolBarVC {
                    vc.toolBarType = toolBarType
                }
            }
        }
    }
    
    var soundEnable: Bool = true {
        didSet {
            if player != nil {
                self.player?.isMuted = !soundEnable
                self.soundButton.setImage(soundEnable ? UIImage(named: "b_vol"):UIImage(systemName: "speaker.slash"), for: .normal)
            }
        }
    }
    var player: AVQueuePlayer?
    var playerLayer: AVPlayerLayer?
    var videoLooper: AVPlayerLooper?
    
    var loadingAlert: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        previewLeftConst.constant = deviceHasHomeButton() ? 20 : 0
        previewRightConst.constant = deviceHasHomeButton() ? 20 : 0
        
        let roundButtons: [UIButton] = [soundButton, textButton, downloadButton, nextButton, textAlignButton, textColorButton, textBgColorButton, textFontButton]
        roundButtons.forEach { button in
            button.layer.cornerRadius = 20
            button.clipsToBounds = true
        }
        textColorButton.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
        textBgColorButton.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
        textFontButton.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
        
        
        previewView.layer.cornerRadius = 6
        previewView.clipsToBounds = true
        
        previewCollectionView.delegate = self
        previewCollectionView.dataSource = self
        
        textEditToolsView.alpha = 0
        imageTintView.alpha = 0
        
        setMedia()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.setMedia), name: .newMediaDidChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(videoSaved), name: .videoSaved, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(multiPhotoSaved), name: .multiPhotoSaved, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .newMediaDidChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: .videoSaved, object: nil)
        NotificationCenter.default.removeObserver(self, name: .multiPhotoSaved, object: nil)
//        NewMediaManager.shared.newMedia = []
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playerLayer?.frame = self.previewView.bounds
        playerLayer?.videoGravity = .resizeAspect
    }
    
    @objc func setMedia() {
        if NewMediaManager.shared.newMedia.count > mediaIndex {
            
            hideLoading()
            
            let newMedia = NewMediaManager.shared.newMedia[mediaIndex]
            
            if newMedia.videoURL != nil {
                DispatchQueue.main.async { [self] in
//                    if player != nil {
                        player?.pause()
                        player = nil
                        playerLayer = nil
                        playerLayer?.removeFromSuperlayer()
                    videoLooper = nil
                    previewVideoView.layer.sublayers?.forEach({ layer in
                        if layer is AVPlayerLayer {
                            layer.removeFromSuperlayer()
                        }
                    })
//                    }
                    
                    previewImageView.isHidden = true
                    previewVideoView.isHidden = false
                    
                    player = AVQueuePlayer(url: newMedia.videoURL!)
                    videoLooper = AVPlayerLooper(player: player!, templateItem: AVPlayerItem(url: newMedia.videoURL!))
                    
                    playerLayer = AVPlayerLayer(player: player)
                    playerLayer?.frame = self.previewVideoView.bounds
                    playerLayer?.videoGravity = .resizeAspect
                    
                    if playerLayer != nil {
                        self.previewVideoView.layer.insertSublayer(playerLayer!, at: 0)
                        player?.play()
                    }
                }
            } else {
                DispatchQueue.main.async { [self] in
                    previewImageView.isHidden = false
                    previewVideoView.isHidden = true
                    previewImageView.image = newMedia.image
                }
            }
            
            let ids = newMedia.textViews.map { $0.id }
            for oldTexView in self.previewView.subviews {
                if let existTexView = oldTexView as? AdvancedTextView {
                    oldTexView.isHidden = !ids.contains(where: { $0 == existTexView.id })
                }
            }
            
            previewCollectionView.reloadData()
            
        } else {
            
            showLoading(title: "Подготовка")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.setMedia()
            }
            
        }
        
    }
    
    func showLoading(title:String) {
        if loadingAlert == nil {
            loadingAlert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
            let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 10,y: 5,width: 50, height: 50)) as UIActivityIndicatorView
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.style = .medium
            loadingIndicator.startAnimating()
            loadingAlert?.view.addSubview(loadingIndicator)
            
            self.present(loadingAlert!, animated: true)
        }
    }
    
    func hideLoading() {
        if loadingAlert != nil {
            DispatchQueue.main.async {
                self.loadingAlert?.dismiss(animated: true)
                self.loadingAlert = nil
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if textEditMode {
            textEditMode = false
        }
    }
    
    @objc func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            showAlert(title: "Ошибка сохранения", body: error.localizedDescription)
        } else {
            showAlert(title: "Успешно сохранено", body: nil)
        }
    }
    
    @objc func videoSaved() {
        if loadingAlert != nil {
            DispatchQueue.main.async {
                self.loadingAlert?.dismiss(animated: true, completion: {
                    showAlert(title: "Успешно сохранено", body: nil)
                })
                self.loadingAlert = nil
            }
        }
    }
    
    @objc func multiPhotoSaved() {
        setMedia()
        DispatchQueue.main.async {
            self.loadingAlert?.dismiss(animated: true, completion: {
                print("ALERT")
                showAlert(title: "Успешно сохранено", body: nil)
            })
            self.loadingAlert = nil
        }
    }
    
    @IBAction func closeButtonAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func soundButtonAction(_ sender: Any) {
        self.soundEnable.toggle()
    }
    
    @IBAction func textButtonAction(_ sender: Any) {
        textEditMode = true
        addNewTextView()
    }
    
    @IBAction func downloadButtonAction(_ sender: Any) {
        if let videoURL = NewMediaManager.shared.newMedia[mediaIndex].videoURL {
            NewMediaManager.shared.saveVideo(preview: self.previewView, videoURL: videoURL)
            self.showLoading(title: "Cохранение")
        } else {
            NewMediaManager.shared.saveImage(preview: self.previewView)
//            self.showLoading(title: "Cохранение")
        }
    }
    
    @IBAction func nextButtonAction(_ sender: Any) {
        if let videoURL = NewMediaManager.shared.newMedia[mediaIndex].videoURL {
//            NewMediaManager.shared.saveVideo(preview: self.previewView, videoURL: videoURL)
//            self.showLoading(title: "Cохранение")
        } else {
            NewMediaManager.shared.saveMultiImage(preview: self.previewView)
            self.showLoading(title: "Cохранение")
        }
    }
    
    //text edit buttons
    @IBAction func textDoneButtonAction(_ sender: Any) {
        textEditMode = false
    }
    
    @IBAction func textAlignButtonAction(_ sender: Any) {
        switch self.activeTextView?.textAlignment {
        case .center:
            self.activeTextView?.textAlignment = .left
            self.textAlignButton.setImage(UIImage(systemName: "text.alignleft"), for: .normal)
        case .left:
            self.activeTextView?.textAlignment = .right
            self.textAlignButton.setImage(UIImage(systemName: "text.alignright"), for: .normal)
        default:
            self.activeTextView?.textAlignment = .center
            self.textAlignButton.setImage(UIImage(systemName: "text.aligncenter"), for: .normal)
        }
    }
    
    @IBAction func textColorButtonAction(_ sender: Any) {
        toolBarType = toolBarType == .textColor ? .none : .textColor
    }
    
    @IBAction func textBgButtonAction(_ sender: Any) {
        toolBarType = toolBarType == .bgColor ? .none : .bgColor
    }
    
    @IBAction func textFontButtonAction(_ sender: Any) {
        toolBarType = toolBarType == .font ? .none : .font
    }
    
    func updateTextButons() {
        switch toolBarType {
        case .textColor:
            textColorButton.backgroundColor = .white.withAlphaComponent(0.3)
            textColorButton.layer.borderWidth = 1
            textBgColorButton.backgroundColor = .white.withAlphaComponent(0.1)
            textBgColorButton.layer.borderWidth = 0
            textFontButton.backgroundColor = .white.withAlphaComponent(0.1)
            textFontButton.layer.borderWidth = 0
            guard let activeTextView = activeTextView else {
                return
            }
            NotificationCenter.default.post(name: .setSliderValue, object: nil, userInfo: ["newValue" : Float(activeTextView.textAlpha)])
        case .bgColor:
            textColorButton.backgroundColor = .white.withAlphaComponent(0.1)
            textColorButton.layer.borderWidth = 0
            textBgColorButton.backgroundColor = .white.withAlphaComponent(0.3)
            textBgColorButton.layer.borderWidth = 1
            textFontButton.backgroundColor = .white.withAlphaComponent(0.1)
            textFontButton.layer.borderWidth = 0
            guard let activeTextView = activeTextView else {
                return
            }
            NotificationCenter.default.post(name: .setSliderValue, object: nil, userInfo: ["newValue" : Float(activeTextView.bgAlpha)])
        case .font:
            textColorButton.backgroundColor = .white.withAlphaComponent(0.1)
            textColorButton.layer.borderWidth = 0
            textBgColorButton.backgroundColor = .white.withAlphaComponent(0.1)
            textBgColorButton.layer.borderWidth = 0
            textFontButton.backgroundColor = .white.withAlphaComponent(0.3)
            textFontButton.layer.borderWidth = 1
            guard let activeTextView = activeTextView else {
                return
            }
            NotificationCenter.default.post(name: .setSliderValue, object: nil, userInfo: ["newValue" : Float(activeTextView.textAlpha)])
        case .mention, .none:
            textColorButton.backgroundColor = .white.withAlphaComponent(0.1)
            textColorButton.layer.borderWidth = 0
            textBgColorButton.backgroundColor = .white.withAlphaComponent(0.1)
            textBgColorButton.layer.borderWidth = 0
            textFontButton.backgroundColor = .white.withAlphaComponent(0.1)
            textFontButton.layer.borderWidth = 0
        }
    }
    
}

extension PreviewVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return NewMediaManager.shared.newMedia.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "previewCell", for: indexPath)
        
        let previewImageView = cell.viewWithTag(201) as? UIImageView
        let selectedView = cell.viewWithTag(202)
        
        previewImageView?.layer.cornerRadius = 8
        previewImageView?.clipsToBounds = true
        
        selectedView?.layer.cornerRadius = 10
        selectedView?.layer.borderColor = UIColor.white.cgColor
        selectedView?.layer.borderWidth = 1
        
        selectedView?.isHidden = indexPath.row == mediaIndex ? false : true
        
        previewImageView?.image = NewMediaManager.shared.newMedia[indexPath.row].image
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        mediaIndex = indexPath.row
        self.setMedia()
    }
    
}
