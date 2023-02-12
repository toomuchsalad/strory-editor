//
//  ToolBarVC.swift
//  photo-editor
//
//  Created by Andrey Atroshchenko on 28.07.2022.
//

import Foundation
import UIKit

class ToolBarVC: UIViewController {
    
    @IBOutlet var bottomToolBarView: UIVisualEffectView!
    @IBOutlet weak var mentionButton: UIButton!
    @IBOutlet weak var linkButton: UIButton!
    
    @IBOutlet weak var toolsCollectionView: UICollectionView!
    
    @IBOutlet weak var mentionEffectView: UIVisualEffectView!
    @IBOutlet weak var mentionCollectionView: UICollectionView!
    
    var toolBarType: ToolBarType = .none {
        didSet {
            setType()
        }
    }
    var delegate: ToolBarDelegate?
    
    var colors:[UIColor] = [.white,
                            UIColor(hexString: "040404"),
                            UIColor(hexString: "64D2FF"),
                            UIColor(hexString: "0A84FF"),
                            UIColor(hexString: "fc0200"),
                            UIColor(hexString: "6aa142"),
                            UIColor(hexString: "787276"),
                            UIColor(hexString: "555555"),
                            UIColor(hexString: "fa808d"),
                            UIColor(hexString: "FF9F0A"),
                            UIColor(hexString: "FFD60A"),
                            UIColor(hexString: "5E5CE6")]
//    var bgColors:[UIColor] = [.black, .white, .clear]
    
    var fonts:[UIFont] = [UIFont(name: "SF Pro Text Bold", size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .bold),
                          UIFont(name: "AlumniSans-Regular", size: 14)!,
                          UIFont(name: "Caveat-Regular", size: 14)!,
                          UIFont(name: "Lobster-Regular", size: 14)!,
                          UIFont(name: "Marmelad-Regular", size: 14)!,
                          UIFont(name: "Montserrat-ExtraBold", size: 14)!,
                          UIFont(name: "Nunito-Black", size: 14)!,
                          UIFont(name: "Pacifico-Regular", size: 14)!,
                          UIFont(name: "PlayfairDisplaySC-Bold", size: 14)!,
                          UIFont(name: "PoiretOne-Regular", size: 14)!,
                          UIFont(name: "SourceSerifPro-SemiBold", size: 14)!]
    
    var selectedTextColor: UIColor {
        get {
            guard let parent = self.parent as? PreviewVC else {
                return .white
            }
            return parent.activeTextView?.textColor ?? .white
        }
    }
    var selectedBgColor: UIColor {
        get {
            guard let parent = self.parent as? PreviewVC else {
                return .black
            }
            return parent.activeTextView?.backgroundColor ?? .black
        }
    }
    
    var selectedFont: UIFont {
        get {
            guard let parent = self.parent as? PreviewVC else {
                return .systemFont(ofSize: 32, weight: .medium)
            }
            return parent.activeTextView?.font ?? .systemFont(ofSize: 32, weight: .medium)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolsCollectionView.delegate = self
        toolsCollectionView.dataSource = self
        
        mentionCollectionView.delegate = self
        mentionCollectionView.dataSource = self
        
        guard let parent = parent as? PreviewVC else {
            return
        }
        if parent.activeTextView?.type == .mention {
            self.toolBarType = .mention
        }
        
    }
    
    func setType() {
        if bottomToolBarView != nil, toolsCollectionView != nil, mentionEffectView != nil {
            switch toolBarType {
            case .textColor, .bgColor:
                bottomToolBarView.isHidden = false
                toolsCollectionView.isHidden = false
                mentionEffectView.isHidden = true
                
                let flow = UICollectionViewFlowLayout()
                flow.itemSize = CGSize(width: 28, height: 28)
                flow.sectionInset = UIEdgeInsets(top: 5, left: 20, bottom: 0, right: 20)
                flow.scrollDirection = .horizontal
                flow.minimumLineSpacing = 8
                flow.minimumInteritemSpacing = 8
                toolsCollectionView.collectionViewLayout = flow
                toolsCollectionView.reloadData()
                toolsCollectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: true)
            case .font:
                bottomToolBarView.isHidden = false
                toolsCollectionView.isHidden = false
                mentionEffectView.isHidden = true
                
                let flow = UICollectionViewFlowLayout()
                flow.itemSize = CGSize(width: 36, height: 36)
                flow.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
                flow.scrollDirection = .horizontal
                flow.minimumLineSpacing = 12
                flow.minimumInteritemSpacing = 12
                toolsCollectionView.collectionViewLayout = flow
                toolsCollectionView.reloadData()
                toolsCollectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: true)
            case .mention:
                bottomToolBarView.isHidden = true
                toolsCollectionView.isHidden = true
                mentionEffectView.isHidden = false
            case .none:
                bottomToolBarView.isHidden = false
                toolsCollectionView.isHidden = true
                mentionEffectView.isHidden = true
            }
            toolsCollectionView.reloadData()
            mentionCollectionView.reloadData()
        }
    }
    
    @IBAction func mentionButtonAction(_ sender: Any) {
        delegate?.startMentionMode()
        self.toolBarType = .mention
    }
    
    @IBAction func linkButtonAction(_ sender: Any) {
        guard let linkVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LinkVC") as? LinkVC, let previewVC = parent as? PreviewVC else {
            return
        }
        
        linkVC.selectedTextViewId = previewVC.activeTextView?.id ?? ""
        linkVC.delegate = previewVC
        let navi = UINavigationController(rootViewController: linkVC)
        navi.navigationBar.barStyle = .black
        navi.modalPresentationStyle = .overCurrentContext
        self.present(navi, animated: true)
    }
}

extension ToolBarVC: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case toolsCollectionView:
            switch toolBarType {
            case .bgColor, .textColor:
                return colors.count
            case .font:
                return fonts.count
            default:
                return 0
            }
        case mentionCollectionView:
            return 7
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case toolsCollectionView:
            switch toolBarType {
            case .bgColor, .textColor:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "colorCell", for: indexPath)
                
                let smallView = cell.viewWithTag(401)
                smallView?.layer.cornerRadius = 9
                smallView?.clipsToBounds = true
                let bigView = cell.viewWithTag(402)
                bigView?.layer.cornerRadius = 14
                bigView?.clipsToBounds = true
                let borderView = cell.viewWithTag(403)
                borderView?.layer.cornerRadius = 14
                borderView?.clipsToBounds = true
                borderView?.layer.borderColor = UIColor.white.cgColor
                borderView?.layer.borderWidth = 2
                
                let color = colors[indexPath.row]
                
                smallView?.backgroundColor = color
                bigView?.backgroundColor = color
                
                if color.isEqual(toolBarType == .textColor ? selectedTextColor : selectedBgColor) {
                    print("match", indexPath.row)
//                    borderView?.isHidden = false
                    smallView?.isHidden = false
                    bigView?.isHidden = true
                } else {
//                    borderView?.isHidden = true
                    smallView?.isHidden = true
                    bigView?.isHidden = false
                }
                
                return cell
            case .font:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "fontCell", for: indexPath)
                
                let effectView = cell.viewWithTag(301) as? UIVisualEffectView
                effectView?.layer.cornerRadius = 18
                effectView?.clipsToBounds = true
                let blankView = cell.viewWithTag(302)
                blankView?.layer.cornerRadius = 18
                blankView?.clipsToBounds = true
                let fontLbl = cell.viewWithTag(303) as? UILabel
                
                let font = fonts[indexPath.row]
                fontLbl?.font = font
                
                if font.familyName == selectedFont.familyName {
                    effectView?.isHidden = true
                    blankView?.isHidden = false
                    fontLbl?.drawGradientColor(colors: [UIColor(hexString: "00EAFF").cgColor, UIColor(hexString: "3C8CE7").cgColor])
                } else {
                    effectView?.isHidden = false
                    blankView?.isHidden = true
                    fontLbl?.textColor = .white
                }
                
                return cell
            default:
                return UICollectionViewCell()
            }
        case mentionCollectionView:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "mentionCell", for: indexPath)
            
            let imgView = cell.viewWithTag(501) as? UIImageView
            let nameLbl = cell.viewWithTag(502) as? UILabel
            
            imgView?.layer.cornerRadius = 20
            imgView?.clipsToBounds = true
            imgView?.backgroundColor = .white
            
            nameLbl?.text = "user_\(indexPath.row)"
            
            return cell
        default:
            return UICollectionViewCell()
        }
    }
 
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch collectionView {
        case toolsCollectionView:
            switch toolBarType {
            case .bgColor:
                let newColor = colors[indexPath.row]
                delegate?.bgColorDidChanged(color: newColor)
//                selectedBgColor = newColor
                toolsCollectionView.reloadData()
            case .font:
                let newFont = fonts[indexPath.row].withSize(selectedFont.pointSize)
                delegate?.fontDidChanged(font: newFont)
//                selectedFont = newFont
                toolsCollectionView.reloadData()
            case .textColor:
                let newColor = colors[indexPath.row]
                delegate?.textColorDidChanged(color: newColor)
//                selectedTextColor = newColor
                toolsCollectionView.reloadData()
            default:
                break
            }
        case mentionCollectionView:
            delegate?.tagDidSelected(username: "user_\(indexPath.row)")
        default:
            break
        }
    }
}
