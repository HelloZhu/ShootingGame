//
//  BlueShip.swift
//  shooting-game
//
//  Created by papannda444 on 2019/03/03.
//  Copyright © 2019 三野田脩. All rights reserved.
//

import Foundation
import SpriteKit

class BlueShip: SKSpriteNode {
    weak var delegate: SpaceShipDelegate?

    var state = SpaceShipState() {
        didSet {
            let statusTexture: SKTexture?
            switch state {
            case .normal:
                statusTexture = nil
            default:
                // state is .speed or .stone
                statusTexture = SKTexture(imageNamed: state.rawValue)
            }

            delegate?.updateShipState(statusTexture: statusTexture)
        }
    }
    var level = SpaceShipLevel() {
        didSet {
            delegate?.levelUpShip(level: level)
            isInvisibleBodyUsed = true
        }
    }
    var moveSpeed: CGFloat = 0.0
    var hearts: [SKSpriteNode] = []
    var maxHitPoint: Int = 0
    var bulletTimer: Timer?
    var timerForPowerItem: Timer?
    private var isInvisibleBodyUsed = true
    private var invisibleTimer: Timer?

    convenience init(moveSpeed: CGFloat, displayViewFrame frame: CGRect) {
        let texture = SKTexture(imageNamed: SpaceShipType.blue.rawValue)
        self.init(texture: texture, color: .clear, size: texture.size())
        self.moveSpeed = moveSpeed
        position = CGPoint(x: 0, y: frame.height / 2 - self.frame.height)
        scale(to: CGSize(width: 90, height: 90))
        physicsBody = SKPhysicsBody(circleOfRadius: self.frame.width / 4)
    }

    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BlueShip: SpaceShip {
    func damaged(_ enemy: Enemy? = nil) {
        if isShipState(equal: .stone) {
            enemy?.damaged()
            return
        }
        if isInvisibleBodyUsed {
            isInvisibleBodyUsed = false
            let invisibleTime: TimeInterval
            switch level {
            case .one:
                invisibleTime = 3
            case .two:
                invisibleTime = 6
            case .three:
                invisibleTime = 10
            }
            guard let prevContactTestBitMask = physicsBody?.contactTestBitMask else {
                return
            }
            delegate?.startSpecialAttack(spaceShip: self)
            run(SKAction.fadeAlpha(to: 0.3, duration: 0.0))
            invisibleTimer = Timer.scheduledTimer(withTimeInterval: invisibleTime, repeats: false) { [weak self] _ in
                self?.physicsBody?.contactTestBitMask = prevContactTestBitMask
                self?.run(SKAction.fadeAlpha(to: 1.0, duration: 0.0))
            }
            return
        }

        guard let heart = hearts.popLast() else {
            return
        }
        heart.removeFromParent()

        if hearts.isEmpty { delegate?.lostAllHearts() }
    }

    func touchViewBegin(touchedViewFrame frame: CGRect) {
        bulletTimer?.invalidate()
        let moveToTop = SKAction.sequence([
            SKAction.moveTo(y: frame.height + 10, duration: 0.3),
            SKAction.removeFromParent()
        ])
        let bullet = Bullet(bulletType: .blue, bulletLevel: level, position: position)
        bullet.run(moveToTop)
        delegate?.addBullet(bullet: bullet)
        bulletTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self, level] _ in
            let bullet = Bullet(bulletType: .blue, bulletLevel: level, position: self?.position ?? .zero)
            bullet.run(moveToTop)
            self?.delegate?.addBullet(bullet: bullet)
        }
    }
}
