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
                
                let drawCtxt = UIGraphicsGetCurrentContext()
                CGContextSetLineWidth(drawCtxt, 30.0)
                
                //The rectangle is in the coordinate system of the image.
                var faceRect = (feature as CIRectangleFeature).bounds
                
                //ci image left bottom is (0,0)
                faceRect.origin.y = testImage.size.height - faceRect.origin.y - faceRect.size.height
                
                print("kaka af faceRect = \(faceRect)")
                
                let fixedTestImage = fixOrientation(testImage)
                let rectImage = self.cropImage(fixedTestImage, crop: faceRect)
                
                croppedImageView.image = self.detectFace(rectImage)
                
                CGContextSetStrokeColorWithColor(drawCtxt, UIColor.redColor().CGColor)
                CGContextStrokeRect(drawCtxt,faceRect)
            }
            
            drawedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
        }
        return drawedImage!
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
    
    func meetAspectRatio(size : CGSize) -> Bool {
        print("kaka, faceRect size \(size)")
        
        var ratio : CGFloat
        
        if size.height > size.width {
            ratio = size.height/size.width
        } else {
            ratio = size.width/size.height
        }
        
        print("kaka, ratio \(ratio)")
        
        // from 1.423 to 1.8
        if ratio >= 1.423 && ratio <= 1.8 {
            print("kaka, got! ")
            return true
        }
        
        return false
    }
    
    func cropImage(original: UIImage, crop : CGRect) -> UIImage {
        
        let cgImage = CGImageCreateWithImageInRect(original.CGImage, crop)
        
        let image: UIImage = UIImage(CGImage: cgImage!, scale: 1, orientation: original.imageOrientation)
        
        print("kaka cropImage = \(image.size)")
        
        return image
    }
    
    func detectFace(testImage : UIImage) -> UIImage {
        var drawedImage  = UIImage(named: "error")
        
        if let ciImage = CIImage(image :testImage) {
            
            faceCIDector = CIDetector(ofType:CIDetectorTypeFace
                ,context:nil
                ,options:[
                    CIDetectorAccuracy:CIDetectorAccuracyHigh,
                ]
            )

            let features = faceCIDector.featuresInImage(ciImage)
            
            //This line of code creates a new image context with the same size as testImage.
            UIGraphicsBeginImageContext(testImage.size)
            
            testImage.drawInRect(CGRectMake(0,0,testImage.size.width,testImage.size.height))
            
            for feature in features as! [CIFaceFeature]{
                let drawCtxt = UIGraphicsGetCurrentContext()
                CGContextSetLineWidth(drawCtxt, 10.0)
                
                //The rectangle is in the coordinate system of the image.
                var faceRect = (feature as CIFaceFeature).bounds
                
                //ci image left bottom is (0,0)
                faceRect.origin.y = testImage.size.height - faceRect.origin.y - faceRect.size.height
                
                CGContextSetStrokeColorWithColor(drawCtxt, UIColor.redColor().CGColor)
                CGContextStrokeRect(drawCtxt,faceRect)
            }
            
             timeTestField.text = timeTestField.text! + ", face count : \(features.count)"
            
            drawedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        return drawedImage!
    }
    
    //From http://fanyinan.me/%E6%B5%85%E8%B0%88UIImageOrientation(%E4%B8%80)/
    func fixOrientation(image: UIImage) -> UIImage {
        
        let imageRef = image.CGImage
        let width = image.size.width
        let height = image.size.height
        
        //创建一个位图上下文，具体用法在这不是关键
        let ctx = CGBitmapContextCreate(nil, Int(width), Int(height),
                                        CGImageGetBitsPerComponent(imageRef), 0,
                                        CGImageGetColorSpace(imageRef),
                                        CGImageGetBitmapInfo(imageRef).rawValue)
        
        //这个方法的作用是在这个上下文中所有绘制出来的东西都按照这个transform来变换，也可以看作是直接变换坐标系。
        //关键的getFixTransform方法在下面讲
        CGContextConcatCTM(ctx, getFixTransform(image))
        
        switch (image.imageOrientation) {
        case .Left, .LeftMirrored, .Right, .RightMirrored:
            
            //最后来绘制image，如果是Left或 Right的当然要取旋转90度之后的width和height
            CGContextDrawImage(ctx, CGRectMake(0, 0, height, width), imageRef)
        default:
            CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), imageRef)
        }
        
        let fixImageRef = CGBitmapContextCreateImage(ctx)
        
        //这里记得不要将原图片的imageOrientation再设回来，否则imageview又会自动调整方向了
        let fixImage = UIImage(CGImage: fixImageRef!)
        return fixImage
        
    }
    
    func getFixTransform(image: UIImage) -> CGAffineTransform {
        
        var transform = CGAffineTransformIdentity
        let width = image.size.width
        let height = image.size.height
        
        //调整图片的位置和方向
        switch (image.imageOrientation) {
        case .Down, .DownMirrored:
            transform = CGAffineTransformTranslate(transform, width, height)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI))
        case .Left, .LeftMirrored:
            transform = CGAffineTransformTranslate(transform, width, 0)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI_2))
        case .Right, .RightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, height)
            transform = CGAffineTransformRotate(transform, CGFloat(-M_PI_2))
        default: // .Up, .UpMirrored:
            break
        }
        
        //处理Mirrored的情况
        switch (image.imageOrientation) {
        case .UpMirrored, .DownMirrored:
            transform = CGAffineTransformTranslate(transform, width, 0)
            transform = CGAffineTransformScale(transform, -1, 1)
        case .LeftMirrored, .RightMirrored:
            transform = CGAffineTransformTranslate(transform, height, 0)
            transform = CGAffineTransformScale(transform, -1, 1)
        default: // .Up, .Down, .Left, .Right
            break
        }
        
        return transform
    }
}

