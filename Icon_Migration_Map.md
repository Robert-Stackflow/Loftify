# Loftify Lucide 图标迁移清单与语义映射

更新时间：2026-08-24  
对应任务：`ICON-01`

## 1. 范围与原则

本清单覆盖 `lib/**/*.dart`、公共组件以及本地 `third-party/chewie/lib/**/*.dart`。统计对象包括 Material `Icons.*`、Cupertino `CupertinoIcons.*`、现有 `LucideIcons.*` 和 `assets/icon/*.png` 静态界面图标。

以下内容不作为普通界面图标迁移：

- `assets/lottie/*.json` 的 40 个自定义状态动画，包括加载、点赞、推荐、关注、明暗切换和庆祝动画；
- Loftify Logo、托盘 Logo、默认头像等产品标识或内容占位；
- `assets/illust/*`、`assets/mess/*` 等插画与内容装饰；
- 用户头像、帖子图片、装扮、远程 SVG 等用户或业务内容；
- 操作系统原生窗口按钮中不可替换的系统行为，但本地 `awesome_chewie` 自绘窗口按钮仍纳入迁移。

默认迁移规则：使用 Lucide 线性图标；选中、已点赞、已收藏等状态仍使用同一个 Lucide 轮廓，通过主题色、字重感、浅色底板、圆点或容器表达，不再切换到 Material 面性图标。只有后续 `ICON-03` 登记的受控 SVG 例外可以保留配对图形。

## 2. 2026-08-24 基线

| 范围 | Material | Cupertino | Lucide | 涉及文件 |
| --- | ---: | ---: | ---: | ---: |
| Loftify 业务与公共组件 `lib` | 254 处 / 115 个符号 | 0 | 22 处 / 14 个符号 | Material 40 个文件；Lucide 4 个文件 |
| 本地 `awesome_chewie` | 61 处 / 44 个符号 | 4 处 / 3 个符号 | 77 处 / 35 个符号 | Material 26 个文件；Cupertino 3 个文件；Lucide 24 个文件 |
| 合计 | 315 处，跨范围去重后 146 个 Material 符号 | 4 处 / 3 个符号 | 99 处 / 45 个符号 | — |

旧的 `assets/icon` 目录曾包含 51 张 PNG 界面图标（不含 `code.txt` 和 `run.py`）。`ICON-04` 迁移和回归完成后，运行路径已无引用；`ICON-05` 已删除整套染色位图、废弃常量和生成辅助文件。

迁移热点按引用数量排序：

1. `post_detail_screen.dart`：24 处；
2. `video_detail_screen.dart`、`user_detail_screen.dart`：各 23 处；
3. `about_setting_screen.dart`：15 处；
4. `general_post_item_builder.dart`：13 处；
5. `mine_screen.dart`：12 处；
6. `main_screen.dart`：11 处；
7. `setting_screen.dart`：9 处；
8. `panel_screen.dart`、`tag_detail_screen.dart`：各 8 处。

## 3. Material / Cupertino 到 Lucide 的语义映射

表中的目标名称必须存在于本地 `lucide_icons` 包。实际迁移时页面不直接引用目标常量，而应在 `ICON-02` 建立的统一语义组件中取用。

| 旧图标 | 语义键 | Lucide 目标 | 状态说明 |
| --- | --- | --- | --- |
| `Icons.access_alarm` | `alarm` | `alarmClock` | — |
| `Icons.access_time` | `time` | `clock` | — |
| `Icons.account_box` | `accountCard` | `squareUserRound` | — |
| `Icons.account_circle` | `accountCircle` | `circleUserRound` | — |
| `Icons.person_outline_rounded`, `Icons.person_rounded` | `person` | `userRound` | 选中态只改变颜色和底板 |
| `Icons.person_add_alt_1_rounded` | `personAdd` | `userPlus` | — |
| `Icons.add_circle` | `addCircle` | `circlePlus` | — |
| `Icons.add_rounded` | `add` | `plus` | — |
| `Icons.remove_rounded`, `Icons.horizontal_rule_rounded` | `remove` | `minus` | — |
| `Icons.alternate_email_rounded` | `at` | `atSign` | — |
| `Icons.mail_outline_rounded` | `mail` | `mail` | — |
| `Icons.phone_android_rounded` | `phone` | `smartphone` | — |
| `Icons.password_rounded` | `password` | `keyRound` | — |
| `Icons.card_membership_rounded` | `identityCard` | `badge` | 登录方式语义，不表达支付卡 |
| `Icons.credit_card` | `paymentCard` | `creditCard` | — |
| `Icons.verified_outlined` | `verified` | `badgeCheck` | — |
| `Icons.delete_outline_rounded` | `delete` | `trash2` | 危险色由操作语义提供 |
| `Icons.arrow_back`, `Icons.arrow_back_rounded` | `back` | `arrowLeft` | — |
| `Icons.arrow_downward`, `Icons.arrow_downward_rounded` | `arrowDown` | `arrowDown` | — |
| `Icons.arrow_forward`, `Icons.arrow_forward_rounded`, `Icons.arrow_right` | `forward` | `arrowRight` | — |
| `Icons.arrow_upward`, `Icons.arrow_upward_rounded` | `arrowUp` | `arrowUp` | — |
| `Icons.keyboard_arrow_down_rounded`, `Icons.expand_more` | `expand` | `chevronDown` | — |
| `Icons.keyboard_arrow_up_rounded` | `collapse` | `chevronUp` | — |
| `Icons.keyboard_arrow_left_rounded` | `previous` | `chevronLeft` | — |
| `Icons.keyboard_arrow_right_rounded` | `next` | `chevronRight` | — |
| `Icons.keyboard_double_arrow_left_rounded` | `previousPage` | `chevronsLeft` | — |
| `Icons.keyboard_double_arrow_right_rounded` | `nextPage` | `chevronsRight` | — |
| `Icons.article_outlined` | `article` | `fileText` | — |
| `Icons.edit_note_rounded` | `editNote` | `notebookPen` | — |
| `Icons.format_quote` | `quote` | `quote` | — |
| `Icons.copyright_rounded` | `copyright` | `copyright` | — |
| `Icons.copy_rounded` | `copy` | `copy` | 成功态可切换 `copyCheck` |
| `Icons.save_rounded` | `save` | `save` | — |
| `Icons.open_in_browser_rounded`, `Icons.open_in_new_rounded` | `externalLink` | `externalLink` | — |
| `Icons.share_rounded` | `share` | `share2` | — |
| `Icons.auto_awesome_outlined` | `sparkles` | `sparkles` | — |
| `Icons.auto_fix_high_outlined` | `magic` | `wandSparkles` | — |
| `Icons.color_lens_outlined` | `palette` | `palette` | — |
| `Icons.format_color_reset_rounded` | `clearStyle` | `eraser` | — |
| `Icons.merge_type_outlined` | `merge` | `gitMerge` | — |
| `Icons.commit_outlined` | `commit` | `gitCommitHorizontal` | — |
| `Icons.bug_report_outlined` | `bug` | `bug` | — |
| `Icons.block_rounded` | `blocked` | `ban` | 警告色由语义颜色提供 |
| `Icons.shield_outlined` | `shield` | `shield` | — |
| `Icons.flag_outlined` | `report` | `flag` | — |
| `Icons.error`, `Icons.error_outline`, `Icons.error_outline_rounded` | `error` | `circleAlert` | 错误色由状态提供 |
| `Icons.warning_amber_rounded` | `warning` | `triangleAlert` | — |
| `Icons.info_outline_rounded` | `info` | `info` | — |
| `Icons.contact_support_outlined` | `help` | `circleHelp` | — |
| `Icons.bookmark_outline_rounded`, `Icons.bookmark_rounded`, `Icons.bookmark_added_rounded`, `Icons.bookmark_add_outlined` | `bookmark` | `bookmark` | 收藏状态不换面性图标 |
| `Icons.bookmarks_outlined` | `bookmarks` | `libraryBig` | — |
| `Icons.favorite_border_rounded`, `Icons.favorite_rounded` | `favorite` | `heart` | 点赞状态不换面性图标 |
| `Icons.thumb_up`, `Icons.thumb_up_alt`, `Icons.thumb_up_off_alt`, `Icons.thumb_up_outlined`, `Icons.thumb_up_rounded` | `recommend` | `thumbsUp` | 推荐状态不换面性图标 |
| `Icons.star`, `Icons.star_border`, `Icons.star_border_purple500_rounded`, `Icons.star_border_rounded`, `Icons.star_rate_rounded`, `Icons.star_rounded` | `star` | `star` | 选中态用主题色或浅底板 |
| `Icons.star_half` | `starHalf` | `starHalf` | 仅评分显示允许半星 |
| `Icons.check_box`, `Icons.check_box_outline_blank`, `Icons.check_box_outline_blank_rounded` | `checkbox` | `square` / `squareCheckBig` | 使用同一网格的选中状态 |
| `Icons.check_circle_outline_rounded`, `Icons.check_circle_rounded` | `successCircle` | `circleCheck` | — |
| `Icons.check_rounded`, `Icons.done`, `Icons.done_rounded` | `check` | `check` | — |
| `Icons.done_all_rounded` | `checkAll` | `checkCheck` | — |
| `Icons.circle_outlined` | `circle` | `circle` | — |
| `Icons.clear`, `Icons.clear_rounded`, `Icons.close_rounded` | `close` | `x` | — |
| `Icons.broken_image`, `Icons.broken_image_outlined` | `imageError` | `imageOff` | — |
| `Icons.image_outlined` | `image` | `image` | — |
| `Icons.download_rounded` | `download` | `download` | — |
| `Icons.downloading_rounded` | `downloading` | `download` | 进度由环形进度层表达 |
| `Icons.download_done_rounded` | `downloaded` | `fileCheck` | — |
| `Icons.play_arrow_rounded` | `play` | `play` | — |
| `Icons.playlist_play_rounded` | `playlist` | `listVideo` | — |
| `Icons.video_settings_rounded` | `videoSettings` | `settings2` | — |
| `Icons.subtitles_rounded` | `captions` | `captions` | — |
| `Icons.volume_off_rounded` | `muted` | `volumeX` | — |
| `Icons.volume_up_rounded` | `volume` | `volume2` | — |
| `Icons.fullscreen_rounded` | `fullscreen` | `maximize` | — |
| `Icons.fullscreen_exit_rounded` | `exitFullscreen` | `minimize` | — |
| `Icons.repeat_rounded` | `repeat` | `repeat2` | — |
| `Icons.explore_outlined`, `Icons.explore_rounded` | `explore` | `compass` | 选中态不换面性图标 |
| `Icons.home_filled` | `home` | `house` | — |
| `Icons.search_rounded`, `Icons.manage_search_rounded` | `search` | `search` | 选中态通过颜色和底板表达 |
| `Icons.settings`, `Icons.settings_outlined`, `Icons.settings_rounded` | `settings` | `settings` | — |
| `Icons.notifications_on_outlined` | `notifications` | `bell` | 未读状态使用角标 |
| `Icons.history_rounded`, `Icons.history_toggle_off_rounded` | `history` | `history` | 暂停记录用状态角标或文案 |
| `Icons.logout_rounded`, `Icons.exit_to_app_rounded` | `logout` | `logOut` | — |
| `Icons.menu` | `menu` | `menu` | — |
| `Icons.more_horiz_rounded` | `moreHorizontal` | `ellipsis` | — |
| `Icons.more_vert_rounded` | `moreVertical` | `ellipsisVertical` | — |
| `Icons.message` | `message` | `messageCircle` | — |
| `Icons.mode_comment_outlined`, `Icons.mode_comment_rounded` | `comment` | `messageCircle` | 评论状态不换面性图标 |
| `Icons.comment_bank_outlined` | `comments` | `messagesSquare` | — |
| `Icons.inbox_outlined` | `inbox` | `inbox` | — |
| `Icons.refresh_rounded` | `refresh` | `refreshCw` | 动画旋转由统一组件控制 |
| `Icons.filter_alt_rounded` | `filter` | `listFilter` | 激活时显示主题色圆点 |
| `Icons.tag_rounded` | `tag` | `tag` | — |
| `Icons.language_outlined` | `language` | `languages` | — |
| `Icons.group_outlined` | `group` | `users` | — |
| `Icons.local_fire_department_rounded` | `hot` | `flame` | 热度级别不更换图形 |
| `Icons.grain_rounded` | `grainList` | `wheat` | LOFTER 粮单语义 |
| `Icons.workspace_premium_rounded` | `premium` | `crown` | — |
| `Icons.shopping_bag_outlined` | `shop` | `shoppingBag` | — |
| `Icons.shopping_cart` | `cart` | `shoppingCart` | — |
| `Icons.rate_review_outlined` | `review` | `messageSquareText` | — |
| `Icons.telegram_outlined` | `send` | `send` | 不表示 Telegram 品牌 |
| `Icons.push_pin_outlined`, `Icons.push_pin_rounded` | `pin` | `pin` | 固定状态不换面性图标 |
| `Icons.change_history` | `changeHistory` | `triangle` | 仅保留几何语义 |
| `Icons.view_agenda_outlined` | `listLayout` | `layoutList` | — |
| `Icons.view_module_outlined` | `gridLayout` | `layoutGrid` | — |
| `Icons.view_carousel_outlined` | `carouselLayout` | `galleryHorizontal` | — |
| `Icons.visibility_outlined` | `visible` | `eye` | — |
| `Icons.visibility_off_outlined` | `hidden` | `eyeOff` | — |
| `Icons.egg_rounded` | `easterEgg` | `egg` | — |
| `CupertinoIcons.archivebox` | `archive` | `archive` | — |
| `CupertinoIcons.checkmark_alt` | `check` | `check` | — |
| `CupertinoIcons.square_on_square` | `copy` | `copy` | — |

## 4. PNG 静态界面图标映射

| 旧资源组 | 当前使用 | 语义键 | Lucide 目标 | 处理 |
| --- | --- | --- | --- | --- |
| `collection_dark/light/primary/white.png` | 是 | `collection` | `libraryBig` | 颜色由主题提供，删除四套染色位图 |
| `confirm.png` | 否 | `confirm` | `check` | 迁移后删除 |
| `download_white.png` | 否 | `download` | `download` | 颜色由前景色提供 |
| `dress_dark/light.png` | 是 | `dress` | `shirt` | 删除深浅两套位图 |
| `dynamic_dark/light(_selected).png` | 否 | `activityFeed` | `rss` | 选中态不换图 |
| `favorite_dark/light.png` | 否 | `favorite` | `heart` | — |
| `grain_white.png` | 是 | `grainList` | `wheat` | — |
| `home_dark/light(_selected).png` | 否 | `home` | `compass` | 与现有“探索首页”语义一致 |
| `hot.png`, `hotless.png`, `hottest.png`, `hot_white.png` | 是 | `hot` | `flame` | 强度通过颜色、标签和数值表达 |
| `info.png` | 否 | `info` | `info` | — |
| `like_dark/light/filled.png` | 仅注释 | `favorite` | `heart` | 保留 Lottie 点赞动画，删除静态位图 |
| `link_dark/grey/light/primary/white.png` | 否 | `link` | `link` | — |
| `mine_dark/light(_selected).png` | 否 | `person` | `userRound` | — |
| `order_down/up_dark/light.png` | 是 | `sortDirection` | `arrowDownUp` | 方向由旋转或状态参数表达 |
| `pin_dark/light.png` | 否 | `pin` | `pin` | — |
| `search_dark/grey/light.png` | 是 | `search` | `search` | — |
| `setting_dark/light.png` | 是 | `settings` | `settings` | — |
| `tag_dark/grey/light/white.png` | 是 | `tag` | `tag` | — |

`assets/icon/code.txt` 和 `assets/icon/run.py` 是旧资源生成辅助文件，不属于运行时资源，已随 `ICON-05` 一并清理。`assets/illust` 和 `assets/mess` 不在本表中，它们是插画与内容装饰，最终视觉重构前不得因图标迁移误删。

## 5. 当前已合规的 Lucide 使用

当前代码已使用 45 个不同的 Lucide 符号，主要覆盖下载管理、设置入口以及 `awesome_chewie` 的输入框、菜单、空状态和通用操作。迁移时优先复用现有语义：

`arrowLeft`, `check`, `checkCheck`, `chevronDown`, `chevronLeft`, `chevronRight`, `chevronUp`, `circleCheck`, `circleX`, `cloudAlert`, `copy`, `copyCheck`, `download`, `ellipsisVertical`, `externalLink`, `eye`, `eyeOff`, `file`, `flaskConical`, `globe`, `hash`, `house`, `image`, `imageOff`, `inbox`, `info`, `link`, `paintbrushVertical`, `pause`, `play`, `plus`, `refreshCw`, `rotateCcw`, `save`, `search`, `searchSlash`, `settings`, `settings2`, `share2`, `square`, `textCursorInput`, `trash2`, `triangleAlert`, `video`, `x`。

这些直接引用将在 `ICON-02` 一并收口到统一组件，避免“虽然都是 Lucide，但尺寸、颜色和点击区域仍由页面各自决定”。

## 6. 统一组件规范

`ICON-02` 已建立分层入口：业务代码只通过 `LoftifyIcons` 使用产品语义，复用组件通过 `ChewieIcons` 使用基础语义，并由 `ChewieIcon` 和 `ChewieIconButton` 统一渲染。业务页面不得再直接导入 `lucide_icons`；后续迁移时先在对应语义层登记，再替换页面中的旧图标。

| 项目 | 统一规则 |
| --- | --- |
| 视觉尺寸 | 小型辅助图标 16；常规操作 20；大图标 24。特殊内容允许显式覆盖，但不得同时改变点击区域。 |
| 点击区域 | 所有可点击图标最小 44×44 逻辑像素；紧凑列表只缩小字形和间距，不缩小热区。 |
| 颜色 | 默认继承当前 `IconTheme` 或 `onSurfaceVariant`；选中态使用主题色，禁用态统一为当前前景色 38% 不透明度。 |
| 状态 | 选中态保持同一字形，以主题色和 12% 主题色底板表达；悬停、聚焦、按下叠层分别为 8%、10%、12%。 |
| 形状 | 普通按钮透明；柔和按钮使用低对比表面色；描边按钮使用 0.8 细边框；默认圆角 10。 |
| 对齐 | 图标以自身光学尺寸居中；确有字形偏差时只通过 `opticalOffset` 微调，不改变布局盒和热区。 |
| 无障碍 | 可点击图标必须提供 tooltip 或语义标签；禁用、选中和长按状态由统一按钮暴露。 |

上述尺寸、透明度和状态参数集中在 `ChewieIconThemeData`，并注册到明暗主题中；不得在页面重新复制一套状态颜色。自动化测试会阻止业务页面绕过 `LoftifyIcons` 直接导入 Lucide 字体。

## 7. 面性图标与状态表达

持久状态和动作状态必须分开处理：

- 点赞、推荐、收藏、关注、筛选、导航选中等“同一对象的持久状态”，始终保留同一个 Lucide 字形。默认态使用次级前景色；选中态依次使用主题色、12% 主题色底板或小圆点增强辨识，不能切换为另一套填充图标。
- 播放/暂停、静音/有声、展开/收起、全屏/退出全屏等“当前可执行动作已经变化”的场景，可以切换 Lucide 字形。这是动作语义变化，不是面性选中态。
- 成功、警告、错误、加载等反馈使用对应语义图标、颜色和动画；不得用实心版本冒充更强状态。Lottie 继续承担原有加载与反馈动画，静态无障碍替代才使用 Lucide。
- 图标状态的优先级为禁用 > 错误/警告 > 选中 > 默认；悬停、聚焦和按下只添加临时叠层，不改变持久状态的图形和含义。
- 业务语义名称不得包含 `filled`、`outlined`、`active`、`inactive`、`selected` 或 `unselected`。同一语义只登记一次，状态交给统一组件处理。

### 7.1 受控配对 SVG 例外

只有 Lucide 轮廓在 16/20/24 三档尺寸下都无法清晰表达含义，且主题色、底板、圆点、标签仍不足以解决时，才允许制作配对 SVG。例外必须同时满足：24×24 网格、统一 2px 视觉描边、相同基线和包围盒、支持主题色着色、具备语义标签，并在本节登记文件、使用页面、原因和移除条件。

当前受控配对 SVG 例外：**无**。

`assets/logo.svg` 是产品品牌标识，不属于界面图标，也不进入配对 SVG 例外表。自动化测试会拒绝未登记的新增 SVG 界面资源；如确需新增，必须在设计复核后同步更新本节和测试白名单。

## 8. 迁移批次与验收口径

1. 基础组件：先完成 `awesome_chewie`、统一语义组件、输入、菜单、Entry/Setting Item、空状态和 AppBar。
2. 全局导航：迁移 `main_screen.dart`、`panel_screen.dart`、Mine 与设置导航，为 `NAVGLASS-*` 提供稳定图标基础。
3. 内容浏览：迁移帖子卡片、帖子详情、标签、合集、粮单、搜索和用户页。
4. 媒体与状态：迁移视频控件、下载状态、图片失败状态；Lottie 动画继续保留。
5. 清理：仓库扫描不得再出现未登记的 `Icons.*`、`CupertinoIcons.*` 或运行时 `assets/icon/*.png` 引用。

每一批都必须验证：浅色/深色、选中/未选中、禁用/错误/加载状态，中文/英文长文案，手机/平板/桌面尺寸，以及至少 44×44 逻辑像素的触控区域。图标视觉尺寸不能直接等同于点击区域。

## 9. 自动盘点命令

后续验收使用以下规则复查，不依赖人工目测：

```text
rg -o "\bIcons\.[A-Za-z0-9_]+" lib third-party/chewie/lib -g "*.dart"
rg -o "\bCupertinoIcons\.[A-Za-z0-9_]+" lib third-party/chewie/lib -g "*.dart"
rg -o "\bLucideIcons\.[A-Za-z0-9_]+" lib third-party/chewie/lib -g "*.dart"
rg "AssetUtil\.[A-Za-z0-9_]+|assets/icon/" lib -g "*.dart"
```

允许结果只能是本文件明确登记的例外；新增页面不得扩大遗留图标数量。
