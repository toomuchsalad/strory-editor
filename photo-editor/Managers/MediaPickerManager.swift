//
//  MediaPickerManager.swift
//  photo-editor
//
//  Created by Andrey Atroshchenko on 26.07.2022.
//

import Foundation
import UIKit
import Photos

class MediaPickerManager {
    
    static let shared: MediaPickerManager = {
        print(#function)
        let mediaPickerManager = MediaPickerManager()
        mediaPickerManager.requestAuthorization()
        return mediaPickerManager
    }()
    
    var imageManager: PHCachingImageManager?
    var assetsFetchResults: PHFetchResult<PHAsset>?
    var dispatchGroup = DispatchGroup()
    
    private func requestAuthorization() {
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
            case .authorized, .limited:
                print("Good to proceed")
            case .denied, .restricted:
                print("Not allowed")
            case .notDetermined:
                print("Not determined yet")
            default:
                print("Not determined yet")
            }
            NotificationCenter.default.post(name: .mediaLibraryAccessChanged, object: nil, userInfo: nil)
        }
    }
    
    func loadData(type: PHAssetMediaType) {
        
        imageManager = PHCachingImageManager()
        
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.wantsIncrementalChangeDetails = true
        
        assetsFetchResults = PHAsset.fetchAssets(with: type, options: options)
    }
    
    func getPhoto(index: Int, cellSize: CGSize) -> UIImage? {
        
        guard let asset = self.assetsFetchResults?[index] else {
            return nil
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        var finalImage: UIImage?
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = true
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true
        
        imageManager?.requestImage(for: asset, targetSize: CGSize(width: cellSize.width * 3, height: cellSize.height * 3), contentMode: .aspectFill, options: options, resultHandler: { image, info in
            finalImage = image
            semaphore.signal()
        })
        
        semaphore.wait()
        return finalImage
        
    }
    
    func addPhoto(asset: PHAsset) {
        let imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.isSynchronous = true
        imageRequestOptions.isNetworkAccessAllowed = true
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .default,
            options: imageRequestOptions,
            resultHandler: { image, info in
                if let image = image {
                    NewMediaManager.shared.newMedia.insert(MediaModel(videoURL: nil, image: image, textViews: []), at: 0)
                }
            })
        
    }
    
    func addVideo(asset: PHAsset) {
        
        let videoRequestOptions = PHVideoRequestOptions()
        videoRequestOptions.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestAVAsset(forVideo: asset, options: videoRequestOptions) { avAsset, avAudioMix, data in
            guard let avUrlAsset = avAsset as? AVURLAsset else {
                return
            }
            
            let videoDuration = asset.duration
            let durationTime = ceil(videoDuration)
            print("durationTime:" , durationTime)
            struct Duration {
                let start: Double
                let end: Double
            }
            let durations: [Duration]
            if durationTime < 15 {
                durations = [Duration(start: 0, end: durationTime)]
            } else {
                durations = (0...Int(59)/15).compactMap {
                    if Double($0*15) == min(Double($0*15)+15, 59) {
                        return nil
                    }
                    return Duration(start: Double($0*15), end: min(Double($0*15)+15, 59))
                }
            }
            for index in durations.indices {
                self.dispatchGroup.enter()
                let startTime = durations[index].start
                let endTime = durations[index].end
                print("Start time = \(startTime) and Endtime = \(endTime)")
                DispatchQueue.main.async {
                    self.saveVideo(at: avUrlAsset.url, startTime: startTime, endTime: endTime, fileName: "Output-\(index)")
                }
            }
            
            self.dispatchGroup.notify(queue: .main) {
                NotificationCenter.default.post(name: .videoDone, object: nil)
            }
        }
    }
    
    func saveVideo(at url: URL, startTime: Double, endTime:Double, fileName: String) {
        let asset = AVURLAsset(url: url)
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHEVC1920x1080)!
        let outputURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent(fileName)
            .appendingPathExtension("mov")
        // Remove existing file
        if FileManager.default.fileExists(atPath: outputURL.path) {
            do {
                try FileManager.default.removeItem(at: outputURL)
            } catch {
                print(error)
            }
        }
        exportSession.outputURL = outputURL
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.outputFileType = .mp4
        let start = CMTimeMakeWithSeconds(startTime, preferredTimescale: 1)
        let duration = CMTimeMakeWithSeconds(endTime-startTime, preferredTimescale: 1)
        let range = CMTimeRangeMake(start: start, duration: duration)
        print("Will Render \(fileName) from \(start.seconds) to \(duration)")
        exportSession.timeRange = range
        exportSession.exportAsynchronously {
            print("Did Render \(fileName) from \(start.seconds) to \(duration)")
            self.dispatchGroup.leave()
            switch exportSession.status {
            case .completed:
//
                NewMediaManager.shared.newMedia.insert(MediaModel(videoURL: outputURL, image: self.getThumbnailImageFromVideoURL(fromUrl: outputURL), textViews: []), at: 0)
                
                NewMediaManager.shared.newMedia.sort { first, second in
                    return first.videoURL?.absoluteString ?? "" < second.videoURL?.absoluteString ?? ""
                }
                print("SAVED:", outputURL)
                
                break
            case .failed:
                print("Render failed with:", exportSession.error ?? "no error")
                break
            case .cancelled: break
            default: break
            }
        }
    }
    
    func getVideoDuration(index: Int) -> String {
        
        guard let asset = self.assetsFetchResults?[index] else {
            return "00:00"
        }
        
        let formatter = DateComponentsFormatter()
        formatter.calendar?.locale = Locale(identifier: "ru_RU")
        formatter.unitsStyle = .short
        return formatter.string(from: asset.duration) ?? "00:00"
        
    }
    
    func getThumbnailImageFromVideoURL(fromUrl url: URL) -> UIImage? {
        let asset: AVAsset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let thumbnailImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60) , actualTime: nil)
            return UIImage(cgImage: thumbnailImage)
        } catch let error {
            print(error)
        }

        return nil
    }
    
}
