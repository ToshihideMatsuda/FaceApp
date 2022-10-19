//
//  FaceInfo.swift
//  FaceApp
//
//  Created by tmatsuda on 2022/10/19.
//
import SwiftUI
import Foundation

struct FaceInfo {
    let landmarks:[Landmark]
}

struct Landmark {
    let name:String
    let points:[CGPoint]

    init(name:String, points:[CGPoint], mainFrame:CGRect, faceframe:CGRect){
        let W  = mainFrame.width
        let H  = mainFrame.height
        let X  = mainFrame.origin.x
        let Y  = mainFrame.origin.y
        let bw = faceframe.size.width  * W
        let bh = faceframe.size.height * H
        let bx = (1-faceframe.origin.x) * W - bw
        let by = (1-faceframe.origin.y) * H - bh

        self.name = name
        self.points = points.map   { (x: (1-$0.x)  , y: (1-$0.y)) }  // 座標変換
                            .map   { (x: $0.x * bw ,y: $0.y * bh) }  // サイズ変更
                            .map   { (x: $0.x + bx ,y: $0.y + by) }  // 平行移動1
                            .map   { (x: $0.x + X  ,y: $0.y + Y)  }  // 平行移動2
                            .map   { CGPoint(x:$0.x,y:$0.y)       }  // create
                            //.filter{ (1 <= $0.x && $0.x <= W) && (1 <= $0.y && $0.y <= H) }

    }

}
