//
//  BaseCameraView.swift
//  FaceApp
//
//  Created by tmatsuda on 2022/10/19.
//

import AVFoundation
import Combine
import SwiftUI
import Vision

let baseCameraRedraw = "BaseCameraView.redraw"

class BaseCameraView:UIView, AVCaptureVideoDataOutputSampleBufferDelegate {

    let myQueue       = DispatchQueue.init(label: "vision")
    let overView:BaseCameraOverView = BaseCameraOverView()
    override func layoutSubviews() {
        super.layoutSubviews()
        _ = initCaptureSession

        (layer.sublayers?.first as? AVCaptureVideoPreviewLayer)?.frame = frame
        overView.backgroundColor = UIColor.clear
        overView.frame = self.frame;
        self.addSubview(overView)

        NotificationCenter.default.addObserver(forName: NSNotification.Name(baseCameraRedraw),
                                               object: nil,
                                               queue: nil,
                                               using: { _ in DispatchQueue.main.async {
            self.overView.setNeedsDisplay()
        } })
    }

    lazy var initCaptureSession: Void =
    {
        guard let device = AVCaptureDevice
            .DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
                              mediaType: .video,
                              position : .front)
            .devices
            .first(where:{ $0.position == .front }) else { return }

        guard let input = try? AVCaptureDeviceInput(device: device) else { return }

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue:myQueue)

        let session = AVCaptureSession()
        session.addInput(input)
        session.addOutput(output)

        // not main thread
        DispatchQueue.global().async{ session.startRunning() }

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspect

        guard let orientation = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.windowScene?.interfaceOrientation else { return }

        session.connections.forEach{
            
            $0.videoOrientation =   orientation == .landscapeLeft    ? .landscapeLeft :
                                    orientation == .landscapeRight   ? .landscapeRight :
                                    orientation == .portrait         ? .portrait :
                                    orientation == .portraitUpsideDown ? .portraitUpsideDown : $0.videoOrientation
        }
        layer.insertSublayer(preview, at: 0)

    }()
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) { }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixcelBuf = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let pixcelSize = CVImageBufferGetDisplaySize(pixcelBuf)
      
        DispatchQueue.main.sync {
            let frame:CGRect

            guard let orientation = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.windowScene?.interfaceOrientation else { return }

            if orientation == .portrait || orientation == .portraitUpsideDown { //縦向き
                let W = self.frame.height * pixcelSize.width/pixcelSize.height
                let H = self.frame.height
                frame = CGRect(x: (self.frame.width - W)/2, y: 0, width : W, height: H)
            } else { //横向き
                let W = self.frame.width
                let H = self.frame.width * pixcelSize.height/pixcelSize.width
                frame = CGRect(x: 0, y: (self.frame.height - H)/2, width : W, height: H)
            }
          
            let requests:[VNImageBasedRequest] = ContentView.shared?.facePointOn.value == true ? [VNFaceLandmarkRequest(frame:frame), VNFaceRectanglesRequest()] : []

            try? VNImageRequestHandler(cvPixelBuffer:pixcelBuf , options:[:])
                .perform(requests)
        }
    }
}


/*
* VNRequests
*
*/

extension BaseCameraView {
    
    func VNFaceLandmarkRequest(frame:CGRect) -> VNDetectFaceLandmarksRequest {
        return VNDetectFaceLandmarksRequest(){ request, error in
            if (error != nil)
            {
                print("FaceDetection error: \(String(describing: error)).")
                return ;
            }

            guard let results = request.results as? [VNFaceObservation] else { return }
        
            DispatchQueue.main.async {
                self.overView.faces = results.map { face in
                    return FaceInfo(landmarks:[
                        Landmark(name:"faceContour" , points: face.landmarks?.faceContour?.normalizedPoints ?? [], mainFrame: frame, faceframe: face.boundingBox),  // 輪郭
                        Landmark(name:"rightEyebrow", points: face.landmarks?.rightEyebrow?.normalizedPoints ?? [], mainFrame: frame, faceframe: face.boundingBox),  // 右眉
                        Landmark(name:"rightEye"  , points: face.landmarks?.rightEye?.normalizedPoints ?? [],   mainFrame: frame, faceframe: face.boundingBox),  // 右目
                        Landmark(name:"rightPupil" , points: face.landmarks?.rightPupil?.normalizedPoints ?? [],  mainFrame: frame, faceframe: face.boundingBox),  // 右瞳
                        Landmark(name:"leftEyebrow" , points: face.landmarks?.leftEyebrow?.normalizedPoints ?? [], mainFrame: frame, faceframe: face.boundingBox),  // 右眉
                        Landmark(name:"leftEye"   , points: face.landmarks?.leftEye?.normalizedPoints ?? [],   mainFrame: frame, faceframe: face.boundingBox),  // 右眉
                        Landmark(name:"leftPupil"  , points: face.landmarks?.leftPupil?.normalizedPoints ?? [],  mainFrame: frame, faceframe: face.boundingBox),
                        Landmark(name:"nose"    , points: face.landmarks?.nose?.normalizedPoints ?? [],     mainFrame: frame, faceframe: face.boundingBox),
                        Landmark(name:"noseCrest"  , points: face.landmarks?.noseCrest?.normalizedPoints ?? [],  mainFrame: frame, faceframe: face.boundingBox), // 鼻中央線と下線
                        Landmark(name:"medianLine" , points: face.landmarks?.medianLine?.normalizedPoints ?? [],  mainFrame: frame, faceframe: face.boundingBox), // 正中線
                        Landmark(name:"outerLips"  , points: face.landmarks?.outerLips?.normalizedPoints ?? [],  mainFrame: frame, faceframe: face.boundingBox),
                        Landmark(name:"innerLips"  , points: face.landmarks?.innerLips?.normalizedPoints ?? [],  mainFrame: frame, faceframe: face.boundingBox),
                    ])
                }
            }
        
            DispatchQueue.main.async {
                self.overView.setNeedsDisplay();
            }
        }
    }

   

    func VNFaceRectanglesRequest() -> VNDetectFaceRectanglesRequest {
        return VNDetectFaceRectanglesRequest(){ request, error in
            if (error != nil)
            {
                print("FaceDetection error: \(String(describing: error)).")
                return ;
            }
            guard let results = request.results as? [VNFaceObservation] else { return }
            for face in results {
                ContentView.shared?.setFaceRotateValue(roll:face.roll?.doubleValue ?? 0, yaw:face.yaw?.doubleValue ?? 0, pitch:face.pitch?.doubleValue ?? 0)
            }
        }
    }
}

class BaseCameraOverView : UIView {

    var faces:[FaceInfo] = []

    private let pointColorDic = [
        "rightPupil" : UIColor.red,
        "leftPupil" : UIColor.red,
    ]

    private let greenOpenLine = ["faceContour","noseCrest","medianLine"];

    override func draw(_ rect: CGRect) {

        if(ContentView.shared?.facePointOn.value == false) { return }

        for face in self.faces{
            for landmark in face.landmarks {
                let pointColor:UIColor = pointColorDic[landmark.name] ?? UIColor.yellow

                for p in landmark.points {

                    let arc = UIBezierPath()
                    arc.addArc(withCenter: CGPoint(x: p.x, y: p.y),
                               radius: 1,
                               startAngle: 0,
                               endAngle: Double.pi * 2,
                               clockwise: true)
                    
                    arc.lineWidth=2
                    pointColor.setStroke()
                    arc.stroke()
                }

                if(landmark.points.count >= 2)
                {

                    let path = UIBezierPath()
                    path.move(to:CGPoint(x:landmark.points[0].x,
                                         y:landmark.points[0].y))

                    for p in landmark.points {
                        if p == landmark.points[0] { continue }
                        path.addLine(to: CGPoint(x:p.x, y:p.y))
                    }
                    
                    if greenOpenLine.contains(landmark.name){
                        UIColor.green.setStroke()
                    } else {
                        path.close()
                        UIColor.blue.setStroke()
                    }
                    path.stroke()
                }
            }
        }
    }
}
