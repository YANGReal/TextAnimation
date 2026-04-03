## 项目描述
### iOS时间文字更新动画研究

## 希望达成的效果
### 当时间发生变化时候（年份和月份），对应的文字从下到上滚动切换。例如：当文字"2026年4月"变成"2026年5月"时，文字4从底部蹲送到顶部消失，文字5从底部滚动出现到视图里。

## 目前思路
### 使用UICollectionView来显示文字，一个Cell对应一个文字，当对应文字更新时候，在Cell里做动画，Cell里应该有两个UILabel，一个显示变化
之前的文字，一个显示变化之后的文字，动画也应该是在这两个UILabel之间切换。

## 为什么需要做这个动画效果？
###直接设置UILabel的text属性，切换过于生硬，特别是时间切换，做这个动画是想在UI交互上体现时间变化的方向性。（从旧到新或者从新到旧）

## 示例iOS工程
### 在TextUpdateAnimationDemo/ViewController.swift里面编写代码

---

## 2026-04-03 开发记录

### 已完成内容

1. **基础动画效果** - 实现了数字滚动切换动画
   - 上一月：旧数字向上滚出，新数字从底部向上滚入（.down方向）
   - 下一月：旧数字向下滚出，新数字从顶部向下滚入（.up方向）

2. **非数字字符处理** - "年"和"月"保持静止，只有数字有滚动动画

3. **动画防抖** - 使用`isAnimating`标志和`DispatchGroup`防止快速点击导致的跳动

4. **Cell实现细节**
   - 使用`containerView`设置`clipsToBounds = true`防止内容溢出
   - 纯frame布局避免与Auto Layout约束冲突
   - 两个UILabel：`currentLabel`显示当前字符，`nextLabel`用于动画过渡

### 待解决问题

1. **长度变化动画** - 当月份从9→10或12→1时，文字长度发生变化，"月"字位置会突然跳动
   - 尝试方案：让"月"字也参与滚动动画（旧位置滚出，新位置滚入）
   - 问题：reloadData后旧cell不存在，无法做滚出动画
   - 需要更好的方案来处理这种情况

### 当前代码状态
- 基础功能完整，动画方向正确
- 长度变化时体验有待优化
- 明天继续优化9→10、12→1等临界情况的动画效果

---

## 2026-04-03 第二次更新

### 已完成：方案3 - 手动 Frame 管理替换 UICollectionView

**彻底解决了长度变化时"月"字跳动的问题。**

#### 新文件结构

```
TextUpdateAnimationDemo/
├── AnimationDirection.swift   # 顶层枚举（.up / .down）
├── CharacterView.swift        # 单字符 UIView，持久生命周期
├── TimeTextView.swift         # 字符容器，管理 diff + 动画编排
└── ViewController.swift       # 精简，只负责按钮和日期计算
```

#### 核心思路

- 放弃 UICollectionView，每个字符是一个持久 `CharacterView` 实例
- `TimeTextView.computeDiff` 按"年份前缀5位 + 月份段 + 月字后缀"三段语义 diff
- 每种变化类型对应不同动画：
  - `unchanged`：x 坐标位移动画（"月"字平移）
  - `changed`：原地垂直滚动 + x 位移并行
  - `inserted`：`animateIn` 从屏幕外滑入
  - `removed`：`animateOut` 滑出后 removeFromSuperview
- 快速点击用 `pendingUpdate` 队列排队处理

#### 当前代码状态
- 所有场景完美运行（1-12月正常切换、9→10、12→1、跨年）
- 动画流畅无跳动，快速点击不乱

---

## 2026-04-03 第三次更新

### 已完成：封装为 DateSwitchAnimationLabel

#### 新文件结构

```
TextUpdateAnimationDemo/
├── AnimationDirection.swift          # 顶层枚举（不变）
├── CharacterView.swift               # 改造：font/textColor/height 参数化，宽度动态计算
├── DateSwitchAnimationLabel.swift    # 新：封装好的可复用 UIView（替换 TimeTextView）
└── ViewController.swift              # 使用 DateSwitchAnimationLabel
```

#### 公开接口

```swift
let label = DateSwitchAnimationLabel()
label.font = .systemFont(ofSize: 32, weight: .medium)
label.textColor = .systemBlue
label.dateFormat = .dashYearMonth       // .chineseYearMonth 或 .dashYearMonth
label.configure(with: "2026-4")         // 初始化（无动画）
label.update(to: "2026-10", direction: .up)  // 带动画切换
```

#### 关键技术点
- diff 算法改为**公共前缀/后缀**泛化算法，不再硬编码"前5位"，支持任意格式
- 字符宽度改用 `UILabel.sizeThatFits` 动态测量，比 `NSString.size` 更准确
- `CharacterView` 的 font/textColor/height 全部由外部注入

### 待确认问题

1. **"年"字截断** - `NSString.size` + 4pt padding 仍截断，已改为 `UILabel.sizeThatFits` 方案，明天确认是否修复
