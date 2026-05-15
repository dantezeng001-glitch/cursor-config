---
name: dante-website-product-ui
description: >-
  生成消费电子产品官网风格的 HTML 页面。支持 4 种品牌设计风格（Shokz / Apple / Beats / Bose），覆盖产品详情页和购买页。输出单 HTML 文件，含完整 CSS，可直接浏览器打开。当用户提到"做产品页"、"做 listing page"、"做购买页"、"做官网页面"、"product page"、"listing page"，或要制作产品的 HTML 展示页面时使用。不适用于 PPT（走 dante-shokz-ppt）、邮件/EDM、App 界面。
---

# 产品官网页面制作（多品牌风格）

> 把用户提供的产品资料拼装成一份品牌官网风格的单 HTML 页面。支持 Shokz / Apple / Beats / Bose 四种设计语言。

---

## 1. 触发与边界

### 适用场景

- 用户要做消费电子产品的"产品详情页"或"购买页"的 HTML
- 用户要求按某个品牌的官网风格制作
- 用户说"做个 listing"、"做产品页"、"按 Apple 风格做"

### 不适用

- PPT / 演示文稿 → `dante-shokz-ppt`
- 邮件 / EDM → 通用 skill
- App 界面 / 小程序 → 通用 frontend skill

---

## 2. 工作流（6 步）

### Step 0 · 选择品牌风格

问用户要用哪种设计语言。四种风格的核心差异：

| 风格 | 页面架构 | 视觉调性 | 文案风格 |
|------|---------|---------|---------|
| **Shokz** | 分离式：产品详情页 + 购买页 | 黑白灰极简，品牌橙点缀 | 短句断句 + 技术实证 |
| **Apple** | 分离式：营销页（沉浸滚动）+ 购买页（横滑货架） | 白底主导 + 深黑交替，电影感 | 诗意碎片 + 文字游戏，零感叹号 |
| **Beats** | 合体式：购买区在顶部 + 营销长卷跟随 | 深色主导，高对比，产品配色驱动 | 街头自信 + 数据大字报 |
| **Bose** | 合体式：sticky 购买条 + 叙事长卷，三明治结构 | 极度克制黑白灰，产品是唯一色彩 | 第二人称感官词汇，温暖高端 |

如果用户没指定，默认 **Shokz** 风格。

### Step 1 · 确认页面类型

根据所选风格提供对应选项：

| 风格 | 页面类型 A | 页面类型 B |
|------|-----------|-----------|
| Shokz | 产品详情页（/pages/） | 购买页（/products/） |
| Apple | 营销页（/airpods-max/ 风格） | 购买页（/shop/buy-* 风格） |
| Beats | 合体页（唯一类型） | — |
| Bose | 合体页（唯一类型） | — |

Beats / Bose 只有一种页面类型（购买 + 营销合一），无需选择。

### Step 2 · 收集输入

需要以下资料（至少一项）：

1. **Message House**（.md）— 产品定位、核心/辅助卖点、竞品对标
2. **FABE 卖点体系**（.md）— 每个卖点的 Feature / Advantage / Benefit / Evidence
3. **官网文案表**（Excel 同步的 .md）— 每个 section 的定稿文案
4. **SPEC 规格书** — 技术参数、续航数据、防水等级

如果用户只给 brief，先帮他整理成结构化的卖点列表，确认后再做页面。

### Step 3 · 拼装页面

1. 读取对应品牌的骨架 HTML（从 `assets/` 目录）
2. 读取对应品牌的 `page-structures` 确认 section 选配
3. 读取对应品牌的 `design-tokens` 确认颜色/字体/间距
4. 读取对应品牌的 `components` 选取需要的组件
5. 读取对应品牌的 `copy-patterns` 确认文案写法
6. 逐 section 填入内容，图片用描述性占位符 `[Image: 描述]`

### Step 4 · Section 选配

按产品层级决定 section 数量。参考各品牌 `page-structures` 文件中的层级矩阵。

### Step 5 · 自检

在交付前过一遍：

- [ ] CSS 变量只用对应品牌 `design-tokens` 定义的值
- [ ] 文案符合对应品牌 `copy-patterns` 的公式和禁用词
- [ ] 所有实验室数据带标注（`*` 或上标编号），底部有 footnote
- [ ] 响应式断点生效
- [ ] 文件可独立在浏览器打开
- [ ] （Shokz）产品名全大写；（Apple）产品名标准大小写
- [ ] （Beats）数据大字报的百分比/倍数带对比基准
- [ ] （Bose）叙事区块内零 CTA 按钮

---

## 3. 品牌设计硬规则速查

### Shokz

- 黑白灰主调，品牌橙（#e8491d）仅做 badge 点缀
- CTA 按钮：黑底白字，胶囊型（border-radius: 30px）
- Section 背景交替：白 → 浅灰 → 白 → 浅灰
- 图文交替：奇数文左图右，偶数图左文右
- Headline：`[特性短语]. [价值短句].`
- 完整规则见原始 references 文件（无前缀文件 = Shokz）

### Apple

- 白底 + 深黑交替（电影感节奏），产品图和链接蓝是唯一色彩
- CTA 按钮：蓝底白字胶囊（#0071e3），全圆角
- Hero 区不放 CTA 按钮——依赖滚动驱动
- Headline 必须有文字游戏（双关 / 押韵 / 文化引用）
- 正文 max-width 700px，即使容器全宽也居中约束
- 量化声明必带基准："up to 1.5x more…than previous generation"

### Beats

- 深色主导，高对比，产品配色驱动
- CTA 按钮："ADD TO BAG" 全大写，胶囊型
- Category Tag（全大写小字标签）置于每个 H2 上方
- 数据大字报（48-72px 超大数字）是核心视觉锤
- 文案口语化、自信直述，每段 ≤ 3 句

### Bose

- 极度克制黑白灰，无品牌强调色
- CTA 按钮：黑色填充 + 白字，微圆角（4px）——全站唯一实心按钮
- Sticky 购买条贯穿全程（滚动后底部激活）
- BoseCare 保修选择器集成在购买面板
- 叙事区块零 CTA，保持品牌沉浸感
- 文案用第二人称 + 感官动词（"sink deeper" / "a hug for your ears"）

---

## 4. 参考文件索引

### Shokz（默认风格，文件无前缀）

| 文件 | 内容 | 何时读 |
|------|------|--------|
| [references/page-structures.md](references/page-structures.md) | 两类页面 section 模板 | Step 3 确认结构 |
| [references/design-tokens.md](references/design-tokens.md) | 颜色/字体/间距 CSS 变量 | Step 3 写 CSS |
| [references/component-library.md](references/component-library.md) | 12 个 HTML+CSS 组件 | Step 3 拼装组件 |
| [references/copy-patterns.md](references/copy-patterns.md) | 文案公式和禁用词 | Step 3 + Step 5 |
| [assets/product-page-skeleton.html](assets/product-page-skeleton.html) | 产品详情页骨架 | Step 3 起手 |
| [assets/listing-page-skeleton.html](assets/listing-page-skeleton.html) | 购买页骨架 | Step 3 起手 |

### Apple

| 文件 | 内容 | 何时读 |
|------|------|--------|
| [references/apple-page-structures.md](references/apple-page-structures.md) | 营销页 + 购买页 section 模板 | Step 3 确认结构 |
| [references/apple-design-tokens.md](references/apple-design-tokens.md) | 深浅交替颜色/clamp 字号/布局 | Step 3 写 CSS |
| [references/apple-components.md](references/apple-components.md) | 10 个 HTML+CSS 组件 | Step 3 拼装组件 |
| [references/apple-copy-patterns.md](references/apple-copy-patterns.md) | 诗意标题公式/CTA 规则 | Step 3 + Step 5 |
| [assets/apple-product-page-skeleton.html](assets/apple-product-page-skeleton.html) | 营销页骨架 | Step 3 起手 |
| [assets/apple-buy-page-skeleton.html](assets/apple-buy-page-skeleton.html) | 购买页骨架 | Step 3 起手 |

### Beats

| 文件 | 内容 | 何时读 |
|------|------|--------|
| [references/beats-page-structures.md](references/beats-page-structures.md) | 合体页 section 模板 | Step 3 确认结构 |
| [references/beats-design-tokens.md](references/beats-design-tokens.md) | 深色调/大字报字号/布局 | Step 3 写 CSS |
| [references/beats-components.md](references/beats-components.md) | 11 个 HTML+CSS 组件 | Step 3 拼装组件 |
| [references/beats-copy-patterns.md](references/beats-copy-patterns.md) | 街头文案/大字报规则 | Step 3 + Step 5 |
| [assets/beats-product-page-skeleton.html](assets/beats-product-page-skeleton.html) | 合体页骨架 | Step 3 起手 |

### Bose

| 文件 | 内容 | 何时读 |
|------|------|--------|
| [references/bose-page-structures.md](references/bose-page-structures.md) | 三明治结构 section 模板 | Step 3 确认结构 |
| [references/bose-design-tokens.md](references/bose-design-tokens.md) | 克制色彩/几何字体/微圆角 | Step 3 写 CSS |
| [references/bose-components.md](references/bose-components.md) | 10 个 HTML+CSS 组件 | Step 3 拼装组件 |
| [references/bose-copy-patterns.md](references/bose-copy-patterns.md) | 感官文案/Trust Bar/BoseCare | Step 3 + Step 5 |
| [assets/bose-product-page-skeleton.html](assets/bose-product-page-skeleton.html) | 合体页骨架 | Step 3 起手 |

---

## 5. 输出规范

- 单个 `.html` 文件，CSS 内联在 `<style>` 中
- 文件命名：`[ProductName]-[PageType].html`，如 `OpenMeet2-Listing-Page.html`
- 图片用描述性占位符：`[Image: lifestyle shot — person wearing headset at desk]`
- 占位符格式统一：`[方括号内写内容描述]`
- 价格如未确认写 `$XXX.XX`，数据如未确认写 `XX` 并标注 `[awaiting confirmation]`

---

## 6. 各风格页面类型对比

| 维度 | Shokz 详情页 | Shokz 购买页 | Apple 营销页 | Apple 购买页 | Beats 合体页 | Bose 合体页 |
|------|-------------|-------------|-------------|-------------|-------------|-------------|
| Hero | 居中文字 | 左图右购买 | 全屏深色 | "Shop" 标题 | 上图下购买 | 左图右购买 |
| 购买功能 | 无 | Add to Cart | 无 | Buy 按钮 | ADD TO BAG | Add to Cart + BoseCare |
| 背景节奏 | 白灰交替 | 白灰交替 | 深浅交替 | 全浅色 | 深浅强交替 | 深浅交替 |
| Sticky 购买 | 无 | 无 | 无 | 无 | 无 | 底部条 |
| FAQ | 无 | 4 类手风琴 | 无 | 无 | 5-12 题 | 10-12 题 |
| CTA 风格 | 黑底白字 | 黑底白字 | 蓝底白字 | 蓝底白字 | 黑/白大写 | 黑底白字微圆角 |
| 数据展示 | Stat cards | Stat cards | Data callouts | — | 大字报 | 叙事内嵌 |
