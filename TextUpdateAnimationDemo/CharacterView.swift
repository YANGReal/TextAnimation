//
//  CharacterView.swift
//  TextUpdateAnimationDemo
//

import UIKit

class CharacterView: UIView {

    private(set) var character: Character
    var characterHeight: CGFloat

    var font: UIFont {
        didSet {
            currentLabel.font = font
            nextLabel.font = font
        }
    }

    var textColor: UIColor {
        didSet {
            currentLabel.textColor = textColor
            nextLabel.textColor = textColor
        }
    }

    // 字符宽度用 UILabel 实际测量，比 NSString.size 更准确
    var characterWidth: CGFloat {
        let label = UILabel()
        label.font = font
        label.text = String(character)
        return ceil(label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: characterHeight)).width)
    }

    private let containerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()

    private let currentLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

    private let nextLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

    init(character: Character, font: UIFont, textColor: UIColor, height: CGFloat) {
        self.character = character
        self.font = font
        self.textColor = textColor
        self.characterHeight = height
        super.init(frame: .zero)
        setupUI()
        currentLabel.text = String(character)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        currentLabel.font = font
        currentLabel.textColor = textColor
        nextLabel.font = font
        nextLabel.textColor = textColor
        nextLabel.isHidden = true

        addSubview(containerView)
        containerView.addSubview(currentLabel)
        containerView.addSubview(nextLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.frame = bounds
        let h = bounds.height
        let w = bounds.width
        currentLabel.frame = CGRect(x: 0, y: 0, width: w, height: h)
        if nextLabel.isHidden {
            nextLabel.frame = CGRect(x: 0, y: h, width: w, height: h)
        }
    }

    func configure(character: Character) {
        self.character = character
        currentLabel.text = String(character)
        nextLabel.isHidden = true
        let h = bounds.height
        let w = bounds.width
        currentLabel.frame = CGRect(x: 0, y: 0, width: w, height: h)
        nextLabel.frame = CGRect(x: 0, y: h, width: w, height: h)
    }

    func animateTo(
        newCharacter: Character,
        direction: AnimationDirection,
        duration: TimeInterval = 0.3,
        completion: (() -> Void)? = nil
    ) {
        self.character = newCharacter
        nextLabel.text = String(newCharacter)
        nextLabel.isHidden = false

        let h = containerView.bounds.height
        let w = containerView.bounds.width

        switch direction {
        case .up:
            currentLabel.frame = CGRect(x: 0, y: 0, width: w, height: h)
            nextLabel.frame = CGRect(x: 0, y: h, width: w, height: h)
            UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut]) {
                self.currentLabel.frame = CGRect(x: 0, y: -h, width: w, height: h)
                self.nextLabel.frame = CGRect(x: 0, y: 0, width: w, height: h)
            } completion: { _ in
                self.currentLabel.text = String(newCharacter)
                self.currentLabel.frame = CGRect(x: 0, y: 0, width: w, height: h)
                self.nextLabel.isHidden = true
                completion?()
            }

        case .down:
            currentLabel.frame = CGRect(x: 0, y: 0, width: w, height: h)
            nextLabel.frame = CGRect(x: 0, y: -h, width: w, height: h)
            UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut]) {
                self.currentLabel.frame = CGRect(x: 0, y: h, width: w, height: h)
                self.nextLabel.frame = CGRect(x: 0, y: 0, width: w, height: h)
            } completion: { _ in
                self.currentLabel.text = String(newCharacter)
                self.currentLabel.frame = CGRect(x: 0, y: 0, width: w, height: h)
                self.nextLabel.isHidden = true
                completion?()
            }
        }
    }

    func animateIn(
        direction: AnimationDirection,
        duration: TimeInterval = 0.3,
        completion: (() -> Void)? = nil
    ) {
        nextLabel.isHidden = true
        let h = containerView.bounds.height
        let w = containerView.bounds.width
        let startY: CGFloat = direction == .up ? h : -h
        currentLabel.frame = CGRect(x: 0, y: startY, width: w, height: h)

        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut]) {
            self.currentLabel.frame = CGRect(x: 0, y: 0, width: w, height: h)
        } completion: { _ in
            completion?()
        }
    }

    func animateOut(
        direction: AnimationDirection,
        duration: TimeInterval = 0.3,
        completion: (() -> Void)? = nil
    ) {
        let h = containerView.bounds.height
        let w = containerView.bounds.width
        let endY: CGFloat = direction == .up ? -h : h

        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut]) {
            self.currentLabel.frame = CGRect(x: 0, y: endY, width: w, height: h)
        } completion: { _ in
            completion?()
        }
    }
}
