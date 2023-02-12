//
//  MediaPickerVC.swift
//  photo-editor
//
//  Created by Andrey Atroshchenko on 26.07.2022.
//

import Foundation
import UIKit
import Photos

class MediaPickerVC: UIViewController {
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var mediaTypeButton: UIButton!
    @IBOutlet weak var mediaCollectionView: UICollectionView!
    @IBOutlet weak var multiSelectionButton: UIButton!
    
    var screenType: MediaPickerType = .post
    var mediaType: PHAssetMediaType = .image {
        didSet {
            if mediaType == .video {
                multiSelectionMode = false
                multiSelectionButton.isHidden = true
            } else {
                multiSelectionButton.isHidden = false
            }
        }
    }
    var imageManager: PHCachingImageManager?
    
    var multiSelectionMode: Bool = false {
        didSet {
            mediaCollectionView.allowsMultipleSelection = multiSelectionMode
        }
    }
    var selectedRows: [Int] = []
    var loadingAlert: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mediaCollectionView.delegate = self
        mediaCollectionView.dataSource = self
        setCollectionLayout()
        
        titleLbl.adjustsFontSizeToFitWidth = true
        switch screenType {
        case .story:
            titleLbl.text = "Добавить в историю"
        case .post:
            titleLbl.text = "Новая публикация"
        }
        
         multiSelectionButton.layer.cornerRadius = 16
         multiSelectionButton.clipsToBounds = true
         multiSelectionButton.layer.borderColor = UIColor.black.cgColor
         multiSelectionButton.layer.borderWidth = 1
        
        if #available(iOS 14.0, *) {
            mediaTypeButton.showsMenuAsPrimaryAction = true
            mediaTypeButton.menu = createMenuTypeButton()
        }
        
        reloadData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadData), name: .mediaLibraryAccessChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.showPreview), name: .videoDone, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .mediaLibraryAccessChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: .videoDone, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setCollectionLayout()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    func setCollectionLayout() {
        let flow = UICollectionViewFlowLayout()
        let width = (UIScreen.main.bounds.width - 4) / 3
        flow.itemSize = CGSize(width: width, height: width)
        flow.minimumLineSpacing = 2
        flow.minimumInteritemSpacing = 2
        flow.scrollDirection = .vertical
        flow.sectionInset = .zero
        
        mediaCollectionView.collectionViewLayout = flow
    }
    
    @objc func reloadData() {
        DispatchQueue.main.async {
            MediaPickerManager.shared.loadData(type: self.mediaType)
            self.mediaCollectionView.reloadData()
        }
        
    }
    
    @IBAction func closeButtonAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func mediaTypeButtonAction(_ sender: UIButton) {
        self.mediaType = mediaType == .image ? .video : .image
        self.mediaTypeButton.setTitle(mediaType == .image ? "Фото" : "Видео", for: .normal)
        self.reloadData()
    }
    
    func createMenuTypeButton() -> UIMenu {
        
        let photosAction = UIAction(title: "Фото") { photo in
            print("photo")
            self.mediaType = .image
            self.reloadData()
        }
        
        let videosAction = UIAction(title: "Видео") { photo in
            print("video")
            self.mediaType = .video
            self.reloadData()
        }
        
        let menu = UIMenu(title: "", children: [photosAction, videosAction])
        
        return menu
    }
    
    @IBAction func multiSelectionButtonAction(_ sender: Any) {
        if self.multiSelectionMode {
            pickMultiPhoto()
        } else {
            self.multiSelectionMode = true
            multiSelectionButton.setTitle("Далее", for: .normal)
        }
    }
    
    func pickOnePhoto(index: Int) {
        guard let asset = MediaPickerManager.shared.assetsFetchResults?[index] else {
            return
        }
        MediaPickerManager.shared.addPhoto(asset: asset)
        
        showPreview()
    }
    
    func pickMultiPhoto() {
        for newIndex in selectedRows {
            guard let asset = MediaPickerManager.shared.assetsFetchResults?[newIndex - 1] else {
                return
            }
            MediaPickerManager.shared.addPhoto(asset: asset)
        }
        
        showPreview()
    }
    
    func pickVideo(index: Int) {
        
        guard let asset = MediaPickerManager.shared.assetsFetchResults?[index] else {
            return
        }
        
        
        MediaPickerManager.shared.addVideo(asset: asset)
        
        loadingAlert = UIAlertController(title: "Подготовка", message: nil, preferredStyle: .alert)
        let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 10,y: 5,width: 50, height: 50)) as UIActivityIndicatorView
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        loadingAlert?.view.addSubview(loadingIndicator)
        
        self.present(loadingAlert!, animated: true)
        
        //            showPreview()
        
    }
    
    @objc func showPreview() {
        
        if loadingAlert != nil {
            loadingAlert?.dismiss(animated: true)
            loadingAlert = nil
        }
        
        guard let previewVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PreviewVC") as? PreviewVC else {
            print("PreviewVC storyboard name error")
            return
        }
        
        let navi = UINavigationController(rootViewController: previewVC)
        navi.navigationBar.isHidden = true
        navi.navigationBar.barStyle = .black
        navi.modalPresentationStyle = .fullScreen
        
        weak var pvc = self.presentingViewController

        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: {
                pvc?.present(navi, animated: true, completion: nil)
            })
        }
    }
}

extension MediaPickerVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (MediaPickerManager.shared.assetsFetchResults?.count ?? 0) + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == 0 {
            let cameraCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cameraCell", for: indexPath)
            
            return cameraCell
        } else {
            let mediaCell = collectionView.dequeueReusableCell(withReuseIdentifier: "mediaCell", for: indexPath)
            
            let mediaImageView = mediaCell.viewWithTag(101) as? UIImageView
            mediaImageView?.contentMode = .scaleAspectFill
            
            let tintView = mediaCell.viewWithTag(102)
            let borderView = mediaCell.viewWithTag(103)
            let timeLbl = mediaCell.viewWithTag(104) as? UILabel
            
            timeLbl?.layer.shadowColor = UIColor.black.cgColor
            timeLbl?.layer.shadowOffset = CGSize(width: 0, height: 2)
            timeLbl?.layer.shadowRadius = 2
            timeLbl?.layer.shadowOpacity = 1
            timeLbl?.layer.masksToBounds = false
            
            borderView?.backgroundColor = .clear
            borderView?.layer.borderWidth = 4
            borderView?.layer.borderColor = UIColor.white.cgColor
            
            tintView?.isHidden = !selectedRows.contains(indexPath.row)
            
            mediaImageView?.image = MediaPickerManager.shared.getPhoto(index: indexPath.row - 1, cellSize: mediaCell.bounds.size)
            
            timeLbl?.isHidden = !(self.mediaType == .video)
            
            if self.mediaType == .video {
                timeLbl?.text = MediaPickerManager.shared.getVideoDuration(index: indexPath.row - 1)
            }
            
            return mediaCell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            guard let cameraVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CameraVC") as? CameraVC else {
                print("CameraVC storyboard name error")
                return
            }
            let navi = UINavigationController(rootViewController: cameraVC)
            navi.navigationBar.isHidden = true
            navi.navigationBar.barStyle = .black
            navi.modalPresentationStyle = .fullScreen
            self.present(navi, animated: true)
        } else {
            switch mediaType {
            case .image:
                if self.multiSelectionMode {
                    if selectedRows.contains(indexPath.row) {
                        selectedRows = selectedRows.filter {$0 != indexPath.row}
                    } else {
                        if selectedRows.count >= 5 {
                            showAlert(title: "Максимум", body: "Возможно выбрать не больше 5 фото")
                        } else {
                            selectedRows.append(indexPath.row)
                        }
                    }
                    mediaCollectionView.reloadItems(at: [indexPath])
                } else {
                    self.pickOnePhoto(index: indexPath.row - 1)
                }
            case .video:
                self.pickVideo(index: indexPath.row - 1)
            default: break
            }
        }
    }
}
