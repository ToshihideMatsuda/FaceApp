//
//  ContentView.swift
//  FaceApp
//
//  Created by tmatsuda on 2022/10/19.
//

import SwiftUI

import AVFoundation

import Vision

import Combine


struct ContentView: View {

    static var shared: ContentView?
    @State var faceRotate:String = ""
    @State var facePointOn:CurrentValueSubject<Bool,Never> = CurrentValueSubject<Bool,Never>(false)
    @State var cancellables: [AnyCancellable] = []

    var body: some View {
        VStack {
            VStack {
                VStack(alignment: .leading) {
                    Text(faceRotate).frame(width: 300, alignment: .leading)
                 }.frame(width: 300)
                Toggle("Face Point On", isOn: $facePointOn.value).frame(width: 180)
             }.frame(height: 160)
            
            CameraView()
                .onAppear(perform: {
                    setFaceRotateValue()
                    ContentView.shared = self
                    self.facePointOn
                            .receive(on: DispatchQueue.main)
                            .sink(
                                receiveCompletion: { _ in },
                                receiveValue: {  _  in
                                    NotificationCenter.default.post(name: NSNotification.Name(baseCameraRedraw), object: nil)
                             } )
                            .store(in: &cancellables)
                 })
        }
    }

    public func setFaceRotateValue(roll:Double=0.0, yaw:Double=0.0, pitch:Double=0.0) {
        faceRotate = String(format:"顔の回転情報\n " +
                             " 前後軸[-π,π)\t\t: %.4f \n" +
                             " 左右軸[-π/2,π/2]\t: %.4f \n" +
                             " 上下軸[-π/2,π/2]\t: %.4f ", roll, yaw, pitch)
    }
}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
