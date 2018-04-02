import SceneKit
import PlaygroundSupport

public class GameManager {

    public static var current = GameManager()
    
    let rootSize = CGRect(x: 0, y: 0, width: 800, height: 800)
    var arSceneView: ARTowerView!
    var scnSceneView: SCNTowerView!
    var is3D = true
    
    public func setup() {
        JTexture.loadTextures()
        loadSCNScene()
        loadARScene()

        let intro = IntroScene()
        PlaygroundPage.current.liveView = intro.sceneView
    }
    
    func loadARScene() {
        arSceneView = ARTowerView(frame: rootSize)
        let scene = ARTowerScene()
        arSceneView?.scene = scene
        arSceneView?.setup()
    }
    
    func loadSCNScene() {
        scnSceneView = SCNTowerView(frame: rootSize)
        let scene = SCNTowerScene()
        scnSceneView?.scene = scene
        scnSceneView?.setup()
    }
    
    func firstShow3D() {
        show3D()
        (scnSceneView.overlaySKScene as! OverlayInfoScene).blackFadeOut()
    }
    
    func showAR() {
        PlaygroundSupport.PlaygroundPage.current.liveView = arSceneView
        (arSceneView.overlaySKScene as! OverlayInfoScene).title.showThenFade()
        is3D = false
    }
    
    func show3D() {
        PlaygroundSupport.PlaygroundPage.current.liveView = scnSceneView
        (scnSceneView.overlaySKScene as! OverlayInfoScene).title.showThenFade()
        is3D = true 
    }
    
}
