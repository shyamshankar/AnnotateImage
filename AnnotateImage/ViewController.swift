//
//  ViewController.swift
//  AnnotateImage
//
//  Created by Shyam Shankar on 12/30/21.
//  Features:
//      1. Capture an image
//      2. Mark a region using a highlighter
//          2.1. Pinch and Zoom to change size of the marker (highlighter)
//          2.2. Pan to move the marker (highlighter)
//      3. Save the marked image
//  To see what we write, it always saves the image locally with the same name.
//  Visually it can get messy, but helps verify things are working, to test that we can fallback on stock image just change savedImageName

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let savedImageName = "markedAndSaved.jpg"
    let imageView = UIImageView(image: UIImage(named: "stock"))
    let markerView: UIView = {
        let av = UIView()
        av.backgroundColor = .cyan
        av.backgroundColor = .cyan
        av.isOpaque = false
        av.alpha = 0.5
        return av
    }()
    
    
    let buttonTakePicture = UIButton(type: .roundedRect)
    let buttonSavePicture = UIButton(type: .roundedRect)
    
    let imagePickerController = UIImagePickerController()
            
    var dirty = false
    
    var minMarkerSize = CGFloat(100.0)
    var maxMarkerSize = CGFloat(300.0)
    
    // TODO: Will this work do I need to add special qualifiers for concurrency?
    var annotatorScaleStartSize = CGFloat(0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        imagePickerController.delegate = self
        imagePickerController.sourceType = .camera
        imagePickerController.cameraCaptureMode = .photo
        // imagePickerController.showsCameraControls = false

        view.backgroundColor = .black
        // Setting up imageView (auto-layout)
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        imageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        imageView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.9).isActive = true
        imageView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.9).isActive = true

        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        
        // Setting up annotator view
        imageView.addSubview(markerView)
        minMarkerSize = view.frame.width * 0.9 * 0.3
        maxMarkerSize = view.frame.width * 0.9 * 0.9
        markerView.frame = CGRect(x: 0, y: 0, width: minMarkerSize, height: minMarkerSize)
        markerView.clipsToBounds = true
        markerView.isUserInteractionEnabled = true
        markerView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture)))
        markerView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinchGesture)))
        
        
        // Setting up buttonTakePicture
        view.addSubview(buttonTakePicture)
        buttonTakePicture.setTitle("Take Picture", for: .normal)
        buttonTakePicture.translatesAutoresizingMaskIntoConstraints = false
        buttonTakePicture.leftAnchor.constraint(equalTo: imageView.leftAnchor).isActive = true
        buttonTakePicture.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        buttonTakePicture.heightAnchor.constraint(equalToConstant: view.frame.height * 0.075).isActive = true
        buttonTakePicture.widthAnchor.constraint(equalToConstant: view.frame.width * 0.3).isActive = true
        buttonTakePicture.addTarget(self, action: #selector(self.onTakePicture), for: .primaryActionTriggered)

        // Setting up buttonTakePicture
        view.addSubview(buttonSavePicture)
        buttonSavePicture.setTitle("Save Picture", for: .normal)
        buttonSavePicture.translatesAutoresizingMaskIntoConstraints = false
        buttonSavePicture.rightAnchor.constraint(equalTo: imageView.rightAnchor).isActive = true
        buttonSavePicture.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        buttonSavePicture.heightAnchor.constraint(equalToConstant: view.frame.height * 0.075).isActive = true
        buttonSavePicture.widthAnchor.constraint(equalToConstant: view.frame.width * 0.3).isActive = true
        buttonSavePicture.addTarget(self, action: #selector(self.onSavePicture), for: .primaryActionTriggered)
        
        let imageURL = documentDirectoryPath()?.appendingPathComponent(savedImageName)
        if imageURL != nil && FileManager.default.fileExists(atPath: imageURL!.relativePath){
            resetImageView(image: UIImage(contentsOfFile: imageURL!.path)!)
        } else {
            resetImageView(image: UIImage(named:"stock")!)
        }
    }
    
    @objc func onTakePicture(_ sender: UIButton) {
        // TODO: Check if the canvas is clean
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    @objc  func onSavePicture(_ sender: UIButton) {
        if dirty {
            let renderer = UIGraphicsImageRenderer(size: imageView.bounds.size)
            // TODO: Improve to only clip the portion of the image
            let image = renderer.image { ctx in
                imageView.drawHierarchy(in: imageView.bounds, afterScreenUpdates: true)
            }
            
            if let jpgData = image.jpegData(compressionQuality: 0.5),
               let path = documentDirectoryPath()?.appendingPathComponent(savedImageName) {
                try? jpgData.write(to: path)
            }
            
            dirty = false
        } else {
            flashAlertBox(title: "Info", message: "No changes to save")
        }
    }
        
    // Completion handler
    @objc func onSaveCompletion(_ image: UIImage, didFinishSavingWithError: Error?, contextInfo: UnsafeRawPointer) {
        if didFinishSavingWithError != nil {
            flashAlertBox(title: "Error", message: "Could not save image. Please make sure you allow saving photos!")
        } else {
            flashAlertBox(title: "Image Saved", message: "Image was saved successfully")
        }
    }

    
    @objc func handleSizerChange(_ sender: UISlider!) {
        let oldCenter = markerView.center
        markerView.frame.size.width =  CGFloat(sender.value) * (imageView.frame.size.width * 0.1)
        markerView.frame.size.height = CGFloat(sender.value) * (imageView.frame.size.width * 0.1)
        markerView.center = oldCenter
    }
    
    @objc func handlePanGesture(gesture: UIPanGestureRecognizer) {
        centerAndZoom(expectedCenter: gesture.location(in: imageView), expectedSize: markerView.frame.size.width)
    }
    
    @objc func handlePinchGesture(gesture: UIPinchGestureRecognizer) {
        if (gesture.state == .began) {
            annotatorScaleStartSize = markerView.frame.size.width
        }
        if (gesture.state == .changed) {
            centerAndZoom(expectedCenter: markerView.center, expectedSize: annotatorScaleStartSize * gesture.scale)
        }
    }
    
    // UIImagePickerControllerDelegate impl
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        
        // Set the image on the UIImageView
        resetImageView(image: image)
        dirty = true
        picker.dismiss(animated: true, completion: nil)
    }
    
    // Utils
    func centerAndZoom(expectedCenter: CGPoint, expectedSize: CGFloat) {
        dirty = true
        var adjustedSize = expectedSize
        if expectedSize < minMarkerSize {
            adjustedSize = minMarkerSize
        } else if expectedSize > maxMarkerSize {
            adjustedSize = maxMarkerSize
        }
        let halfAdjustedSize = adjustedSize / 2
        
        var adjustedCenterX = expectedCenter.x
        if (expectedCenter.x - halfAdjustedSize) < 0 {
            adjustedCenterX = halfAdjustedSize
        } else if (expectedCenter.x + halfAdjustedSize) > imageView.frame.size.width {
            adjustedCenterX = imageView.frame.size.width - halfAdjustedSize
        }
        
        var adjustedCenterY = expectedCenter.y
        if (expectedCenter.y - halfAdjustedSize) < 0 {
            adjustedCenterY = halfAdjustedSize
        } else if (expectedCenter.y + halfAdjustedSize) > imageView.frame.size.height {
            adjustedCenterY = imageView.frame.size.height - halfAdjustedSize
        }
        
        markerView.frame = CGRect(x: adjustedCenterX - halfAdjustedSize, y: adjustedCenterY - halfAdjustedSize, width: adjustedSize, height: adjustedSize)
    }
        
    func resetImageView(image: UIImage) {
        imageView.image = image
    }
    
    func flashAlertBox(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func documentDirectoryPath() -> URL? {
        let path = FileManager.default.urls(for: .documentDirectory,
                                            in: .userDomainMask)
        return path.first
    }
}
