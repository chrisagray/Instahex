//
//  CameraViewController.swift
//  Color Picker
//
//  Created by Chris Gray on 1/9/18.
//  Copyright © 2018 Chris Gray. All rights reserved.
//

import UIKit

class CameraViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate {
    
    @IBOutlet weak var colorBarButton: UIBarButtonItem!
    @IBOutlet weak var hexBarButton: UIBarButtonItem!
    @IBOutlet weak var rgbBarButton: UIBarButtonItem!
    @IBOutlet weak var pixelTargetView: PixelTargetView!
    @IBOutlet weak var loadImageButton: UIButton!
    
    private var backgroundImageView = UIImageView()
    private let reader = ImagePixelReader()
    private let minimumZoomScale = 0.25
    private let maximumZoomScale = 1.0
    
    private var centerColor = HexColor()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.bringSubview(toFront: loadImageButton)
        pixelTargetView.isHidden = true
    }
    
    @IBAction func copyColor(_ sender: UIBarButtonItem) {
        UIPasteboard.general.string = centerColor.hexValue
    }
    
    
    //MARK: - Image
    
    private var centerPixelLocation: CGPoint! {
        return CGPoint(x: Int((scrollView.contentOffset.x)/scrollView.zoomScale), y: Int((scrollView.contentOffset.y)/scrollView.zoomScale))
    }
    
    private var userChosePhoto = false {
        didSet {
            loadImageButton.isHidden = true
            pixelTargetView.isHidden = false
            view.bringSubview(toFront: pixelTargetView)
        }
    }
    
    private var backgroundImage: UIImage? {
        didSet {
            if !userChosePhoto {
                userChosePhoto = true
            }
            reader.image = backgroundImage!.fixOrientation()
            
            backgroundImageView.image = backgroundImage
            backgroundImageView.sizeToFit()
            setContentSizes()
        }
    }
    
    private func setContentSizes() {
        scrollView.zoomScale = 0.25
        scrollView.contentSize = CGSize(width: backgroundImageView.frame.width + scrollView.frame.width, height: backgroundImageView.frame.height + scrollView.frame.height)
        backgroundImageView.frame = CGRect(x: scrollView.frame.width/2, y: scrollView.frame.height/2, width: backgroundImageView.frame.width, height: backgroundImageView.frame.height)
        
        scrollView.contentOffset.x = (backgroundImage!.size.width/2)*scrollView.zoomScale
        scrollView.contentOffset.y = (backgroundImage!.size.height/2)*scrollView.zoomScale
    }
    
    private func getColorFromCenter() {
        //dividing scollView's offsets by the zoomScale if we're zoomed in/out
        
        if (centerPixelLocation.x >= 0 && centerPixelLocation.x < backgroundImage!.size.width) && (centerPixelLocation.y >= 0 && centerPixelLocation.y < backgroundImage!.size.height) {
            if let color = reader.getColorFromPixel(centerPixelLocation) {
                centerColor.uiColor = color
            }
        } else {
            centerColor.uiColor = .white
        }
        
        colorBarButton.tintColor = centerColor.uiColor
        hexBarButton.title = "#\(centerColor.hexValue)"
        
        let (red, green, blue, _) = centerColor.rgbValues
        
        let rgbIntValues = (Int(red*255), Int(green*255), Int(blue*255))
        rgbBarButton.title = String(describing: rgbIntValues)
    }
    
    //MARK: - Scroll View
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.delegate = self
            scrollView.minimumZoomScale = 0.25
            scrollView.maximumZoomScale = 1.5
            scrollView.addSubview(backgroundImageView)
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return backgroundImageView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        scrollView.contentSize = CGSize(width: backgroundImageView.frame.width + scrollView.frame.width, height: backgroundImageView.frame.height + scrollView.frame.height)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        getColorFromCenter()
    }
    
    //MARK: - Camera
    
    private var cameraIsAvailable: Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    private var photoLibraryIsAvailable: Bool {
        return UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
    }
    
    @IBOutlet weak var cameraButton: UIBarButtonItem! {
        didSet {
            cameraButton.isEnabled = cameraIsAvailable || photoLibraryIsAvailable
        }
    }
    
    @IBAction func presentPhotoActionSheet(_ sender: Any) {
        let photoActionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if cameraIsAvailable {
            photoActionSheet.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { _ in
                self.takePhoto()
            }))
        }
        if photoLibraryIsAvailable {
            photoActionSheet.addAction(UIAlertAction(title: "Choose Photo", style: .default, handler: { _ in
                self.choosePhoto()
            }))
        }
        photoActionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            photoActionSheet.dismiss(animated: true)
        }))
        present(photoActionSheet, animated: true)
    }
    
    private func takePhoto() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        present(picker, animated: true)
    }

    private func choosePhoto() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    //MARK: - ImagePickerController
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
    
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true)
        if let image = (info[UIImagePickerControllerEditedImage] as? UIImage ?? info[UIImagePickerControllerOriginalImage]) as? UIImage {
            backgroundImage = image
        }
        getColorFromCenter()
    }
}
