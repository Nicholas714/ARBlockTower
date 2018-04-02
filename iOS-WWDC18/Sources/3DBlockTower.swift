//
//  JSCNScene.swift
//  JengaAR
//
//  Created by Nicholas Grana on 3/17/18.
//  Copyright © 2018 Nicholas Grana. All rights reserved.
//

import SceneKit
import ARKit
import UIKit

class SCNTowerView: SCNView, ARSCNViewDelegate {
    
    // MARK: Properties
    
    var isCreated = false
    var jScene: SCNTowerScene!
    
    // MARK: Creation of view
    
    func setup() {
        jScene = SCNTowerScene()
        scene = jScene
        jScene.setup(for: self)
        delegate = self

        backgroundColor = UIColor.black
        allowsCameraControl = true
        autoenablesDefaultLighting = true
        scene = scene
        
        defaultCameraController.interactionMode = .orbitTurntable
        defaultCameraController.maximumVerticalAngle = 60.0
        defaultCameraController.minimumVerticalAngle = 1.0
        
        // remove all gestures put pan to move and pinch to zoom
        for gesture in gestureRecognizers! {
            if gesture is UIRotationGestureRecognizer || gesture is UITapGestureRecognizer || gesture is UILongPressGestureRecognizer {
                if let index = gestureRecognizers?.index(of: gesture) {
                    gestureRecognizers!.remove(at: index)
                }
            }
        }
        
        // add tap gesture to move blocks
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapGesture(_:)))
        addGestureRecognizer(tap)
        
        overlaySKScene = OverlayInfoScene(size: frame.size, top: "3D Scene", line1: "Pan with your finger to look around the scene", line2: "Tap a block to push it", bottom: "WWDC18")
    }
    
    // TODO: add button to switch to ARView
    
    // MARK: Gestures
    
    var isSendingDirections = false
    
    @objc func tapGesture(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        let hit = hitTest(location, options: [:])
        
        let force = 3
        
        if let first = hit.first, let povPos = pointOfView?.position {
            let side = Side.camSide(cameraPosition: povPos)
            
            if first.node.name == "box" && !isSendingDirections {
                isSendingDirections = true
                
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

class SCNTowerScene: SCNScene, UIGestureRecognizerDelegate {
    
    var sceneView: SCNTowerView!
    
    var nodeOrigin = [SCNNode: SCNVector3]()
    var nodeRot = [SCNNode: SCNVector4]()
    let cameraNode = SCNNode()
    let camera = SCNCamera()
    let camPos = SCNVector3(x: -5.7, y: 13.1, z: 14.1)
    let camRot = SCNVector4(x: -0.67, y: -0.72, z: -0.14, w: 0.55)
    
    func setup(for sceneView: SCNTowerView) {
        self.sceneView = sceneView
        
        setupCamera()
        setupLighting()
        createFloor()
        createTower()
        
        physicsWorld.gravity = SCNVector3(0, -30, 0)
        
        let material = SCNMaterial()
        
        material.lightingModel = .physicallyBased
        material.isDoubleSided = true
        material.diffuse.contents = UIImage(named: "floor.png")
        
        let sphere = SCNSphere(radius: 160)
        sphere.firstMaterial = material
        let bgSphere = SCNNode(geometry: sphere)
        rootNode.addChildNode(bgSphere)
        
       
    }
    
    func setupCamera() {
        camera.zFar = 100000
        cameraNode.camera = camera
        cameraNode.position = camPos
        cameraNode.rotation = camRot
        rootNode.addChildNode(cameraNode)
    }
    
    func setupLighting() {
        sceneView.autoenablesDefaultLighting = false
        
        let lighting = UIImage(named: "spherical.jpg")
        sceneView.scene?.lightingEnvironment.contents = lighting
    }
    
    // MARK: Node creation
    
    func createTower() {
        let length: CGFloat = 4
        let width: CGFloat = length / CGFloat(3)
        let height: CGFloat = 1
        
        for y in 0...10 {
            for x in -1...1 {
                let box = SCNBox(width: width, height: height, length: length, chamferRadius: (width / 2) * 0.15)
                
                let wood = JMaterial(type: .wood)
                wood.apply(to: box)
                
                let boxNode = SCNNode(geometry: box)
                
                if y % 2 == 0 {
                    boxNode.position = SCNVector3(x: Float(x) * Float(width), y: Float(y) * Float(height) + 0.5, z: 0)
                } else {
                    boxNode.position = SCNVector3(x: 0, y: Float(y) * Float(height) + 0.5, z: Float(x) * Float(width))
                    boxNode.rotation = SCNVector4(x: 0, y: 1, z: 0, w: Float.pi / 2)
                }
                
                boxNode.name = "box"
                boxNode.physicsBody = SCNPhysicsBody.dynamic()
                boxNode.physicsBody?.friction = 0.9
                boxNode.physicsBody?.mass = 0.1
                rootNode.addChildNode(boxNode)
                
                nodeOrigin[boxNode] = boxNode.position
                nodeRot[boxNode] = boxNode.rotation
            }
        }
        
    }
    
    func createFloor() {
        let floor = SCNFloor()
        JMaterial(type: .floor).apply(to: floor)
        floor.reflectivity = 0.2
        let floorNode = SCNNode(geometry: floor)
        floorNode.position = SCNVector3(x: 50, y: 0, z: 50)
        floorNode.physicsBody = SCNPhysicsBody.static()
        rootNode.addChildNode(floorNode)
    }
    
    func resetWorld() {
        for node in rootNode.childNodes(passingTest: { (node, _) -> Bool in
            return node.geometry != nil && node.geometry! is SCNBox
        }) {
            if let origin = nodeOrigin[node], let rot = nodeRot[node] {
                sceneView.pointOfView?.runAction(SCNAction.group([SCNAction.move(to: camPos, duration: 1), SCNAction.rotate(toAxisAngle: camRot, duration: 1)]))
                sceneView.pointOfView?.camera?.fieldOfView = 60
                
                node.rotation = SCNVector4(x: 0, y: 0, z: 0, w: 0)
                
                node.physicsBody = nil
                node.runAction(SCNAction.group([SCNAction.move(to: origin, duration: 1.0), SCNAction.rotate(toAxisAngle: rot, duration: 1.0)]))
                
                Timer.scheduledTimer(withTimeInterval: 2.1, repeats: false, block: { (_) in
                    node.rotation = rot
                    node.position = origin
                    
                    node.physicsBody = SCNPhysicsBody.dynamic()
                    node.physicsBody?.friction = 0.9
                    node.physicsBody?.mass = 0.1
                })
            }
        }
    }
    
}
