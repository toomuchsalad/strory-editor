//
//  MakeMediaManager.swift
//  photo-editor
//
//  Created by Andrey Atroshchenko on 27.07.2022.
//

import Foundation
import Photos
import UIKit
import AVFoundation
import CoreImage.CIFilterBuiltins

class NewMediaManager {
    
    static let shared = NewMediaManager()
    
    var newMedia: [MediaModel] = [] {
        willSet {
            if newValue.count != newMedia.count {
                NotificationCenter.default.post(name: .newMediaDidChanged, object: nil, userInfo: nil)
            }
        }
    }
    
    func saveImage(preview:UIView, multi: Bool = false) {
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 6
        let renderer = UIGraphicsImageRenderer(bounds: preview.bounds, format: format)
        preview.layer.cornerRadius = 0
        preview.layoutIfNeeded()
        let image = renderer.image { rendererContext in
            preview.layer.render(in: rendererContext.cgContext)
        }
        preview.layer.cornerRadius = 6
        preview.layoutIfNeeded()
        
        guard let previewVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PreviewVC") as? PreviewVC else {
            return
        }
        
        if !multi {
            UIImageWriteToSavedPhotosAlbum(image, previewVC, #selector(previewVC.saveCompleted(_:didFinishSavingWithError:contextInfo:)), nil)
        } else {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
    }
    
    func saveMultiImage(preview: UIView) {
        
        for media in newMedia {
            
            let ids = media.textViews.map { $0.id }
            for oldView in preview.subviews {
                if let existTexView = oldView as? AdvancedTextView {
                    oldView.isHidden = !ids.contains(where: { $0 == existTexView.id })
                } else if let imgView = oldView as? UIImageView {
                    imgView.image = media.image
                }
            }
            saveImage(preview: preview, multi: true)
            
        }
        
        NotificationCenter.default.post(name: .multiPhotoSaved, object: nil, userInfo: nil)
        
    }
    
    func saveVideo(preview:UIView, videoURL: URL) {
        makeVideo(videoURL: videoURL, previewView: preview) { exportedURL in
            guard let exportedURL = exportedURL else {
                return
            }
            print(exportedURL)
            
            PHPhotoLibrary.shared().performChanges( {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: exportedURL)
            }) { [weak self] (isSaved, error) in
                if isSaved {
                    print("Video saved.")
                    NotificationCenter.default.post(name: .videoSaved, object: nil, userInfo: nil)
                } else {
                    print("Cannot save video.")
                    print(error ?? "unknown error")
                    NotificationCenter.default.post(name: .videoError, object: nil, userInfo: nil)
                }
                
            }
            
        }
    }
    
    func makeVideo(videoURL: URL, previewView: UIView, onComplete: @escaping (URL?) -> Void) {
        print(videoURL)
        let asset = AVURLAsset(url: videoURL)
        let composition = AVMutableComposition()
        
        guard let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid), let assetTrack = asset.tracks(withMediaType: .video).first else {
            print("Something is wrong with the asset.")
            onComplete(nil)
            return
        }
        
        do {
            let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
            try compositionTrack.insertTimeRange(timeRange, of: assetTrack, at: .zero)
            
            if let audioAssetTrack = asset.tracks(withMediaType: .audio).first,
               let compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid) {
                try compositionAudioTrack.insertTimeRange(
                    timeRange,
                    of: audioAssetTrack,
                    at: .zero)
            }
        } catch {
            print(error)
            onComplete(nil)
            return
        }
        
        compositionTrack.preferredTransform = assetTrack.preferredTransform
        let videoInfo = orientation(from: assetTrack.preferredTransform)
        
        let videoSize: CGSize
        if videoInfo.isPortrait {
            videoSize = CGSize(
                width: assetTrack.naturalSize.height,
                height: assetTrack.naturalSize.width)
        } else {
            videoSize = assetTrack.naturalSize
        }
        
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: videoSize)
        let overlayLayer = CALayer()
        overlayLayer.frame = CGRect(origin: .zero, size: videoSize)
        
        videoLayer.frame = CGRect(x: 0, y: 0, width: videoSize.width, height: videoSize.height)
        
        addImage(toLayer: overlayLayer, fromView: previewView, videoSize: videoSize)
        
        let outputLayer = CALayer()
        outputLayer.frame = CGRect(origin: .zero, size: videoSize)
        outputLayer.addSublayer(videoLayer)
        outputLayer.addSublayer(overlayLayer)
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = videoSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: outputLayer)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(
            start: .zero,
            duration: composition.duration)
        videoComposition.instructions = [instruction]
        let layerInstruction = compositionLayerInstruction(
            for: compositionTrack,
            assetTrack: assetTrack)
        instruction.layerInstructions = [layerInstruction]
        
        guard let export = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPreset1280x720)
        else {
            print("Cannot create export session.")
            onComplete(nil)
            return
        }
        
        let videoName = UUID().uuidString
        let exportURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(videoName)
            .appendingPathExtension("mov")
        
        export.videoComposition = videoComposition
        export.outputFileType = .mov
        export.outputURL = exportURL
        
        export.exportAsynchronously {
            DispatchQueue.main.async {
                switch export.status {
                case .completed:
                    onComplete(exportURL)
                default:
                    print("Something went wrong during export.")
                    print(export.error ?? "unknown error")
                    onComplete(nil)
                    break
                }
            }
        }
    }
    
    private func addImage(toLayer: CALayer, fromView: UIView, videoSize: CGSize) {
        
        for subview in fromView.subviews {
            if subview.tag == 111 {
                print("FOUND")
                subview.isHidden = true
            }
        }
        
        print("VIDEO SIZE:", videoSize, "VIEW SIZE:", fromView.frame.size)
        
        let image = fromView.asImage()
        
        let imageLayer = CALayer()
        
        let aspect: CGFloat = image.size.width / image.size.height
        print("ASPECT:", aspect)
        let width = videoSize.width
        let height = width / aspect
        if videoSize.height > videoSize.width {
            imageLayer.frame = CGRect(x: 0, y: 0, width: width, height: height)
        } else {
            let y = (height - width*aspect)/2
            imageLayer.frame = CGRect(x: 0, y: -y, width: width, height: height)
        }
        
        
        imageLayer.contents = image.cgImage
        toLayer.addSublayer(imageLayer)
        
        for subview in fromView.subviews {
            if subview.tag == 111 {
                print("FOUND")
                subview.isHidden = false
            }
        }
    }
    
    private func orientation(from transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .down
        }
        
        return (assetOrientation, isPortrait)
    }
    
    private func compositionLayerInstruction(for track: AVCompositionTrack, assetTrack: AVAssetTrack) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let transform = assetTrack.preferredTransform
        
        instruction.setTransform(transform, at: .zero)
        
        return instruction
    }
    
}

