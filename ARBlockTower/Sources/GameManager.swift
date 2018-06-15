import SceneKit

public class GameManager {

    public static var current = GameManager()
    
    var controller: ViewController!
    
    var arSceneView: ARTowerView!
    var scnSceneView: SCNTowerView!
    var is3D = false 
    
    func setup(controller: ViewController) {
        self.controller = controller
        
        JTexture.loadTextures()
        loadSCNScene()
        loadARScene()

    }
    
    func loadARScene() {
        arSceneView = ARTowerView(frame: controller.view.frame)
        let scene = ARTowerScene()
        arSceneView?.scene = scene
        arSceneView?.setup()
        controller.view.addSubview(arSceneView!)
    }
    
    func loadSCNScene() {
        scnSceneView = SCNTowerView(frame: controller.view.frame)
        let scene = SCNTowerScene()
        scnSceneView?.scene = scene
        scnSceneView?.setup()
        controller.view.addSubview(scnSceneView!)
    }
    
    func firstShow3D() {
        show3D()
        (scnSceneView.overlaySKScene as! OverlayInfoScene).blackFadeOut()
    }
    
    func showAR() {
        controller.view.addSubview(arSceneView)

        (arSceneView.overlaySKScene as! OverlayInfoScene).title.showThenFade()
        is3D = false
    }
    
    func show3D() {
        controller.view.addSubview(scnSceneView)
        
        (scnSceneView.overlaySKScene as! OverlayInfoScene).title.showThenFade()
        is3D = true 
    }
    
}
