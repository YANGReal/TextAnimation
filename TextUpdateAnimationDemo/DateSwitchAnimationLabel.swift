//
//  DateSwitchAnimationLabel.swift
//  TextUpdateAnimationDemo
//

import UIKit

class DateSwitchAnimationLabel: UIView {

    // MARK: - 公开类型

    enum DateFormat {
        case chineseYearMonth   // yyyy年M月
        case dashYearMonth      // yyyy-M
    }

    // MARK: - 公开属性

    var font: UIFont = .systemFont(ofSize: 40, weight: .bold) {
        didSet {
            currentCharViews.forEach {
                $0.font = font
                $0.characterHeight = characterHeight
            }
            reconfigure()
        }
    }

    var textColor: UIColor = .label {
        didSet {
            currentCharViews.forEach { $0.textColor = textColor }
        }
    }

    var dateFormat: DateFormat = .chineseYearMonth

    var animationDuration: TimeInterval = 0.3

    private(set) var currentText: String = ""

    // MARK: - 私有属性

    private var currentCharViews: [CharacterView] = []
    private var isAnimating = false
    private var pendingUpdate: (String, AnimationDirection)?

    // 字符高度基于字体行高
    private var characterHeight: CGFloat {
        return ceil(font.lineHeight * 1.2)
    }

    // MARK: - intrinsicContentSize

    override var intrinsicContentSize: CGSize {
        let totalWidth = currentCharViews.reduce(0.0) { $0 + $1.characterWidth }
        return CGSize(width: totalWidth, height: characterHeight)
    }

    // MARK: - 初始显示

    func configure(with text: String) {
        currentCharViews.forEach { $0.removeFromSuperview() }
        currentCharViews = []
        currentText = text

        var xOffset: CGFloat = 0
        let h = characterHeight
        for char in text {
            let view = CharacterView(character: char, font: font, textColor: textColor, height: h)
            let w = view.characterWidth
            view.frame = CGRect(x: xOffset, y: 0, width: w, height: h)
            addSubview(view)
            currentCharViews.append(view)
            xOffset += w
        }

        invalidateIntrinsicContentSize()
    }

    // MARK: - 带动画更新

    func update(to newText: String, direction: AnimationDirection) {
        guard newText != currentText else { return }

        if isAnimating {
            pendingUpdate = (newText, direction)
            return
        }

        isAnimating = true
        let oldText = currentText
        currentText = newText

        let oldChars = Array(oldText)
        let newChars = Array(newText)
        let newXPositions = computeXPositions(for: newChars)
        let diff = computeDiff(from: oldChars, to: newChars)

        print("[update] '\(oldText)' → '\(newText)'")
        for (i, char) in newChars.enumerated() {
            print("  char='\(char)' x=\(newXPositions[i]) width=\(characterWidth(for: char))")
        }

        let group = DispatchGroup()

        for change in diff {
            switch change {

            case .unchanged(let oi, let ni):
                let view = currentCharViews[oi]
                let newX = newXPositions[ni]
                if abs(view.frame.origin.x - newX) > 0.5 {
                    group.enter()
                    UIView.animate(withDuration: animationDuration, delay: 0, options: [.curveEaseInOut]) {
                        view.frame.origin.x = newX
                    } completion: { _ in
                        group.leave()
                    }
                }

            case .changed(let oi, let ni, let newChar):
                let view = currentCharViews[oi]
                let newX = newXPositions[ni]
                group.enter()
                UIView.animate(withDuration: animationDuration, delay: 0, options: [.curveEaseInOut]) {
                    view.frame.origin.x = newX
                }
                view.animateTo(newCharacter: newChar, direction: direction, duration: animationDuration) {
                    group.leave()
                }

            case .inserted(let ni, let char):
                let h = characterHeight
                let view = CharacterView(character: char, font: font, textColor: textColor, height: h)
                let w = view.characterWidth
                view.frame = CGRect(x: newXPositions[ni], y: 0, width: w, height: h)
                addSubview(view)
                group.enter()
                DispatchQueue.main.async {
                    view.animateIn(direction: direction, duration: self.animationDuration) {
                        group.leave()
                    }
                }

            case .removed(let oi):
                let view = currentCharViews[oi]
                group.enter()
                view.animateOut(direction: direction, duration: animationDuration) {
                    view.removeFromSuperview()
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.rebuildCurrentViews()
            self.invalidateIntrinsicContentSize()
            self.isAnimating = false

            if let pending = self.pendingUpdate {
                self.pendingUpdate = nil
                self.update(to: pending.0, direction: pending.1)
            }
        }
    }

    // MARK: - 私有辅助

    private func reconfigure() {
        guard !currentText.isEmpty else { return }
        configure(with: currentText)
    }

    private func characterWidth(for character: Character) -> CGFloat {
        let scalar = character.unicodeScalars.first!.value
        let isCJK = (scalar >= 0x4E00 && scalar <= 0x9FFF)
                 || (scalar >= 0x3000 && scalar <= 0x303F)
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

    private func computeXPositions(for chars: [Character]) -> [CGFloat] {
        var positions: [CGFloat] = []
        var x: CGFloat = 0
        for char in chars {
            positions.append(x)
            x += characterWidth(for: char)
        }
        return positions
    }

    private func rebuildCurrentViews() {
        let activeViews = subviews
            .compactMap { $0 as? CharacterView }
            .sorted { $0.frame.origin.x < $1.frame.origin.x }
        currentCharViews = activeViews
    }

    // MARK: - 泛化 diff（公共前缀/后缀算法）

    private enum ChangeDescriptor {
        case unchanged(oldIndex: Int, newIndex: Int)
        case changed(oldIndex: Int, newIndex: Int, newChar: Character)
        case inserted(newIndex: Int, char: Character)
        case removed(oldIndex: Int)
    }

    private func computeDiff(from old: [Character], to new: [Character]) -> [ChangeDescriptor] {
        var result: [ChangeDescriptor] = []

        // 1. 计算公共前缀长度
        var prefixLen = 0
        while prefixLen < old.count && prefixLen < new.count && old[prefixLen] == new[prefixLen] {
            prefixLen += 1
        }

        // 2. 计算公共后缀长度（不超过剩余部分）
        var suffixLen = 0
        while suffixLen < old.count - prefixLen
                && suffixLen < new.count - prefixLen
                && old[old.count - 1 - suffixLen] == new[new.count - 1 - suffixLen] {
            suffixLen += 1
        }

        // 3. 前缀段：均为 unchanged（x 坐标可能位移）
        for i in 0..<prefixLen {
            result.append(.unchanged(oldIndex: i, newIndex: i))
        }

        // 4. 变化区
        let oldMid = Array(old[prefixLen..<old.count - suffixLen])
        let newMid = Array(new[prefixLen..<new.count - suffixLen])
        let oldMidStart = prefixLen
        let newMidStart = prefixLen

        if oldMid.count == newMid.count {
            for j in 0..<oldMid.count {
                let oi = oldMidStart + j
                let ni = newMidStart + j
                if oldMid[j] == newMid[j] {
                    result.append(.unchanged(oldIndex: oi, newIndex: ni))
                } else {
                    result.append(.changed(oldIndex: oi, newIndex: ni, newChar: newMid[j]))
                }
            }
        } else if newMid.count > oldMid.count {
            // 字符数增加（9→10）：前面插入，后面 changed
            let diff = newMid.count - oldMid.count
            for j in 0..<diff {
                result.append(.inserted(newIndex: newMidStart + j, char: newMid[j]))
            }
            for j in 0..<oldMid.count {
                let oi = oldMidStart + j
                let ni = newMidStart + diff + j
                if oldMid[j] == newMid[diff + j] {
                    result.append(.unchanged(oldIndex: oi, newIndex: ni))
                } else {
                    result.append(.changed(oldIndex: oi, newIndex: ni, newChar: newMid[diff + j]))
                }
            }
        } else {
            // 字符数减少（12→1）：前面删除，后面 changed
            let diff = oldMid.count - newMid.count
            for j in 0..<diff {
                result.append(.removed(oldIndex: oldMidStart + j))
            }
            for j in 0..<newMid.count {
                let oi = oldMidStart + diff + j
                let ni = newMidStart + j
                if oldMid[diff + j] == newMid[j] {
                    result.append(.unchanged(oldIndex: oi, newIndex: ni))
                } else {
                    result.append(.changed(oldIndex: oi, newIndex: ni, newChar: newMid[j]))
                }
            }
        }

        // 5. 后缀段：均为 unchanged（x 坐标可能位移）
        for i in 0..<suffixLen {
            let oi = old.count - suffixLen + i
            let ni = new.count - suffixLen + i
            result.append(.unchanged(oldIndex: oi, newIndex: ni))
        }

        return result
    }
}
