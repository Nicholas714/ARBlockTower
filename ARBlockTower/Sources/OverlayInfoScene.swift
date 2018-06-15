import UIKit
import SpriteKit
import SceneKit

extension SKLabelNode {
    
    func fade() {
        run(SKAction.fadeOut(withDuration: 0.5))
    }
    
    func show() {
        run(SKAction.fadeIn(withDuration: 0.5))
    }
    
    func showThenFade() {
        alpha = 0
        
        show()
        
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { (_) in
            self.fade()
        })
    }
    
}

class OverlayInfoScene: SKScene {

    var title: SKLabelNode
    var reset: TowerButton
    var ar: TowerButton

    let toggle: () -> Void = {
        if GameManager.current.is3D {
            GameManager.current.showAR()
        } else {
            GameManager.current.show3D()
        }
    }
    
    let resetGame: () -> Void = {
        if GameManager.current.is3D {
            GameManager.current.scnSceneView.jScene.resetWorld()
        } else {
            GameManager.current.arSceneView.jScene.resetWorld()
        }
    }
    
    init(size: CGSize, top: String, line1: String, line2: String, bottom: String) {
        title = SKLabelNode(text: top)
        reset = TowerButton(title: "Reset", onClick: resetGame)
        ar = TowerButton(title: "AR/3D", onClick: toggle)
        
        super.init(size: size)
        
        setup()
    }

    func setup() {
        let infoFont = UIFont.boldSystemFont(ofSize: 16.0).fontName

        scaleMode = .aspectFit

        title.fontSize = 23
        title.alpha = 0
        title.fontName = infoFont
    
        addChild(reset)
        addChild(ar)
        addChild(title)
        
        updatePositions()
    }
    
    func blackFadeOut() {
        let background = SKShapeNode(rectOf: CGSize(width: 5000, height: 5000))
        background.fillColor = UIColor.black
        background.strokeColor = UIColor.black
        background.zPosition = 5
        addChild(background)
        background.run(SKAction.fadeOut(withDuration: 2))
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updatePositions() {
        title.position = CGPoint(x: frame.midX, y: frame.height - 60)
        ar.position = CGPoint(x: frame.minX + reset.frame.width / 2 + 20, y: frame.maxY * 0.1)
        reset.position = CGPoint(x: frame.maxX - reset.frame.width / 2 - 20, y: frame.maxY * 0.1)
    }
    
}

class TowerButton: SKSpriteNode {
    
    let infoFont = UIFont.boldSystemFont(ofSize: 16.0).fontName
    
    let label: SKLabelNode
    let buttonSize = CGSize(width: 100, height: 50)
    
    let onClick: () -> Void
    
    init(title: String, onClick: @escaping () -> Void) {
        self.onClick = onClick
        
        label = SKLabelNode(text: title)
        label.fontSize = 19
        label.fontName = infoFont
        label.fontColor = UIColor.black
        label.verticalAlignmentMode = .center
        
        let bg = SKShapeNode(rect: CGRect(origin: CGPoint.zero, size: buttonSize), cornerRadius: (buttonSize.height - 1) / 2)
        bg.strokeColor = UIColor.white
        bg.fillColor = UIColor.white
        let bgTexture = SKView().texture(from: bg)!
        
        super.init(texture: bgTexture, color: UIColor.white, size: buttonSize)
        
        isUserInteractionEnabled = true 
        
        label.zPosition = 3
        zPosition = 2
        
        label.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(label)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let _ = touches.first {
            alpha = 0.6
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let clickedResets = nodes(at: touch.location(in: self)).filter({ (node) -> Bool in
                return node is TowerButton
            })
            
            if clickedResets.isEmpty {
                 alpha = 1.0
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let _ = touches.first {
            alpha = 1.0
            onClick()
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let _ = touches.first {
            alpha = 1.0
            onClick()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
