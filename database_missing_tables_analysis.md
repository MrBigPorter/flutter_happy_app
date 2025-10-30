# 数据库设计补充分析报告

## 📊 对比分析：JSON 数据 vs 数据库文档

基于 `assets/data/` 目录下的 JSON 文件分析，以下是**数据库设计文档中遗漏的表**：

---

## ❌ 遗漏的表（需要补充）

### 1. **banners - 横幅广告表**

**来源：** `bannersList.json`

**用途：** 存储首页和各页面的横幅广告/轮播图

```sql
CREATE TABLE banners (
    banner_id BIGINT PRIMARY KEY COMMENT '横幅ID（雪花ID）',

    -- 基本信息
    title VARCHAR(200) COMMENT '横幅标题',
    banner_img_url VARCHAR(255) NOT NULL COMMENT '横幅图片URL',
    video_url VARCHAR(255) COMMENT '视频URL',
    file_type TINYINT DEFAULT 1 COMMENT '文件类型: 1-图片 2-视频',

    -- 分类与位置
    banner_cate TINYINT NOT NULL COMMENT '横幅分类: 1-首页 2-活动页 3-产品页',
    position TINYINT DEFAULT 0 COMMENT '显示位置: 0-顶部 1-中部 2-底部',
    sort_type TINYINT DEFAULT 1 COMMENT '排序类型',
    sort_order INT DEFAULT 0 COMMENT '排序值（越小越靠前）',

    -- 跳转配置
    jump_cate TINYINT COMMENT '跳转类型: 1-无跳转 2-APP内页 3-产品详情 5-外部链接',
    jump_url VARCHAR(500) COMMENT '跳转URL',
    related_title_id INT COMMENT '关联产品ID',

    -- 显示配置
    show_type TINYINT DEFAULT 1 COMMENT '展示类型: 1-单图 2-轮播',
    img_style_type TINYINT DEFAULT 0 COMMENT '图片样式类型',
    grid_id BIGINT DEFAULT 0 COMMENT '宫格组ID（轮播组）',

    -- 时间配置
    activity_at_start BIGINT COMMENT '活动开始时间戳',
    activity_at_end BIGINT COMMENT '活动结束时间戳',

    -- 状态
    state TINYINT DEFAULT 1 COMMENT '状态: 0-禁用 1-启用',
    valid_state TINYINT DEFAULT 1 COMMENT '有效状态: 0-无效 1-有效',

    -- 管理
    created_by VARCHAR(50) COMMENT '创建人',
    updated_by VARCHAR(50) COMMENT '更新人',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    INDEX idx_banner_cate(banner_cate),
    INDEX idx_position(position),
    INDEX idx_state(state),
    INDEX idx_sort(sort_order),
    INDEX idx_activity_time(activity_at_start, activity_at_end)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='横幅广告表';
```

**关键字段说明：**
- `banner_array`: 支持多图轮播（JSON数组）
- `grid_id`: 用于分组管理轮播图
- `jump_cate`: 控制点击后的跳转行为

---

### 2. **advertisements - 广告位表**

**来源：** `advertiseList.json`

**用途：** 存储应用内的广告位配置（与横幅不同，这是独立的广告模块）

```sql
CREATE TABLE advertisements (
    ad_id BIGINT PRIMARY KEY COMMENT '广告ID（雪花ID）',

    -- 基本信息
    title VARCHAR(200) COMMENT '广告标题',
    ad_img_url VARCHAR(255) NOT NULL COMMENT '广告图片URL',
    video_url VARCHAR(255) COMMENT '视频URL',
    file_type TINYINT DEFAULT 1 COMMENT '文件类型: 1-图片 2-视频',

    -- 位置配置
    ad_position TINYINT NOT NULL COMMENT '广告位置: 1-首页顶部 2-首页中部 3-分类页 4-详情页',
    sort_order INT DEFAULT 0 COMMENT '排序值',

    -- 跳转配置
    jump_cate TINYINT COMMENT '跳转类型',
    jump_url VARCHAR(500) COMMENT '跳转URL',
    related_id BIGINT COMMENT '关联业务ID',

    -- 时间配置
    start_time BIGINT NOT NULL COMMENT '投放开始时间',
    end_time BIGINT NOT NULL COMMENT '投放结束时间',

    -- 状态
    status TINYINT DEFAULT 1 COMMENT '状态: 0-禁用 1-启用',

    -- 统计
    view_count INT DEFAULT 0 COMMENT '曝光次数',
    click_count INT DEFAULT 0 COMMENT '点击次数',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    INDEX idx_position(ad_position),
    INDEX idx_status(status),
    INDEX idx_time(start_time, end_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='广告位表';
```

---

### 3. **help_faqs - 常见问题表**

**来源：** `helpFaqsList.json`

**用途：** 存储帮助中心的常见问题和答案

```sql
CREATE TABLE help_faqs (
    faq_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '问题ID',

    -- 分类
    category_id INT NOT NULL COMMENT '分类ID',
    category_content VARCHAR(200) COMMENT '分类名称',

    -- 问题内容
    question TEXT NOT NULL COMMENT '问题描述',
    answer TEXT NOT NULL COMMENT '答案/解决方案',

    -- 多语言
    question_en TEXT COMMENT '英文问题',
    answer_en TEXT COMMENT '英文答案',

    -- 排序
    sort_order INT DEFAULT 0 COMMENT '排序值',

    -- 状态
    status TINYINT DEFAULT 1 COMMENT '状态: 0-禁用 1-启用',
    is_hot TINYINT DEFAULT 0 COMMENT '是否热门: 0-否 1-是',

    -- 统计
    view_count INT DEFAULT 0 COMMENT '查看次数',
    helpful_count INT DEFAULT 0 COMMENT '有帮助次数',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    INDEX idx_category(category_id),
    INDEX idx_status(status),
    INDEX idx_is_hot(is_hot),
    INDEX idx_sort(sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='常见问题表';
```

---

### 4. **help_contacts - 客服联系方式表**

**来源：** `helpContactList.json`

**用途：** 存储多渠道客服联系方式

```sql
CREATE TABLE help_contacts (
    contact_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '联系方式ID',

    -- 联系方式
    contact_type TINYINT NOT NULL COMMENT '联系类型: 1-在线客服 2-邮箱 3-电话 4-社交媒体',
    contact_name VARCHAR(100) NOT NULL COMMENT '联系方式名称',
    contact_value VARCHAR(255) NOT NULL COMMENT '联系方式值',
    contact_icon VARCHAR(255) COMMENT '图标URL',

    -- 社交媒体链接
    social_platform VARCHAR(50) COMMENT '社交平台: Facebook/Twitter/Instagram',
    social_url VARCHAR(500) COMMENT '社交媒体链接',

    -- 显示配置
    display_text VARCHAR(200) COMMENT '显示文字',
    display_order INT DEFAULT 0 COMMENT '显示顺序',

    -- 工作时间
    working_hours VARCHAR(200) COMMENT '工作时间说明',
    is_24h TINYINT DEFAULT 0 COMMENT '是否24小时: 0-否 1-是',

    -- 状态
    status TINYINT DEFAULT 1 COMMENT '状态: 0-禁用 1-启用',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    INDEX idx_type(contact_type),
    INDEX idx_status(status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='客服联系方式表';
```

---

### 5. **work_order_types - 工单类型表**

**来源：** `userWorkOrderWorkOrderType.json`

**用途：** 存储工单/客服问题的分类类型

```sql
CREATE TABLE work_order_types (
    type_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '类型ID',

    -- 类型信息
    type_name VARCHAR(100) NOT NULL COMMENT '类型名称',
    type_name_en VARCHAR(100) COMMENT '英文名称',
    type_code VARCHAR(50) UNIQUE COMMENT '类型代码',

    -- 描述
    description TEXT COMMENT '类型描述',
    icon VARCHAR(255) COMMENT '图标URL',

    -- 优先级
    default_priority TINYINT DEFAULT 2 COMMENT '默认优先级: 1-高 2-中 3-低',
    default_urgency TINYINT DEFAULT 1 COMMENT '默认紧急度',

    -- 处理配置
    sla_hours INT COMMENT 'SLA响应时间（小时）',
    auto_assign TINYINT DEFAULT 0 COMMENT '是否自动分配: 0-否 1-是',

    -- 排序
    sort_order INT DEFAULT 0 COMMENT '排序值',

    -- 状态
    status TINYINT DEFAULT 1 COMMENT '状态: 0-禁用 1-启用',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    INDEX idx_status(status),
    INDEX idx_sort(sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='工单类型表';
```

**常见工单类型：**
- Result Issue（结果问题）
- Payment Issue（支付问题）
- Prize Delivery（奖品配送）
- Account Issue（账户问题）
- Technical Support（技术支持）

---

### 6. **work_orders - 工单表**

**来源：** `userWorkOrderList.json`, `userWorkOrderCreate.json`

**用途：** 存储用户提交的工单/客服问题（比 customer_service_sessions 更正式）

```sql
CREATE TABLE work_orders (
    work_order_id BIGINT PRIMARY KEY COMMENT '工单ID（雪花ID）',
    work_order_no VARCHAR(50) UNIQUE NOT NULL COMMENT '工单编号',
    user_id BIGINT NOT NULL COMMENT '用户ID',

    -- 工单信息
    work_order_type_id INT NOT NULL COMMENT '工单类型ID',
    work_order_type_name VARCHAR(100) COMMENT '工单类型名称',

    -- 问题描述
    problem_describe TEXT NOT NULL COMMENT '问题描述',
    problem_images JSON COMMENT '问题图片列表（JSON数组）',

    -- 回复信息
    reply_content TEXT COMMENT '客服回复内容',
    reply_images JSON COMMENT '回复图片列表',

    -- 状态
    reply_state TINYINT DEFAULT 1 COMMENT '回复状态: 1-待处理 2-处理中 3-已回复 4-已关闭',
    urgency TINYINT DEFAULT 1 COMMENT '紧急度: 1-普通 2-紧急 3-非常紧急',

    -- 处理人
    handler_id BIGINT COMMENT '处理人ID（客服ID）',
    handler_name VARCHAR(100) COMMENT '处理人名称',

    -- 关联信息
    related_order_id BIGINT COMMENT '关联订单ID',
    related_type VARCHAR(50) COMMENT '关联业务类型',

    -- 评价
    rating TINYINT COMMENT '评分（1-5星）',
    feedback TEXT COMMENT '用户反馈',

    -- 时间
    created_at BIGINT NOT NULL COMMENT '创建时间戳',
    updated_at BIGINT COMMENT '更新时间戳',
    replied_at BIGINT COMMENT '回复时间戳',
    closed_at BIGINT COMMENT '关闭时间戳',

    INDEX idx_user(user_id),
    INDEX idx_work_order_no(work_order_no),
    INDEX idx_type(work_order_type_id),
    INDEX idx_reply_state(reply_state),
    INDEX idx_urgency(urgency),
    INDEX idx_created_at(created_at),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (work_order_type_id) REFERENCES work_order_types(type_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='工单表';
```

**与 customer_service_sessions 的区别：**
- `work_orders`: 更正式的问题工单系统，有编号、分类、SLA
- `customer_service_sessions`: 在线聊天/即时沟通

---

### 7. **provinces - 省份配置表**

**来源：** `provinceCfg.json`, `getCityCfg.json`

**用途：** 存储菲律宾的省份和城市配置（用于地址选择）

```sql
CREATE TABLE provinces (
    province_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '省份ID',
    province_name VARCHAR(100) NOT NULL COMMENT '省份名称',
    province_code VARCHAR(50) COMMENT '省份代码',

    -- 排序
    sort_order INT DEFAULT 0 COMMENT '排序值',

    -- 状态
    status TINYINT DEFAULT 1 COMMENT '状态: 0-禁用 1-启用',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    INDEX idx_status(status),
    INDEX idx_province_name(province_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='省份配置表';
```

---

### 8. **cities - 城市配置表**

```sql
CREATE TABLE cities (
    city_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '城市ID',
    province_id INT NOT NULL COMMENT '省份ID',
    city_name VARCHAR(100) NOT NULL COMMENT '城市名称',
    city_code VARCHAR(50) COMMENT '城市代码',
    postal_code VARCHAR(10) COMMENT '邮政编码',

    -- 排序
    sort_order INT DEFAULT 0 COMMENT '排序值',

    -- 状态
    status TINYINT DEFAULT 1 COMMENT '状态: 0-禁用 1-启用',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    INDEX idx_province(province_id),
    INDEX idx_status(status),
    INDEX idx_city_name(city_name),
    FOREIGN KEY (province_id) REFERENCES provinces(province_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='城市配置表';
```

---

### 9. **receive_payment_methods - 收款方式表**

**来源：** `userReceivePaymentList.json`, `userReceivePaymentInsert.json`

**用途：** 存储用户的收款方式（用于提现、中奖现金发放）

```sql
CREATE TABLE receive_payment_methods (
    receive_payment_id BIGINT PRIMARY KEY COMMENT '收款方式ID（雪花ID）',
    user_id BIGINT NOT NULL COMMENT '用户ID',

    -- 收款方式
    receive_payment_type TINYINT NOT NULL COMMENT '收款类型: 1-GCash 2-PayMaya 3-银行卡 4-其他',
    payment_name VARCHAR(100) NOT NULL COMMENT '账户名',
    payment_account VARCHAR(100) NOT NULL COMMENT '账号',

    -- 银行信息（银行卡用）
    bank_type VARCHAR(50) COMMENT '银行名称',
    bank_branch VARCHAR(200) COMMENT '支行名称',
    swift_code VARCHAR(20) COMMENT 'SWIFT代码',

    -- 状态
    is_default TINYINT DEFAULT 0 COMMENT '是否默认: 0-否 1-是',
    verified TINYINT DEFAULT 0 COMMENT '是否已验证: 0-否 1-是',
    status TINYINT DEFAULT 1 COMMENT '状态: 0-已删除 1-正常',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    INDEX idx_user(user_id),
    INDEX idx_is_default(user_id, is_default),
    INDEX idx_status(status),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='收款方式表';
```

**与 bank_cards 的区别：**
- `bank_cards`: 用户绑定的银行卡（主要用于充值）
- `receive_payment_methods`: 收款方式（主要用于提现和中奖现金发放，支持更多渠道）

---

### 10. **treasure_visit_records - 产品访问收藏记录表**

**来源：** `treasureVisitCollect.json`

**用途：** 记录用户访问和收藏产品的行为

```sql
CREATE TABLE treasure_visit_records (
    record_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '记录ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    treasure_id BIGINT NOT NULL COMMENT '产品ID',

    -- 行为类型
    action_type TINYINT NOT NULL COMMENT '行为类型: 1-访问 2-收藏 3-取消收藏',

    -- 访问信息
    visit_duration INT COMMENT '访问时长（秒）',
    visit_from VARCHAR(50) COMMENT '访问来源: home/category/search',

    -- 收藏状态
    is_collected TINYINT DEFAULT 0 COMMENT '是否已收藏: 0-否 1-是',
    collected_at BIGINT COMMENT '收藏时间戳',

    action_time BIGINT NOT NULL COMMENT '行为时间戳',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',

    INDEX idx_user(user_id),
    INDEX idx_treasure(treasure_id),
    INDEX idx_action_type(action_type),
    INDEX idx_is_collected(user_id, is_collected),
    INDEX idx_action_time(action_time),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (treasure_id) REFERENCES treasures(treasure_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='产品访问收藏记录表';
```

---

### 11. **avatar_defaults - 默认头像表**

**来源：** `userAvatarDefaultList.json`

**用途：** 存储系统提供的默认头像列表

```sql
CREATE TABLE avatar_defaults (
    avatar_id INT PRIMARY KEY AUTO_INCREMENT COMMENT '头像ID',
    avatar_url VARCHAR(255) NOT NULL COMMENT '头像URL',
    avatar_name VARCHAR(100) COMMENT '头像名称',
    avatar_category VARCHAR(50) COMMENT '头像分类',

    -- 排序
    sort_order INT DEFAULT 0 COMMENT '排序值',

    -- 状态
    status TINYINT DEFAULT 1 COMMENT '状态: 0-禁用 1-启用',

    -- 统计
    use_count INT DEFAULT 0 COMMENT '使用次数',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    INDEX idx_status(status),
    INDEX idx_category(avatar_category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='默认头像表';
```

---

### 12. **homepage_statistics - 首页统计数据表**

**来源：** `homepageStatisticalData.json`

**用途：** 存储首页展示的实时统计数据

```sql
CREATE TABLE homepage_statistics (
    stat_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '统计ID',

    -- 统计类型
    stat_type VARCHAR(50) NOT NULL COMMENT '统计类型: total_users/active_draws/total_winners',
    stat_value BIGINT NOT NULL COMMENT '统计值',

    -- 显示配置
    display_label VARCHAR(100) COMMENT '显示标签',
    display_order INT DEFAULT 0 COMMENT '显示顺序',

    -- 时间
    stat_date DATE NOT NULL COMMENT '统计日期',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    UNIQUE KEY uk_type_date(stat_type, stat_date),
    INDEX idx_stat_date(stat_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='首页统计数据表';
```

---

## 🔄 需要调整的表

### 1. **customer_service_sessions** → 需要扩展

当前设计缺少 `work_order` 相关字段，建议添加：

```sql
-- 在 customer_service_sessions 表中添加
work_order_id BIGINT COMMENT '关联工单ID',
session_source TINYINT COMMENT '会话来源: 1-在线聊天 2-工单 3-电话',
```

---

## 📝 总结

### 已设计的表：33张 ✅
### 遗漏的表：12张 ❌

**建议补充的表：**

1. ✅ **banners** - 横幅广告表（必需）
2. ✅ **advertisements** - 广告位表（必需）
3. ✅ **help_faqs** - 常见问题表（必需）
4. ✅ **help_contacts** - 客服联系方式表（必需）
5. ✅ **work_order_types** - 工单类型表（必需）
6. ✅ **work_orders** - 工单表（必需）
7. ✅ **provinces** - 省份配置表（必需）
8. ✅ **cities** - 城市配置表（必需）
9. ✅ **receive_payment_methods** - 收款方式表（重要）
10. ✅ **treasure_visit_records** - 产品访问收藏记录表（可选）
11. ✅ **avatar_defaults** - 默认头像表（可选）
12. ✅ **homepage_statistics** - 首页统计数据表（可选）

### 最终建议表数量：**33 + 12 = 45张表**

---

## 🎯 优先级建议

### P0（必需）- 8张
- banners
- advertisements
- help_faqs
- help_contacts
- work_order_types
- work_orders
- provinces
- cities

### P1（重要）- 1张
- receive_payment_methods

### P2（可选）- 3张
- treasure_visit_records
- avatar_defaults
- homepage_statistics

---

> **报告生成时间：** 2025-01-21
> **分析依据：** assets/data/ 目录下的 JSON 接口数据
> **对比文档：** database_design.md
