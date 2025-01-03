//
//  ViewController.swift
//  Project13
//
//  Created by Maksim Li on 24/12/2024.
//

import CoreImage
import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var intensity: UISlider!
    @IBOutlet var changeFilterButton: UIButton!
    @IBOutlet var radiusSlider: UISlider!
    
    var currentImage: UIImage!
    var context: CIContext!
    var currentFilter: CIFilter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Instafilter"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(importPicture))
        
        context = CIContext()
        guard CIFilter(name: "CISepiaTone") != nil else {
            fatalError("Unable to create CISepiaTone filter")
        }
        currentFilter = CIFilter(name: "CISepiaTone")
        intensity.value = intensity.minimumValue
        radiusSlider.value = radiusSlider.minimumValue
    }
    
    @objc func importPicture() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage else {
            let ac = UIAlertController(title: "Loading Error", message: "Unable to load the selected image.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            return
        }
        
        dismiss(animated: true)
        currentImage = image
        
        let beginImage = CIImage(image: currentImage)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        applyProcessing()
    }
    
    
    @IBAction func changeFilter(_ sender: UIButton) {
        let ac = UIAlertController(title: "Choose Filter", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "CIBumpDistortion", style: .default, handler: setFilter))
        ac.addAction(UIAlertAction(title: "CIGaussianBlur", style: .default, handler: setFilter))
        ac.addAction(UIAlertAction(title: "CIPixellate", style: .default, handler: setFilter))
        ac.addAction(UIAlertAction(title: "CISepiaTone", style: .default, handler: setFilter))
        ac.addAction(UIAlertAction(title: "CITwirlDistortion", style: .default, handler: setFilter))
        ac.addAction(UIAlertAction(title: "CIUnsharpMask", style: .default, handler: setFilter))
        ac.addAction(UIAlertAction(title: "CIVignette", style: .default, handler: setFilter))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popoverPresentationController = ac.popoverPresentationController {
            popoverPresentationController.sourceView = sender
            popoverPresentationController.sourceRect = sender.bounds
        }
        
        present(ac, animated: true)
    }
    
    func setFilter(action: UIAlertAction) {
        guard currentImage != nil else {
            let ac = UIAlertController(title: "No Image", message: "Please load an image first.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            return
        }
        
        guard let actionTitle = action.title else { return }
        guard let filter = CIFilter(name: actionTitle) else {
            let ac = UIAlertController(title: "Filter Error", message: "Unable to create filter.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            return
        }
        currentFilter = filter
        currentFilter.setDefaults()
        
        changeFilterButton.setTitle(actionTitle, for: .normal)
        
        let beginImage = CIImage(image: currentImage)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        applyProcessing()
    }
    
    @IBAction func save(_ sender: Any) {
        guard let image = imageView.image else {
            let ac = UIAlertController(title: "Save Error", message: "There is no image to save. Please select and edit an image first.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            return
        }
        
        let loadingAC = UIAlertController(title: nil, message: "Saving...", preferredStyle: .alert)
        loadingAC.view.tag = 100 
        present(loadingAC, animated: true)
        
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        view.window?.viewWithTag(100)?.removeFromSuperview()
        
        if let error = error {
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    @IBAction func intensityChanged(_ sender: Any) {
        guard currentImage != nil else { return }
        let intensityValue = intensity.value
        updateIntensity(intensityValue)
        applyProcessing()
    }
    
    
    @IBAction func radiusChanged(_ sender: Any) {
        guard currentImage != nil else { return }
        let radiusValue = radiusSlider.value
        updateRadius(radiusValue)
        applyProcessing()
    }
    
    
    func updateIntensity(_ value: Float) {
        guard let inputKeys = currentFilter?.inputKeys,
              inputKeys.contains(kCIInputIntensityKey) else { return }
        
        currentFilter.setValue(value, forKey: kCIInputIntensityKey)
    }
    
    func updateRadius(_ value: Float) {
        guard let inputKeys = currentFilter?.inputKeys,
              inputKeys.contains(kCIInputRadiusKey) else { return }
        
        let radiusValue = value * 200
        currentFilter.setValue(radiusValue, forKey: kCIInputRadiusKey)
    }
    
    func applyProcessing() {
        guard let inputKeys = currentFilter?.inputKeys,
              let beginImage = CIImage(image: currentImage) else { return }
        
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        
        if inputKeys.contains(kCIInputIntensityKey) {
            currentFilter.setValue(intensity.value, forKey: kCIInputIntensityKey)
        }
        
        if inputKeys.contains(kCIInputScaleKey) {
            currentFilter.setValue(intensity.value * 10, forKey: kCIInputScaleKey)
        }
        
        if inputKeys.contains(kCIInputCenterKey) {
            currentFilter.setValue(CIVector(x: currentImage.size.width / 2, y: currentImage.size.height / 2), forKey: kCIInputCenterKey)
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self,
                  let outputImage = self.currentFilter.outputImage,
                  let cgImage = self.context.createCGImage(outputImage, from: outputImage.extent) else { return }
            
            let processedImage = UIImage(cgImage: cgImage)
            
            DispatchQueue.main.async {
                self.imageView.image = processedImage
            }
        }
    }
}
