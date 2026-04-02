//
//  ViewController.swift
//  TextUpdateAnimationDemo
//
//  Created by RunFor on 2026/4/2.
//

import UIKit

// MARK: - Character Cell
class CharacterCell: UICollectionViewCell {
    static let reuseIdentifier = "CharacterCell"

    // 裁剪容器，防止动画时内容溢出
    private let containerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // 当前显示的Label
    private let currentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()

    // 下一个显示的Label（用于动画）
    private let nextLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()

    private var cellHeight: CGFloat = 60

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(currentLabel)
        containerView.addSubview(nextLabel)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 使用frame布局，避免与约束冲突
        let bounds = containerView.bounds
        let labelFrame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        currentLabel.frame = labelFrame
        nextLabel.frame = labelFrame.offsetBy(dx: 0, dy: cellHeight)
    }

    func configure(with character: Character, cellHeight: CGFloat) {
        self.cellHeight = cellHeight
        currentLabel.text = String(character)
        nextLabel.isHidden = true
        currentLabel.isHidden = false
        setNeedsLayout()
        layoutIfNeeded()
    }

    // 执行滚动动画：旧字符向上滚出，新字符从底部滚入
    func animateTo(newCharacter: Character, direction: AnimationDirection = .up, completion: (() -> Void)? = nil) {
        nextLabel.text = String(newCharacter)
        nextLabel.isHidden = false

        let animationDuration: TimeInterval = 0.3
        let bounds = containerView.bounds

        switch direction {
        case .up:
            // 向上滚动：旧字符向上滚出，新字符从底部滚入
            currentLabel.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
            nextLabel.frame = CGRect(x: 0, y: bounds.height, width: bounds.width, height: bounds.height)

            UIView.animate(withDuration: animationDuration, delay: 0, options: [.curveEaseInOut], animations: {
                self.currentLabel.frame = CGRect(x: 0, y: -bounds.height, width: bounds.width, height: bounds.height)
                self.nextLabel.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
            }) { _ in
                self.currentLabel.text = String(newCharacter)
                self.currentLabel.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
                self.nextLabel.isHidden = true
                completion?()
            }

        case .down:
            // 向下滚动：旧字符向下滚出，新字符从顶部滚入
            currentLabel.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
            nextLabel.frame = CGRect(x: 0, y: -bounds.height, width: bounds.width, height: bounds.height)

            UIView.animate(withDuration: animationDuration, delay: 0, options: [.curveEaseInOut], animations: {
                self.currentLabel.frame = CGRect(x: 0, y: bounds.height, width: bounds.width, height: bounds.height)
                self.nextLabel.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
            }) { _ in
                self.currentLabel.text = String(newCharacter)
                self.currentLabel.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
                self.nextLabel.isHidden = true
                completion?()
            }
        }
    }

    enum AnimationDirection {
        case up      // 旧到新（向上滚动）
        case down    // 新到旧（向下滚动）
    }
}

// MARK: - ViewController
class ViewController: UIViewController {

    private var collectionView: UICollectionView!
    private var characters: [Character] = []
    private let cellHeight: CGFloat = 60
    private let cellWidth: CGFloat = 30

    private var currentText = "2026年4月"
    private var isAnimating = false  // 动画状态标志

    // 控制按钮
    private let prevButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("上一月", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("下一月", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let currentDateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateCharacters(from: currentText)
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        // 创建布局
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width: cellWidth, height: cellHeight)

        // 创建CollectionView
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CharacterCell.self, forCellWithReuseIdentifier: CharacterCell.reuseIdentifier)
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(collectionView)
        view.addSubview(prevButton)
        view.addSubview(nextButton)
        view.addSubview(currentDateLabel)

        NSLayoutConstraint.activate([
            collectionView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            collectionView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            collectionView.heightAnchor.constraint(equalToConstant: cellHeight),
            collectionView.widthAnchor.constraint(equalToConstant: cellWidth * 8), // 最大支持8个字符

            prevButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            prevButton.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 40),

            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            nextButton.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 40),

            currentDateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            currentDateLabel.topAnchor.constraint(equalTo: prevButton.bottomAnchor, constant: 20)
        ])

        prevButton.addTarget(self, action: #selector(prevMonthTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextMonthTapped), for: .touchUpInside)

        currentDateLabel.text = "当前显示: \(currentText)"
    }

    private func updateCharacters(from text: String) {
        characters = Array(text)
        collectionView.reloadData()
    }

    // 更新文字并执行动画
    private func updateText(to newText: String, direction: CharacterCell.AnimationDirection = .up) {
        guard newText != currentText, !isAnimating else { return }

        isAnimating = true  // 开始动画，设置标志

        let newCharacters = Array(newText)
        let oldCharacters = characters

        // 更新数据源
        characters = newCharacters

        // 找到所有变化的索引
        let maxLength = max(oldCharacters.count, newCharacters.count)
        var changedIndices: [Int] = []

        for i in 0..<maxLength {
            let oldChar = i < oldCharacters.count ? oldCharacters[i] : nil
            let newChar = i < newCharacters.count ? newCharacters[i] : nil

            if oldChar != newChar {
                changedIndices.append(i)
            }
        }

        // 使用 DispatchGroup 跟踪所有动画完成
        let animationGroup = DispatchGroup()

        // 如果长度变化，需要重新加载
        if oldCharacters.count != newCharacters.count {
            collectionView.reloadData()
            // 然后对新添加的cell做动画（只对数字做动画）
            DispatchQueue.main.async {
                for index in changedIndices {
                    if let cell = self.collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? CharacterCell {
                        if index < newCharacters.count {
                            let newChar = newCharacters[index]
                            // 只对数字做动画，"年"和"月"直接更新
                            if newChar.isNumber {
                                animationGroup.enter()
                                cell.animateTo(newCharacter: newChar, direction: direction) {
                                    animationGroup.leave()
                                }
                            } else {
                                cell.configure(with: newChar, cellHeight: self.cellHeight)
                            }
                        }
                    }
                }

                // 所有动画完成后重置标志
                animationGroup.notify(queue: .main) {
                    self.isAnimating = false
                }
            }
        } else {
            // 长度不变，只对变化的字符做动画
            for index in changedIndices {
                if let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? CharacterCell {
                    let newChar = newCharacters[index]
                    // 只对数字做动画，"年"和"月"直接更新
                    if newChar.isNumber {
                        animationGroup.enter()
                        cell.animateTo(newCharacter: newChar, direction: direction) {
                            animationGroup.leave()
                        }
                    } else {
                        cell.configure(with: newChar, cellHeight: cellHeight)
                    }
                }
            }

            // 所有动画完成后重置标志
            animationGroup.notify(queue: .main) {
                self.isAnimating = false
            }
        }

        currentText = newText
        currentDateLabel.text = "当前显示: \(currentText)"
    }

    @objc private func prevMonthTapped() {
        let newDate = calculateDate(offset: -1)
        updateText(to: newDate, direction: .down)
    }

    @objc private func nextMonthTapped() {
        let newDate = calculateDate(offset: 1)
        updateText(to: newDate, direction: .up)
    }

    // 计算偏移后的日期字符串
    private func calculateDate(offset: Int) -> String {
        // 解析当前日期
        var year = 2026
        var month = 4

        // 简单解析
        if currentText.contains("年") && currentText.contains("月") {
            let components = currentText.components(separatedBy: "年")
            if let y = Int(components.first ?? "") {
                year = y
            }
            let monthComponents = components.last?.components(separatedBy: "月")
            if let m = Int(monthComponents?.first ?? "") {
                month = m
            }
        }

        // 计算新日期
        month += offset
        if month > 12 {
            month = 1
            year += 1
        } else if month < 1 {
            month = 12
            year -= 1
        }

        return "\(year)年\(month)月"
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return characters.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CharacterCell.reuseIdentifier, for: indexPath) as! CharacterCell

        if indexPath.item < characters.count {
            cell.configure(with: characters[indexPath.item], cellHeight: cellHeight)
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // 根据字符类型调整宽度
        if indexPath.item < characters.count {
            let char = characters[indexPath.item]
            // 数字较窄，中文较宽
            if char.isNumber {
                return CGSize(width: 24, height: cellHeight)
            } else {
                return CGSize(width: 40, height: cellHeight)
            }
        }
        return CGSize(width: cellWidth, height: cellHeight)
    }
}
