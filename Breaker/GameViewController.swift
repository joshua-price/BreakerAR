/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import SceneKit
import ARKit

enum ColliderType: Int {
  case ball = 0b0001
  case barrier = 0b0010
  case brick = 0b0100
  case paddle = 0b1000
}

class GameViewController: UIViewController {
  
  @IBOutlet weak var sceneView: ARSCNView!
  var game = GameHelper.sharedInstance
  var planeNode: SCNNode?
  var ballNode: SCNNode?
  var paddleNode: SCNNode?
  var lastContactNode: SCNNode?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupSceneView()
    setupNodes()
    setupSounds()
  }
  
  func setupSceneView() {
    let configuration = ARWorldTrackingConfiguration()
    
    configuration.planeDetection = [.vertical]
    
    sceneView.session.run(configuration)
    
    sceneView.showsStatistics = true
    
    sceneView.autoenablesDefaultLighting = true
    sceneView.automaticallyUpdatesLighting = true
    
    sceneView.delegate = self
    sceneView.isPlaying = true
    
    sceneView.scene.physicsWorld.contactDelegate = self
  }
  
  func setupScene() {
    
  }
  
  func setupNodes() {
    guard let planeNode = self.planeNode else {
      return
    }
    
    planeNode.addChildNode(game.hudNode)
    let scene = SCNScene.init(named: "Breaker.scnassets/Scenes/Game.scn")!
    
    planeNode.addChildNode(scene.rootNode)
    
    self.ballNode = scene.rootNode.childNode(withName: "Ball", recursively: true)
    self.paddleNode = scene.rootNode.childNode(withName: "Paddle", recursively: true)
    
    ballNode?.physicsBody?.contactTestBitMask =
      ColliderType.barrier.rawValue |
      ColliderType.brick.rawValue |
      ColliderType.paddle.rawValue
  }
  
  func setupSounds() {
  }
  
  override var shouldAutorotate: Bool { return true }
  
  override var prefersStatusBarHidden: Bool { return true }
  
  // 1
  override func viewWillTransition(to size: CGSize, with coordinator:
    UIViewControllerTransitionCoordinator) {

  }
}

extension GameViewController: ARSCNViewDelegate {
  
  func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
    guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
    
//    let width = CGFloat(planeAnchor.extent.x)
//    let height = CGFloat(planeAnchor.extent.z)
    let plane = SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0)
    
    plane.materials.first?.diffuse.contents = UIColor.clear
    
    let planeNode = SCNNode(geometry: plane)
    
    let x = CGFloat(planeAnchor.center.x)
    let y = CGFloat(planeAnchor.center.y)
    let z = CGFloat(planeAnchor.center.z)
    planeNode.position = SCNVector3(x,y,z)
    
    node.addChildNode(planeNode)
    if self.planeNode == nil {
      self.planeNode = planeNode
      self.setupNodes()
    }
  }
  
  // TODO: Remove plane node from plane nodes array if appropriate
  
  
  func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {
    
  }
  
  func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
    if let planeAnchor = anchor as?  ARPlaneAnchor {
      guard let planeNode = node.childNodes.first
        , let _ = planeNode.geometry as? SCNBox
        else {
          return
      }
      
      let x = CGFloat(planeAnchor.center.x)
      let y = CGFloat(planeAnchor.center.y)
      let z = CGFloat(planeAnchor.center.z)
      
      planeNode.position = SCNVector3(x, y, z)
    }
    
  }
  
  func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
    
  }
  
  func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
    game.updateHUD()
  }
  
  func renderer(_ renderer: SCNSceneRenderer, didApplyAnimationsAtTime time: TimeInterval) {
    
  }
  
  func renderer(_ renderer: SCNSceneRenderer, didSimulatePhysicsAtTime time: TimeInterval) {
    
  }
  
  func renderer(_ renderer: SCNSceneRenderer, didApplyConstraintsAtTime time: TimeInterval) {
    
  }
  
  func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
    
  }
  
  func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
    
  }
  
}

extension GameViewController: SCNPhysicsContactDelegate {
  // 2
  func physicsWorld(_ world: SCNPhysicsWorld,
                    didBegin contact: SCNPhysicsContact) {
    // 3
    var contactNode: SCNNode!
    if contact.nodeA.name == "Ball" {
      contactNode = contact.nodeB
    } else {
      contactNode = contact.nodeA
    }
    // 4
    if lastContactNode != nil &&
      lastContactNode == contactNode {
      return
    }
    lastContactNode = contactNode
    
    // 1
    if contactNode.physicsBody?.categoryBitMask ==
      ColliderType.barrier.rawValue {
      if contactNode.name == "Bottom" {
        game.lives -= 1
        if game.lives == 0 {
          game.saveState()
          game.reset()
        }
      }
    }
    // 2
    if contactNode.physicsBody?.categoryBitMask ==
      ColliderType.brick.rawValue {
      game.score += 1
      contactNode.isHidden = true
      contactNode.runAction(
        SCNAction.waitForDurationThenRunBlock(duration: 120) {
          (node:SCNNode!) -> Void in
          node.isHidden = false
      })
    }
    // 3
    if contactNode.physicsBody?.categoryBitMask ==
      ColliderType.paddle.rawValue {
      if contactNode.name == "Left" {
        ballNode?.physicsBody!.velocity.xzAngle -=
          (convertToRadians(angle: 20))
      }
      if contactNode.name == "Right" {
        ballNode?.physicsBody!.velocity.xzAngle +=
          (convertToRadians(angle: 20))
      }
    }
    // 4
    ballNode?.physicsBody?.velocity.length = 0.5
  }
  
  func physicsWorld(_ world: SCNPhysicsWorld, didUpdate contact: SCNPhysicsContact) {
    
  }
  
  func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
    
  }
}
