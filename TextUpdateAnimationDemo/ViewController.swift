//
//  ViewController.swift
//  TextUpdateAnimationDemo
//
//  Created by RunFor on 2026/4/2.
//

import UIKit

class ViewController: UIViewController {

    // MARK: - 示例：使用 DateSwitchAnimationLabel

    private let dateLabel: DateSwitchAnimationLabel = {
        let label = DateSwitchAnimationLabel()
        label.font = .systemFont(ofSize: 40, weight: .bold)
        label.textColor = .label
        label.dateFormat = .chineseYearMonth
        label.translatesAutoresizingMaskIntoConstraints = false
        label.clipsToBounds = true
        return label
    }()

    private var currentText = "2026年4月"

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

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        dateLabel.configure(with: currentText)
        currentDateLabel.text = "当前显示: \(currentText)"
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(dateLabel)
        view.addSubview(prevButton)
        view.addSubview(nextButton)
        view.addSubview(currentDateLabel)

        NSLayoutConstraint.activate([
            // dateLabel 宽度固定为最大字符宽度之和（约 280），高度由 intrinsicContentSize 决定
            dateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            dateLabel.widthAnchor.constraint(equalToConstant: 280),
            dateLabel.heightAnchor.constraint(equalToConstant: dateLabel.font.lineHeight * 1.2),

            prevButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            prevButton.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 40),

            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            nextButton.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 40),

            currentDateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            currentDateLabel.topAnchor.constraint(equalTo: prevButton.bottomAnchor, constant: 20)
        ])

        prevButton.addTarget(self, action: #selector(prevMonthTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextMonthTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func prevMonthTapped() {
        let newDate = calculateDate(offset: -1)
        updateText(to: newDate, direction: .down)
    }

    @objc private func nextMonthTapped() {
        let newDate = calculateDate(offset: 1)
        updateText(to: newDate, direction: .up)
    }

    private func updateText(to newText: String, direction: AnimationDirection) {
        guard newText != currentText else { return }
        currentText = newText
        currentDateLabel.text = "当前显示: \(currentText)"
        dateLabel.update(to: newText, direction: direction)
    }

    private func calculateDate(offset: Int) -> String {
        var year = 2026
        var month = 4

        if dateLabel.dateFormat == .chineseYearMonth,
           currentText.contains("年"), currentText.contains("月") {
            let parts = currentText.components(separatedBy: "年")
            if let y = Int(parts.first ?? "") { year = y }
            if let m = Int(parts.last?.components(separatedBy: "月").first ?? "") { month = m }
        } else if dateLabel.dateFormat == .dashYearMonth,
                  currentText.contains("-") {
            let parts = currentText.components(separatedBy: "-")
            if let y = Int(parts.first ?? "") { year = y }
            if let m = Int(parts.last ?? "") { month = m }
        }

        month += offset
        if month > 12 { month = 1; year += 1 }
        else if month < 1 { month = 12; year -= 1 }

        switch dateLabel.dateFormat {
        case .chineseYearMonth: return "\(year)年\(month)月"
        case .dashYearMonth:    return "\(year)-\(month)"
        }
    }
}
