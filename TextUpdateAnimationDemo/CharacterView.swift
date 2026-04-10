//
//  CharacterView.swift
//  TextUpdateAnimationDemo
//

import UIKit

extension UIColor {
    static var randomColor: UIColor {
        UIColor(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            alpha: 0.4
        )
    }
}

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

    // 中文字符是正方形 em square，宽度直接用 pointSize；
    // ASCII 字符用 CTLine typographic bounds（advance width）
    var characterWidth: CGFloat {
        let scalar = character.unicodeScalars.first!.value
        let isCJK = (scalar >= 0x4E00 && scalar <= 0x9FFF)   // CJK 统一汉字
                 || (scalar >= 0x3000 && scalar <= 0x303F)    // CJK 标点
        if isCJK {
            return ceil(font.pointSize)
        }
        let str = String(character)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let attrStr = NSAttributedString(string: str, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attrStr)
        let width = CTLineGetTypographicBounds(line, nil, nil, nil)
        return ceil(CGFloat(width))
    }

    private let containerView: UIView = {
        let view = UIView()
        view.clipsToBounds = false  // 不整体裁切，由 layer mask 只裁垂直方向
        return view
    }()

    private let currentLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.backgroundColor = .randomColor
        return label
    }()

    private let nextLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.backgroundColor = .randomColor
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
        // label 比 CharacterView 宽 20pt（左右各 10pt），居中对齐，确保字符不被水平裁切
        let labelFrame = CGRect(x: -10, y: 0, width: w + 20, height: h)
        currentLabel.frame = labelFrame
        if nextLabel.isHidden {
            nextLabel.frame = CGRect(x: -10, y: h, width: w + 20, height: h)
        }

        // 只在垂直方向裁切，防止滚动动画溢出，水平方向不裁切
        let maskLayer = CALayer()
        maskLayer.frame = CGRect(x: -999, y: 0, width: w + 1998, height: h)
        maskLayer.backgroundColor = UIColor.black.cgColor
        layer.mask = maskLayer
    }

    func configure(character: Character) {
        self.character = character
        currentLabel.text = String(character)
        nextLabel.isHidden = true
        let h = bounds.height
        let w = bounds.width
        currentLabel.frame = CGRect(x: -10, y: 0, width: w + 20, height: h)
        nextLabel.frame = CGRect(x: -10, y: h, width: w + 20, height: h)
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
            currentLabel.frame = CGRect(x: -10, y: 0, width: w + 20, height: h)
            nextLabel.frame = CGRect(x: -10, y: h, width: w + 20, height: h)
            UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut]) {
                self.currentLabel.frame = CGRect(x: -10, y: -h, width: w + 20, height: h)
                self.nextLabel.frame = CGRect(x: -10, y: 0, width: w + 20, height: h)
            } completion: { _ in
                self.currentLabel.text = String(newCharacter)
                self.currentLabel.frame = CGRect(x: -10, y: 0, width: w + 20, height: h)
                self.nextLabel.isHidden = true
                completion?()
            }

        case .down:
            currentLabel.frame = CGRect(x: -10, y: 0, width: w + 20, height: h)
            nextLabel.frame = CGRect(x: -10, y: -h, width: w + 20, height: h)
            UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut]) {
                self.currentLabel.frame = CGRect(x: -10, y: h, width: w + 20, height: h)
                self.nextLabel.frame = CGRect(x: -10, y: 0, width: w + 20, height: h)
            } completion: { _ in
                self.currentLabel.text = String(newCharacter)
                self.currentLabel.frame = CGRect(x: -10, y: 0, width: w + 20, height: h)
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
        currentLabel.frame = CGRect(x: -10, y: startY, width: w + 20, height: h)

        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut]) {
            self.currentLabel.frame = CGRect(x: -10, y: 0, width: w + 20, height: h)
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
            self.currentLabel.frame = CGRect(x: -10, y: endY, width: w + 20, height: h)
        } completion: { _ in
            completion?()
        }
    }
}
