//
//  JARScene.swift
//  JengaAR
//
//  Created by Nicholas Grana on 3/17/18.
//  Copyright © 2018 Nicholas Grana. All rights reserved.
//

import SceneKit
import ARKit
import UIKit

class ARTowerView: ARSCNView, ARSCNViewDelegate, UIGestureRecognizerDelegate {
    
    // MARK: Properties

    var jScene: ARTowerScene!
    var towerCenter: SCNVector3?
    
    // MARK: Creation of view
    
    func setup() {
        jScene = ARTowerScene()
        scene = jScene
        jScene.setup(for: self)
        delegate = self
        //sceneView.debugOptions = .showPhysicsShapes
        
        // add tap gesture to move blocks
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapGesture))
        addGestureRecognizer(tap)
        
        // create AR session
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.isLightEstimationEnabled = true
        configuration.planeDetection = .horizontal
        
        session.run(configuration)
        
        overlaySKScene = OverlayInfoScene(size: frame.size, top: "Augmented Reality Scene", line1: "Move around the room and find a flat surface", line2: "Tap the yellow zone to place the tower", bottom: "WWDC18")
    }
    
    // MARK: ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let anchor = anchor as? ARPlaneAnchor else {
            return
        }
        
        if let floor = jScene.createFloor(anchor: anchor) {
            node.addChildNode(floor)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let anchor = anchor as? ARPlaneAnchor else {
            return
        }
        
        scene.rootNode.childNodes { (node, _) -> Bool in
            return node.name == "yellow-floor"
            }.forEach { (node) in
                node.removeFromParentNode()
        }
        
        if let floor = jScene.createFloor(anchor: anchor) {
            node.addChildNode(floor)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if let lightEst = session.currentFrame?.lightEstimate {
            let strength = lightEst.ambientIntensity / 1000
            scene.lightingEnvironment.intensity = strength
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
    
    // MARK: Gestures
    
    @objc func tapGesture(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        let hit = hitTest(location, options: [:])
        
        guard let first = hit.first else {
            return
        }
        
        if towerCenter == nil {
            let arHit = hitTest(location, types: ARHitTestResult.ResultType.existingPlaneUsingExtent)
            if let first = arHit.first {
                jScene.createTower(hit: first)
                towerCenter = SCNVector3(x: first.worldTransform.columns.3.x, y: first.worldTransform.columns.3.y, z: first.worldTransform.columns.3.z)
                (overlaySKScene as! OverlayInfoScene).line1Label.fade()
                (overlaySKScene as! OverlayInfoScene).line2Label.fade()
                
                let line1Label = (self.overlaySKScene as! OverlayInfoScene).line1Label
                let line2Label = (self.overlaySKScene as! OverlayInfoScene).line2Label
                
                Timer.scheduledTimer(withTimeInterval: 0.6, repeats: false, block: { (_) in
                    line1Label.text = "Push out each block until the tower falls"
                    line2Label.text = "See how far you can stack up against gravity"
                    line1Label.show()
                    line2Label.show()
                })
                
                Timer.scheduledTimer(withTimeInterval: 10, repeats: false, block: { (_) in
                    line1Label.fade()
                    line2Label.fade()
                })
            }
            first.node.removeFromParentNode()
        } else {
            let force = 0.0003
            
            if let povPos = pointOfView?.position {
                let side = Side.camSide(cameraPosition: povPos, offset: towerCenter!)
                
                (overlaySKScene as! OverlayInfoScene).line1Label.fade()
                (overlaySKScene as! OverlayInfoScene).line2Label.fade()
                
                if let body = first.node.physicsBody, !body.isAffectedByGravity {
                    for node in scene.rootNode.childNodes(passingTest: { (node, _) -> Bool in
                        return node.geometry != nil && node.geometry! is SCNBox
                    }) {
                        node.physicsBody?.isAffectedByGravity = true
                    }
                }
                
                switch side {
                case .north:
                    first.node.physicsBody?.applyForce(SCNVector3(0, 0, -force), asImpulse: true)
                case .south:
                    first.node.physicsBody?.applyForce(SCNVector3(0, 0, force), asImpulse: true)
                case .west:
                    first.node.physicsBody?.applyForce(SCNVector3(-force, 0, 0), asImpulse: true)
                case .east:
                    first.node.physicsBody?.applyForce(SCNVector3(force, 0, 0), asImpulse: true)
                case .top:
                    return
                }
            }
            
        }
        
    }
    
    
}

class ARTowerScene: SCNScene, UIGestureRecognizerDelegate {
    
    var nodeOrigin = [SCNNode: SCNVector3]()
    var nodeRot = [SCNNode: SCNVector4]()
    
    var sceneView: ARTowerView!
    
    func setup(for sceneView: ARTowerView) {
        self.sceneView = sceneView
        
        setupLighting()
    }
    
    func setupLighting() {
        sceneView.autoenablesDefaultLighting = false
        sceneView.automaticallyUpdatesLighting = false
        
        let lighting = UIImage(named: "spherical.jpg")
        sceneView.scene.lightingEnvironment.contents = lighting
    }
    
    // MARK: Node creation
    
    func createTower(hit: ARHitTestResult) {
        let length: CGFloat = 0.08
        let width: CGFloat = length / CGFloat(3)
        let height: CGFloat = 0.02
        
        let centerX = hit.worldTransform.columns.3.x
        let centerY = hit.worldTransform.columns.3.y
        let centerZ = hit.worldTransform.columns.3.z
        
        for x in -1...1 {
            let bottomBox = SCNBox(width: width, height: height, length: length, chamferRadius: (width / 2) * 0.1)
            bottomBox.firstMaterial?.diffuse.contents = UIColor.clear
            let bottomBoxNode = SCNNode(geometry: bottomBox)
            bottomBoxNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: bottomBox, options: nil))
            bottomBoxNode.physicsBody?.allowsResting = true
            bottomBoxNode.physicsBody?.friction = 1.0
            bottomBoxNode.physicsBody?.rollingFriction = 1.0
            bottomBoxNode.position = SCNVector3(x: centerX + Float(x) * Float(width), y: centerY + Float(height / 2), z: centerZ)
            rootNode.addChildNode(bottomBoxNode)
        }
       
        
        for y in 1...11 {
            for x in -1...1 {
                let box = SCNBox(width: width, height: height, length: length, chamferRadius: (width / 2) * 0.1)
                
                let wood = JMaterial(type: .wood)
                wood.apply(to: box)
                
                let boxNode = SCNNode(geometry: box)
                
                if y % 2 == 0 {
                    boxNode.position = SCNVector3(x: centerX + Float(x) * Float(width), y: centerY + Float(y) * Float(height) + Float(height / 2), z: centerZ)
                } else {
                    boxNode.position = SCNVector3(x: centerX, y: centerY + Float(y) * Float(height) + Float(height / 2), z: centerZ + Float(x) * Float(width))
                    boxNode.rotation = SCNVector4(x: 0, y: 1, z: 0, w: Float.pi / 2)
                }
                
                boxNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: box, options: nil))
                boxNode.physicsBody?.allowsResting = false
                boxNode.physicsBody?.mass = 0.001
                
                boxNode.physicsBody?.friction = 0.9
                boxNode.physicsBody?.isAffectedByGravity = false
                
                nodeOrigin[boxNode] = boxNode.position
                nodeRot[boxNode] = boxNode.rotation
                
                rootNode.addChildNode(boxNode)
            }
        }
        
        physicsWorld.gravity = SCNVector3(x: 0, y: -0.01, z: 0) 
        
        let phy = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.0), options: nil))
        phy.isAffectedByGravity = false
        sceneView.pointOfView?.physicsBody = phy
        
        if let anchor = hit.anchor, anchor is ARPlaneAnchor {
            let floorNode = createUnderFloor(anchor: hit.anchor as! ARPlaneAnchor)
            floorNode.position = SCNVector3(x: centerX, y: centerY, z: centerZ)
            rootNode.addChildNode(floorNode)
        }
    }
    
    func createFloor(anchor: ARPlaneAnchor) -> SCNNode? {
        if sceneView.towerCenter == nil {
            let floor = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
            floor.firstMaterial?.diffuse.contents = UIColor.yellow.withAlphaComponent(0.6)
            floor.cornerRadius = (floor.width / 2) * 0.5
            
            let floorNode = SCNNode(geometry: floor)
            floorNode.name = "yellow-floor"
            floorNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
            
            return floorNode
        }
        
        return nil
    }
    
    func createUnderFloor(anchor: ARPlaneAnchor) -> SCNNode {
        let floor = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        JMaterial(type: .floor).apply(to: floor)
        floor.cornerRadius = (floor.width / 2) * 0.5
        
        let floorNode = SCNNode(geometry: floor)
        floorNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        floorNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: floor, options: nil))
        
        return floorNode
    }
    
    func resetWorld() {
        for _ in rootNode.childNodes(passingTest: { (node, _) -> Bool in
            return node.geometry != nil && node.geometry! is SCNBox
        }) {
            self.sceneView.overlaySKScene = OverlayInfoScene(size: self.sceneView.frame.size, top: "Augmented Reality Scene", line1: "Move around the room and find a flat surface", line2: "Tap the yellow zone to place the tower", bottom: "WWDC18")
            self.sceneView.towerCenter = nil
            
            for node in self.rootNode.childNodes {
                if let geo = node.geometry {
                    if geo is SCNBox || geo is SCNPlane {
                        node.removeFromParentNode()
                    }
                }
            }
            
        }
    }
    
}
