//
//  Side.swift
//  JengaAR
//
//  Created by Nicholas Grana on 3/17/18.
//  Copyright © 2018 Nicholas Grana. All rights reserved.
//

import SceneKit
import ARKit

enum Side: Int {
    
    case north
    case south
    case east
    case west
    case top
    
    static func relativeSide(cameraPosition pos: SCNVector3, clickedSide: Int) -> Side {
        let orientations = orientationsFrom(cameraPosition: pos)
        
        if orientations.n == clickedSide {
            return .north
        } else if orientations.e == clickedSide {
            return .east
        } else if orientations.s == clickedSide {
            return .south
        } else if orientations.w == clickedSide {
            return .west
        }
        return .north
    }
    
    static func orientationsFrom(cameraPosition pos: SCNVector3) -> (n: Int, e: Int, s: Int, w: Int) {
        let left = SCNVector3(-30, pos.y, 0).distance(to: pos)
        let right = SCNVector3(30, pos.y, 0).distance(to: pos)
        let back = SCNVector3(0, pos.y, 30).distance(to: pos)
        let front = SCNVector3(0, pos.y, -30).distance(to: pos)
        
        let all = [left, right, back, front]
        
        if front.isSmallest(from: all) {
            return (n: 0, e: 1, s: 2, w: 3)
        } else if right.isSmallest(from: all) {
            return (n: 3, e: 0, s: 1, w: 2)
        } else if back.isSmallest(from: all) {
            return (n: 2, e: 3, s: 0, w: 1)
        } else if left.isSmallest(from: all) {
            return (n: 1, e: 2, s: 3, w: 0)
        } else {
            return (n: 0, e: 1, s: 2, w: 3)
        }
    }
    
    static func camSide(cameraPosition pos: SCNVector3, offset center: SCNVector3 = SCNVector3(x: 0, y: 0, z: 0)) -> Side {
        let left = SCNVector3(center.x + -30, pos.y, center.z).distance(to: pos)
        let right = SCNVector3(center.x + 30, pos.y, center.z).distance(to: pos)
        let back = SCNVector3(center.x, pos.y, center.z + 30).distance(to: pos)
        let front = SCNVector3(center.x, pos.y, center.z + -30).distance(to: pos)
        
        let all = [left, right, back, front]
        
        if front.isSmallest(from: all) {
            return .north
        } else if right.isSmallest(from: all) {
            return .east
        } else if back.isSmallest(from: all) {
            return .south
        } else if left.isSmallest(from: all) {
            return .west
        } else {
            return .west
        }
    }

}

extension SCNVector3 {
    func distance(to: SCNVector3) -> Double {
        let x = self.x - to.x
        let y = self.y - to.y
        let z = self.z - to.z
        
        return Double((x * x) + (y * y) + (z * z))
    }
}

extension Double {
    func isSmallest(from: [Double]) -> Bool {
        for value in from {
            if self < value {
                return false
            }
        }
        return true
    }
}
