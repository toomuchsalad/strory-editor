//
//  CameraVC.swift
//  photo-editor
//
//  Created by Andrey Atroshchenko on 27.07.2022.
//

import Foundation
import UIKit
import AVFoundation

class CameraVC: UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var galleryButton: UIButton!
    @IBOutlet weak var changeCameraButton: UIButton!
    @IBOutlet weak var shootBgView: UIView!
    @IBOutlet weak var shootButton: UIButton!
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var previewRightConst: NSLayoutConstraint!
    @IBOutlet weak var previewLeftConst: NSLayoutConstraint!
    
    var captureSession: AVCaptureSession!
    var stillImageOutput: AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var finalImage: UIImage?
    
    var isBackCamera: Bool = true {
        didSet {
            self.videoPreviewLayer.removeFromSuperlayer()
            captureSession.stopRunning()
            
            setupSession()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        previewLeftConst.constant = deviceHasHomeButton() ? 20 : 0
        previewRightConst.constant = deviceHasHomeButton() ? 20 : 0
        
        galleryButton.layer.cornerRadius = 20
        galleryButton.clipsToBounds = true
        changeCameraButton.layer.cornerRadius = 20
        changeCameraButton.clipsToBounds = true
        
        shootBgView.layer.cornerRadius = 32
        shootBgView.layer.borderWidth = 3
        shootBgView.layer.borderColor = UIColor.white.cgColor
        shootButton.clipsToBounds = true
        
        shootButton.layer.cornerRadius = 28
        shootButton.clipsToBounds = true
        
        previewView.layer.cornerRadius = 6
        previewView.clipsToBounds = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupSession()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
//        self.setupSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.captureSession.stopRunning()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBAction func closeButtonAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func galleryButtonAction(_ sender: Any) {
        
    }
    
    @IBAction func changeCameraButtonAction(_ sender: Any) {
        isBackCamera.toggle()
    }
    
    @IBAction func shootButtonAction(_ sender: Any) {
        self.shootButton.backgroundColor = .gray
        
        let photoSettings: AVCapturePhotoSettings
        if self.stillImageOutput.availablePhotoCodecTypes.contains(.hevc) {
            photoSettings = AVCapturePhotoSettings(format:
                                                    [AVVideoCodecKey: AVVideoCodecType.hevc])
        } else {
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])
        }
//            photoSettings.isAutoStillImageStabilizationEnabled = self.stillImageOutput.isStillImageStabilizationSupported
        self.stillImageOutput.capturePhoto(with: photoSettings, delegate: self)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            self.shootButton.backgroundColor = .white
        }
        
    }
    
    func setupSession() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        var device: AVCaptureDevice!
        if isBackCamera {
            guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)
            else {
                print("Unable to access back camera!")
                return
            }
            device = backCamera
        } else {
            guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
            else {
                print("Unable to access front camera!")
                return
            }
            device = frontCamera
        }
        do {
            device.isFocusModeSupported(.continuousAutoFocus)
            let input = try AVCaptureDeviceInput(device: device)
            stillImageOutput = AVCapturePhotoOutput()
            stillImageOutput.isHighResolutionCaptureEnabled = true
            
            if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(stillImageOutput)
                setupLivePreview()
            }
        }
        catch let error  {
            print("Error Unable to initialize back camera:  \(error.localizedDescription)")
        }
    }
    
    func setupLivePreview() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.connection?.videoOrientation = .portrait
        self.videoPreviewLayer.frame = self.previewView.bounds
        previewView.layer.addSublayer(videoPreviewLayer)
        DispatchQueue.global(qos: .userInitiated).async { //[weak self] in
            self.captureSession.startRunning()
        }
    }
}

extension CameraVC: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        self.videoPreviewLayer.removeFromSuperlayer()
        
        DispatchQueue.main.async {
            guard let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) else {
                return
            }
            
            NewMediaManager.shared.newMedia.insert(MediaModel(videoURL: nil, image: image, textViews: []), at: 0)
            
            guard let previewVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PreviewVC") as? PreviewVC else {
                print("PreviewVC storyboard name error")
                return
            }
            
            self.navigationController?.pushViewController(previewVC, animated: false)
        }
    }
}
