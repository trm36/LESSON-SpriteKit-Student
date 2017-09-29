//
//  GameScene.swift
//  BrickBreaker
//
//  Created by Taylor Mott on 19.4.17.
//  Copyright © 2017 Mott Applications. All rights reserved.
//

import SpriteKit
import GameplayKit

enum NodeName : String {
    case ball = "ball"
    case paddle = "paddle"
    case brick = "brick"
    
    static func string(from nodeName: NodeName) -> String {
        return nodeName.rawValue
    }
}

let BallCategoryBitMask: UInt32 = 0x1 << 0
let BottomCategoryBitMask: UInt32 = 0x1 << 1
let BrickCategoryBitMask: UInt32 = 0x1 << 2
let PaddleCategoryBitMask: UInt32 = 0x1 << 3
let BorderCategoryBitMask: UInt32 = 0x1 << 4

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    private var ball: SKSpriteNode?
    private var paddle: SKSpriteNode?
    var isPaddleTouched = false

    override func didMove(to view: SKView) {
        super.didMove(to: view)
    
        self.ball = childNode(withName: NodeName.string(from: .ball)) as? SKSpriteNode
        self.paddle = childNode(withName: NodeName.string(from: .paddle)) as? SKSpriteNode
        
        
        let borderPhysicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        borderPhysicsBody.isDynamic = false
        borderPhysicsBody.allowsRotation = false
        borderPhysicsBody.affectedByGravity = false
        borderPhysicsBody.pinned = false
        borderPhysicsBody.friction = 0.0
        borderPhysicsBody.restitution = 1.0
        borderPhysicsBody.linearDamping = 0.0
        borderPhysicsBody.angularDamping = 0.0
        physicsBody = borderPhysicsBody
        
        physicsWorld.contactDelegate = self

        let bottom = SKNode()
        bottom.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: 0, y: 0), to: CGPoint(x: frame.width, y: 0.0))
        bottom.physicsBody?.categoryBitMask = BottomCategoryBitMask
        addChild(bottom)
        
        ball?.physicsBody?.categoryBitMask = BallCategoryBitMask
        paddle?.physicsBody?.categoryBitMask = PaddleCategoryBitMask
        physicsBody?.categoryBitMask = BorderCategoryBitMask
        
        ball?.physicsBody?.contactTestBitMask = BrickCategoryBitMask | BottomCategoryBitMask
        
        setupBricks()
        
        ball?.physicsBody?.applyImpulse(CGVector(dx: 2.0, dy: -2.0))
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        
        guard let body = physicsWorld.body(at: touchLocation) else { return }
        if body.node?.name == NodeName.string(from: .paddle) {
            isPaddleTouched = true
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isPaddleTouched {
            guard let touch = touches.first else { return }
            let touchLocation = touch.location(in: self)
            let previousLocation = touch.previousLocation(in: self)
            
            guard let paddle = paddle else { return }
            
            var paddleX = paddle.position.x + (touchLocation.x - previousLocation.x)
            paddleX = max(paddleX, paddle.size.width/2.0)
            paddleX = min(paddleX, size.width - paddle.size.width/2.0)
            
            paddle.position = CGPoint(x: paddleX, y: paddle.position.y)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isPaddleTouched = false
    }
    
    func setupBricks() {
        let numberOfBricks = 8
        let spacing: CGFloat = 5.0
        let brickWidth: CGFloat = #imageLiteral(resourceName: "brick").size.width
        let totalBrickWidth = ((brickWidth + spacing) * CGFloat(numberOfBricks)) - spacing
        let xOffset = (frame.width - totalBrickWidth + brickWidth) / 2.0
        
        for i in 0..<numberOfBricks {
            let brick = SKSpriteNode(imageNamed: "brick")
            brick.name = NodeName.string(from: .brick)
            brick.position = CGPoint(x: xOffset + CGFloat(i) * (brickWidth + spacing), y: frame.height * 0.8)
            brick.zPosition = 2
            brick.physicsBody = SKPhysicsBody(rectangleOf: brick.frame.size)
            brick.physicsBody?.allowsRotation = false
            brick.physicsBody?.friction = 0.0
            brick.physicsBody?.affectedByGravity = false
            brick.physicsBody?.isDynamic = false
            brick.physicsBody?.categoryBitMask = BrickCategoryBitMask
            addChild(brick)
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if firstBody.categoryBitMask == BallCategoryBitMask {
            switch secondBody.categoryBitMask {
            case BottomCategoryBitMask:
                print("Hit Bottom")
            case BrickCategoryBitMask:
                breakBrick(node: secondBody.node)
            default:
                return
            }
        }
    }
    
    func breakBrick(node: SKNode?) {
        guard let node = node,
            let particles = SKEmitterNode(fileNamed: "Shatter") else { return }
        particles.position = node.position
        particles.zPosition = 3
        addChild(particles)
        let action = SKAction.sequence([SKAction.wait(forDuration: 1.0), SKAction.removeFromParent()])
        particles.run(action)
        node.removeFromParent()
    }

}
