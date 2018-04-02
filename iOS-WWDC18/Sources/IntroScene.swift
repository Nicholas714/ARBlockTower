import SceneKit
import SpriteKit

class IntroScene {
    
    var sceneView = SCNView(frame: GameManager.current.rootSize)
    let scene: SCNScene
    let cameraNode: SCNNode
    let exp1: SCNParticleSystem
    let exp2: SCNParticleSystem
    
    init() {
        scene = SCNScene()
        sceneView.scene = scene
        sceneView.backgroundColor = UIColor.black
        
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = false
        
        cameraNode = SCNNode()
        cameraNode.physicsBody = SCNPhysicsBody.dynamic()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zFar = 10000
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 400)
        scene.rootNode.addChildNode(cameraNode)
        
        exp1 = SCNParticleSystem()
        exp2 = SCNParticleSystem()
        
        for color in [UIColor.brown] {
            exp1.loops = true
            exp1.birthRate = 15000
            exp1.emissionDuration = 5
            exp1.emitterShape = SCNCylinder(radius: 4, height: 40)
            exp1.particleLifeSpan = 15
            exp1.particleVelocity = CGFloat(-100)
            exp1.particleSize = 0.4
            exp1.particleColor = color
            exp1.isAffectedByPhysicsFields = true
            exp1.isAffectedByGravity = true
            scene.addParticleSystem(exp1, transform: SCNMatrix4MakeRotation(0, 0, 0, 0))
        }
        
        for color in [UIColor.brown] {
            exp2.loops = true
            exp2.birthRate = 15000
            exp2.emissionDuration = 5
            exp2.emitterShape = SCNCylinder(radius: 4, height: 40)
            exp2.particleLifeSpan = 15
            exp2.particleVelocity = CGFloat(100)
            exp2.particleSize = 0.4
            exp2.particleColor = color
            exp2.isAffectedByPhysicsFields = true
            exp2.isAffectedByGravity = true
            scene.addParticleSystem(exp2, transform: SCNMatrix4MakeRotation(0, 0, 0, 0))
        }
        
        sceneView.overlaySKScene = IntroSKScene(intro: self)

    }
    
    func startTimers() {
        let moveToTop = SCNAction.move(to: SCNVector3(x: 0, y: 400, z: 0), duration: 15)
        let rotToTop = SCNAction.rotate(toAxisAngle: SCNVector4(-1, 0, 0, Float.pi / 2), duration: 15)
        moveToTop.timingMode = .easeIn
        rotToTop.timingMode = .easeIn
        cameraNode.runAction(SCNAction.group([moveToTop, rotToTop]))
        
        Timer.scheduledTimer(withTimeInterval: 8, repeats: false) { (_) in
            
            let wwdcText = SCNText(string: "WWDC18", extrusionDepth: 1.0)
            let wwdcNode = SCNNode(geometry: wwdcText)
            wwdcNode.position = SCNVector3(x: -33, y: 0, z: 0)
            wwdcNode.rotation = SCNVector4(-1, 0, 0, Float.pi / 2)
            wwdcNode.opacity = 0.0
            let fadeIn = SCNAction.fadeIn(duration: 15) // 10
            wwdcNode.runAction(fadeIn)
            self.scene.rootNode.addChildNode(wwdcNode)
            
            var rad: CGFloat = 4
            Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { (timer) in
                if rad < 100 {
                    rad += 0.5
                    self.exp1.particleSize += 0.001
                    self.exp1.birthRate += 30
                    self.exp2.birthRate += 30
                    self.exp1.emitterShape = SCNCylinder(radius: rad, height: 40)
                    self.exp2.particleSize += 0.001
                    self.exp2.emitterShape = SCNCylinder(radius: rad, height: 40)
                } else {
                    timer.invalidate()
                }
            }
        }
        
        Timer.scheduledTimer(withTimeInterval: 19, repeats: false) { (_) in
            let a = SCNAction.move(to: SCNVector3Make(0, -10, 0), duration: 5)
            a.timingMode = .easeIn
            self.cameraNode.runAction(a)
        }
        
        Timer.scheduledTimer(withTimeInterval: 24, repeats: false) { (_) in
            GameManager.current.firstShow3D()
        }
        
        let field = SCNPhysicsField.vortex()
        field.strength = -30
        let fieldNode = SCNNode()
        fieldNode.physicsField = field
        scene.rootNode.addChildNode(fieldNode)
    }
    
    class IntroSKScene: SKScene {
        
        let intro: IntroScene
        let startLabel: SKLabelNode
        var startBackground: SKShapeNode!
        
        init(intro: IntroScene) {
            self.intro = intro
            self.startLabel = SKLabelNode(text: "Tap anywhere when the iPad is in fullscreen and you are ready.")
            
            super.init(size: GameManager.current.rootSize.size)
            
            let infoFont = UIFont.boldSystemFont(ofSize: 16.0).fontName
            
            startLabel.verticalAlignmentMode = .center
            startLabel.horizontalAlignmentMode = .center
            
            scaleMode = .aspectFit
            
            startLabel.fontSize = 12
            startLabel.alpha = 0
            startLabel.fontName = infoFont
            
            self.startBackground = SKShapeNode(rect: CGRect(origin: CGPoint.zero, size: CGSize(width: 1000, height: startLabel.frame.height + 10)), cornerRadius: 1.0)

            startBackground.fillColor = UIColor.black
            startBackground.strokeColor = UIColor.black
            
            addChild(startBackground)
            addChild(startLabel)
            
            startLabel.show()
            updatePositions()
        }
        
        var isStarted = false
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            if let _ = touches.first, !isStarted {
                startLabel.fade()
                startBackground.run(SKAction.fadeOut(withDuration: 0.5))
                self.intro.startTimers()
                isStarted = true
            }
        }
        
        func updatePositions() {
            startLabel.position = CGPoint(x: frame.midX, y: frame.midY - 2.5)
            startBackground.position = CGPoint(x: frame.midX - startBackground.frame.width / 2, y: frame.midY - startBackground.frame.height / 2)
        }
        
        override func update(_ currentTime: TimeInterval) {
            let newSize = intro.sceneView.frame.size
            
            if size != newSize {
                size = newSize
                updatePositions()
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
    }
    
}


