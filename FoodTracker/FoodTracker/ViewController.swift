import UIKit

class ViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var mealNameLabel: UILabel!
    
    @IBOutlet weak var timeTestField: UILabel!
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var croppedImageView: UIImageView!
    
    var selectedImage : UIImage!
    
    var rectCIDector : CIDetector!
    var faceCIDector : CIDetector!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        //Hide the keyboard
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        mealNameLabel.text = textField.text
    }

    // MARK: UIImagePickerControllerDelegate
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        // Dismiss the picker if the user canceled.
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        // The info dictionary contains multiple representations of the image, and this uses the original.
        selectedImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        // Set photoImageView to display the selected image.
        photoImageView.image = selectedImage
        
        // Dismiss the picker.
        dismissViewControllerAnimated(true, completion: nil)
        
        testDetection()
    }
    
    func testDetection() {
        
        photoImageView.image = detectRect(selectedImage!)

        let img = performRectangleDetection(CIImage(image :selectedImage)!)
        if img != nil {
            print("performRectangleDetection done, img size:\(img?.extent)")
            photoImageView.image? = UIImage(CIImage: img!)
        }
    }
    
    func detectRect(testImage : UIImage) -> UIImage {
        var drawedImage  = UIImage(named: "error")
        
        let h = testImage.size.height
        let w = testImage.size.width
        
        mealNameLabel.text = "h = \(h) , w = \(w)"
        
        if let ciImage = CIImage(image :testImage) {
            
            rectCIDector = CIDetector(ofType:CIDetectorTypeRectangle
                ,context:nil
                ,options:[
                    CIDetectorAccuracy:CIDetectorAccuracyHigh,
                    //CIDetectorAspectRatio:1.667,
                    //CIDetectorFocalLength:0.0
                ]
            )
            
            let start = CACurrentMediaTime()
            let features = rectCIDector.featuresInImage(ciImage)
            let end = CACurrentMediaTime()
            let executionTimeInterval = end - start
            let exetime = String(format: "%.3f", executionTimeInterval)
            
            timeTestField.text = "time : \(exetime) , rect count : \(features.count)"
            
            //This line of code creates a new image context with the same size as testImage.
            UIGraphicsBeginImageContext(testImage.size)
            
            testImage.drawInRect(CGRectMake(0,0,testImage.size.width,testImage.size.height))
            
            if features.count == 0 {
                croppedImageView.image = UIImage(named: "default")
            }
            
            for feature in features as! [CIRectangleFeature]{
                
                //let drawCtxt = UIGraphicsGetCurrentContext()
                //CGContextSetLineWidth(drawCtxt, 30.0)
                
                //The rectangle is in the coordinate system of the image.
                var faceRect = (feature as CIRectangleFeature).bounds
                
                //ci image left bottom is (0,0)
                faceRect.origin.y = testImage.size.height - faceRect.origin.y - faceRect.size.height
                
                print("kaka af faceRect = \(faceRect)")
                
                let rectImage = ciImage.imageByCroppingToRect(feature.bounds)
                
                croppedImageView.image = UIImage(CIImage: self.detectFace(rectImage))
                //croppedImageView.image = UIImage(CIImage: rectImage)
                
                //CGContextSetStrokeColorWithColor(drawCtxt, UIColor.redColor().CGColor)
                //CGContextStrokeRect(drawCtxt,faceRect)
            }
            
            drawedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
        }
        return drawedImage!
    }
    
    func performRectangleDetection(image: CIImage) -> CIImage? {
        var resultImage: CIImage?
        
            // Get the detections
            let features = rectCIDector.featuresInImage(image)
            for feature in features as! [CIRectangleFeature] {
                resultImage = drawHighlightOverlayForPoints(image, topLeft: feature.topLeft, topRight: feature.topRight,
                                                            bottomLeft: feature.bottomLeft, bottomRight: feature.bottomRight)
            }
        
        return resultImage
    }
    
    func drawHighlightOverlayForPoints(image: CIImage, topLeft: CGPoint, topRight: CGPoint,
                                       bottomLeft: CGPoint, bottomRight: CGPoint) -> CIImage {
        var overlay = CIImage(color: CIColor(red: 1.0, green: 0, blue: 0, alpha: 0.5))
        overlay = overlay.imageByCroppingToRect(image.extent)
        overlay = overlay.imageByApplyingFilter("CIPerspectiveTransformWithExtent",
                                                withInputParameters: [
                                                    "inputExtent": CIVector(CGRect: image.extent),
                                                    "inputTopLeft": CIVector(CGPoint: topLeft),
                                                    "inputTopRight": CIVector(CGPoint: topRight),
                                                    "inputBottomLeft": CIVector(CGPoint: bottomLeft),
                                                    "inputBottomRight": CIVector(CGPoint: bottomRight)
            ])
        return overlay.imageByCompositingOverImage(image)
    }
        
    //MARK: Actions
    @IBAction func setDefaultLabelText(sender: UIButton) {
        mealNameLabel.text = "Default Text"
    }
    
    @IBAction func selectImageFromPhotoLibrary(sender: UITapGestureRecognizer) {
        //Hide the keyboard
        //nameTextField.resignFirstResponder()
        
        // UIImagePickerController is a view controller that lets a user pick media from their photo library.
        let imagePickerController = UIImagePickerController()
        
        // Only allow photos to be picked, not taken.
        imagePickerController.sourceType = .PhotoLibrary
    
        // Make sure ViewController is notified when the user picks an image.
        imagePickerController.delegate = self
        
        presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    func detectFace(ciImage: CIImage) -> CIImage {
        
        if(faceCIDector == nil) {
            faceCIDector = CIDetector(ofType:CIDetectorTypeFace
                ,context:nil
                ,options:[
                    CIDetectorAccuracy:CIDetectorAccuracyHigh,
                ]
            )
        }

        // Get the detections
        let features = faceCIDector.featuresInImage(ciImage)
        print("Face count:\(features.count)")
        for feature in features as! [CIFaceFeature] {
            print("Find face:\(feature.bounds) / \(ciImage.extent)")
            
            let topLeft = CGPoint(x: feature.bounds.origin.x, y: feature.bounds.origin.y)
            let topRight = CGPoint(x: feature.bounds.origin.x + feature.bounds.width, y: feature.bounds.origin.y)
            let bottomLeft = CGPoint(x: feature.bounds.origin.x, y: feature.bounds.origin.y + feature.bounds.height)
            let bottomRight = CGPoint(x: feature.bounds.origin.x + feature.bounds.width, y: feature.bounds.origin.y)
            
            var overlay = CIImage(color: CIColor(red: 1.0, green: 0, blue: 0, alpha: 0.5))
            overlay = overlay.imageByCroppingToRect(ciImage.extent)
            overlay = overlay.imageByApplyingFilter("CIPerspectiveTransformWithExtent",
                                                    withInputParameters: [
                                                        "inputExtent": CIVector(CGRect: ciImage.extent),
                                                        "inputTopLeft": CIVector(CGPoint: topLeft),//feature.bounds.origin),
                                                        "inputTopRight": CIVector(CGPoint: topRight),
                                                        "inputBottomLeft": CIVector(CGPoint: bottomLeft),
                                                        "inputBottomRight": CIVector(CGPoint: bottomRight)
                ])
            return overlay.imageByCompositingOverImage(ciImage)
        }
        
        return ciImage
    }
}

