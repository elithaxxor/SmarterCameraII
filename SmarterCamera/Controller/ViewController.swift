//
//  ViewController.swift
//  SmarterCamera
//
//  Created by a-robota on 5/2/22.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    
    ///[image picker for camera library]
    let imagePicker = UIImagePickerController()
    // let cameraPicker = UIImagePickerController()
    
    @IBOutlet weak var UIImageView: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /// [camera capture session]
        let AVObj = AVCaptureSession()
        
        
        
        
        AVObj.sessionPreset = .photo
        imagePicker.sourceType = .photoLibrary // for accessing user photo library
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
        
        //        cameraPicker.sourceType = .camera
        //        cameraPicker.delegate = self
        //        cameraPicker.allowsEditing = true
        //
        guard let camera = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: camera) else { return }
        
        AVObj.addInput(input)
        AVObj.startRunning()
        
        /// [capture views]-> ports screencapture to UI
        let previewLayer = AVCaptureVideoPreviewLayer(session: AVObj)
        
        
        view.layer.addSublayer(previewLayer)
        // view.addSubview(previewLayer)
        previewLayer.frame = view.frame
        
        /// [to read captured data]
        
        let capturedDataOBJ = AVCaptureVideoDataOutput()
        capturedDataOBJ.setSampleBufferDelegate(self, queue: DispatchQueue(label:"videoQueue"))
        AVObj.addOutput(capturedDataOBJ)
        
        // VNImageRequestHandler(cgImage: capturedDataOBJ as! CGImage, options: [:]).perform([request])
        // let cameraRequest = VNCoreMLRequest(model: VNCoreMLModel, completionHandler: VNRequestCompletionHandler?)
        
        // captureOutput(<#T##output: AVCaptureOutput##AVCaptureOutput#>, didOutput: <#T##CMSampleBuffer#>, from: <#T##AVCaptureConnection#>)
        
        //
        //        VNImageRequestHandler(cgImage: CGImage, options: [:]).perform(requests: [VNRequest])
        //
    }
    
    
    // ''' START OF CAMERA ACTION/VIEWS
    @IBAction func cameraBtn(_ sender: UIButton) {
        // let value = "[!] Error with Camera Btn"
        
        print("[Camera Btn Pressed] \(Date())")
        //  present(cameraPicker, animated: true, completion: nil)
        
    }
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection){
        print("[Frame Captured] \(Date())")
        
        //        CMSampleBufferGetImageBuffer(CMSampleBuffer.self as! CMSampleBuffer)
        //        print( CMSampleBufferGetImageBuffer(CMSampleBuffer.self as! CMSampleBuffer))
        //
        
        // [SETUP MODELS]
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            //fatalError("[Error in pixelBufferm] --> captureOutput function")
            return
        }
        print("pixlebuffer setup")
        
        guard let captureModel = try? VNCoreMLModel(for: Inceptionv3().model) else {
            // fatalError(" func[detect] Error in Createing Models from CII-IMAGE")
            return
        }
        
        print("capture model setup")
        
        let request = VNCoreMLRequest(model: captureModel) {
            (req, error ) in
            
            if let error = error {
                print("Error in Camera request \(error)")
            }
            
            print(req)
        }
        
        guard let results = request.results as? [VNClassificationObservation] else { return }
        guard let firstObservation = results.first else { return }
        
        
        
        print("[first capture ID] ->  \(firstObservation.identifier)")
        print("[request.results] \(String(describing: request.results))")
        print("[capture first observation] \(firstObservation)")
        print("[capture first observation]--> DESCRIPTION  \(firstObservation.description)")
        print("XXXXXXXXXX")
        print("[capture accuracy results] \(firstObservation.confidence)")
        
        //   guard let ciimage = CIImage(image:  pixelBuffer) else {
        
        //  let handler = VNImageRequestHandler(ciImage: ciimage) // [passed as func args]
        do {
            try VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
            //try VNImageRequestHandler(cgImage: CGImage.self as! CGImage, options: [:]).perform([request])
        } catch let error {
            print("error in [Capture Request Handler] \(error)")
            
        }
    }
    // [INSERT--> TO DISPLAY RESULTS ON NAV BAR]
    // navigationItem.titleView =
    
    //        imagePicker.dismiss(animated: true, completion: nil)
    //        detect(image: ciimage)
    //
    
    
    // ''' START OF CAMERA-LIBRARY CONTROLLER/DELEGATE
    
    /// doc://com.apple.documentation/documentation/uikit/uiimagepickercontroller/sourcetype/photolibrary?language=swift
    @IBAction func libraryBtn(_ sender: UIButton) {
        print("[Library Btn Pressed]")
        present(imagePicker, animated: true, completion: nil)
        
    }
    
    ///[controller for camera library] --> access
    private func imagePickerControllerDidCancel(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any?]) {
        print("[User Chose Library]")
        if let libraryImage = info [UIImagePickerController.InfoKey.originalImage.rawValue] as? UIImage {
            UIImageView.image = libraryImage
            guard let ciimage = CIImage(image:  libraryImage) else {
                fatalError("[Error in parsing (USER-LIBRARY] CII-IMAGE] ")
            }
            // imagePicker.perFormSegue(
            imagePicker.dismiss(animated: true, completion: nil)
            detect(image: ciimage)
            
        }
    }
    
    func detect(image: CIImage) {
        
        enum myError: Error {
            case error
        }
        
        guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else {
            fatalError(" func[detect] Error in Createing Models from CII-IMAGE")
        }
        ///[model processing]
        let request = VNCoreMLRequest(model: model) { (request, error )  in
            
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Unable to process model")
            }
            print("[MODEL RESULS] \(results)")
            
            
            // [INSERT--> TO DISPLAY RESULTS ON NAV BAR]
            
            
            
            // [MODEL-CLASSIFICATION]
            let handler = VNImageRequestHandler(ciImage: image) // [passed as func args]
            DispatchQueue.global(qos: .background).async {
                
                do {
                    // // call to above reqeust ^
                    try handler.perform([request])
                    
                } catch {
                    print("Error caught in [model-classification] error \(error)")
                }
                
            }
        }
        
    }
}

