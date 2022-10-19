//
//  CameraView.swift
//  FaceApp
//
//  Created by tmatsuda on 2022/10/19.
//

import SwiftUI

struct CameraView:UIViewRepresentable {
    func makeUIView( context: Context) -> some UIView { BaseCameraView() }
    func updateUIView(_ uiView: UIViewType, context: Context) {/* */}
}
