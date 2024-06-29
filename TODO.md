## 页面设计

### 文章列表

- 顶部栏
  - 抽屉按钮
  - 选择订阅源
  - TTS按钮
  - 搜索按钮（大小写敏感，仅搜索标题，搜索标题和正文）
  - 已读按钮（全部已读、超过1天前已读、超过3天前已读、超过7天前已读）
  - 视图按钮
    - 列表样式
      - 卡片视图：图片占主要部分
      - 瀑布流视图：双栏卡片
      - 杂志视图：包含标题、缩略正文、左/右侧小图片
      - 紧凑试图：仅包含标题和一行缩略正文
      - 画廊视图：包含所有图片
      - 播客视图：包含标题、预计播放时间、播放按钮
    - 排版样式（自定义文字大小、横纵Margin）
  - 筛选按钮
    - 筛选状态（全部文章、已读文章、星标文章、已缓存文章、未星标文章、未读文章）
    - 排序方式（最新、最旧）
    - 选择时间范围（1天内、3天内、7天内、自定义时间）


- 列表Meta


  - 应用图标、应用名称、标题、缩略正文、发布时间、首张图片、星标


  - 长按更多
    - 将以上文章标为已读、将以下文章标为已读
    - 标为已读、标为星标
    - 分享文章
    - 播放（单个播放、播放文章列表、下一个播放、添加到播放列表）



### 订阅源列表

- 顶部栏
  - 抽屉按钮
  - 选择订阅源
  - TTS按钮
  - 搜索按钮（大小写敏感）
  - 添加订阅源按钮
- 应用图标、应用名称、未读文章轮播、未读数、最新文章发布时间
- 订阅源（长按显示选项：详情、重命名、取消订阅、分享、过滤器、通知器、设为首页）
- 订阅源分组设置
- 订阅源设置
  -  Meta：名称、图标、URL、备注
  -  默认抓取模式、文章列表布局、解析器
  -  过滤器、通知器、缓存策略
  -  分组管理

### 文章详情

-  顶部栏
   -  返回
   -  抓取模式：RSS/抓取全文/内置浏览器/外置浏览器
   -  星标
   -  阅读建议时长/字数
   -  排版布局
      -  深色/浅色
      -  无图模式
      -  字体、字号
      -  字距、行距、段距、边距
      -  对齐方向、段首缩进
      -  文字颜色、背景颜色
   -  分享
      -  复制链接
      -  分享链接到…
      -  分享全文到…
      -  URL Schemes（以及自定义）
   -  更多设置
      -  第一行：解析器（Feedbin Parser、FeedMe、Google Web Light）、在浏览器打开、朗读、一键翻译、搜索、设置标签
      -  导出：导出为Markdown、离线Markdown、Epub、MOBI、PDF、图片、第三方应用
-  操作
   -  长按标题：复制标题
   -  长按链接：复制链接、在浏览器打开
   -  长按文字：复制、全选、搜索、<u>收藏文本</u>
   -  长按图片：查看图片、保存图片、复制图片链接、<u>收藏图片</u>、提取文字
   -  双击页面：关闭、星标/取消星标、标为未读/已读、切换抓取模式
   -  非上下滑动式布局下的触顶滑动/触底滑动：关闭页面，切换订阅源

-  视图选项
   -  单文章
   -  左右滑动卡片式布局
   -  上下滑动知乎式布局

-  相关文章

## 功能设计

### 源解析

-  从URL添加（设置URL、名称、图标、分组、排序、是否缓存）
-  导入OMPL文件
-  第三方服务
   -  Fever API
      -  TT-RSS Fever plugin
      -  FreshRSS
      -  Miniflux

   -  Google Reader API
      -  Bazqux Reader
      -  The Old Reader

   -  Inoreader
   -  Feedbin

### 设置

-  外观
   -  内置webviewactivity
   -  语言设置
   -  主题颜色、主题模式
   -  文章详情
      -  视图选项
      -  头图选项（不显示、单张图片、全文图片轮播）
      -  详情页布局设置：Meta设置（头图、发布时间、字数统计、推荐阅读时长）
      -  是否重绘超链接
      -  是否显示相关文章
      -  视频显示方式（预览视频、截取图片、不显示）
   
-  服务管理
   -  印象笔记：直接保存
   -  Evernote：直接保存
   -  Instapaper：直接保存
   -  Pocket：直接保存
   -  Onenote：直接保存
   -  Google Drive：备份OPML并保存为Google Docs
   -  Dropbox：备份OPML并保存为PDF
   -  WebDAV：备份OPML并保存为PDF
   -  有道云笔记：直接保存
   -  为知笔记：直接保存
   -  Joplin：直接保存
   -  flomo：直接保存
   -  专注笔记：直接保存
-  备份
   -  本地备份/恢复（设置、OPML）
   -  WebDav备份/恢复（设置、OPML）
   -  自动备份文章：重复备份时自动覆盖
-  通知
   -  每个订阅源是否通知
   -  每个订阅源根据标题、正文、作者等正则匹配决定动作
-  TTS
   -  是否启用
   -  引擎设置
-  翻译
   -  服务设置
   -  自动翻译（翻译为什么语言）
-  AI摘要
   -  是否开启
   -  服务设置
-  操作
   -  文章列表快捷操作（左右滑动）
      - 标星/取消星标
      - 已读/未读
      - 分享
      - 在外部打开
      - 打开菜单
   -  双击
   -  音量键上下翻页/跳转文章

### 实验功能

- Twine
  - 根据每一页中 banner 图片来调整 UI 色调，配合背景模糊效果，使得应用整体看起来非常现代
  - 针对 banner 图片位置做了视差滚动，不仅视觉上更好看，操作起来也更加有层次感
- Big News
  - 点击进入任意一篇推送的文章，Big News 会对网页进行重新排版，并自动进入阅读模式
  - 在阅读模式中，我可以更改暗色模式、字体大小、频道主题色、加载全文等设置，也可以对文章进行分享、收藏等操作
  - 针对文章的发布账号，我可以直接跳转到其官网、频道，也可以对它进行重命名、置顶、开启推送通知等操作
  - 某个订阅频道中，首篇文章大卡片，其他列表
  - 收藏中，根据领域筛选
- News+
  - 自由选择离线内容的条目及是否加载图片、音频及视频
- 支持第三方密码管理 App 的 API 
- 支持侧滑返回
- 搜索时可以储存关键词
- 在文章列表中，按住文章标题并拖动，屏幕下方会出现类似 Bear 的「动作栏」。此时你还可以用其他手指继续点击其它文章标题，它们会自动聚合成组，方便你批量操作。将它们放入「工作栏」后，你可以选择对它们进行收藏、分享、发送到其他 App 等操作
- Hot Links：被订阅源多次引用的链接
- Calm Feeds：更新频率较低的订阅源的文章
- Linked List：内含多个链接的文章

## 内容设计

- 内容库
  - 星标
  - 集锦
  - 已保存
  - 阅读历史
- 探索
  - Hot Links
  - Calm Feeds
  - Linked List
  - 统计

## 数据库设计

### 订阅源服务

|       字段       |  数据库类型  | 代码类型 | 是否必需 |                 备注                 |
| :--------------: | :----------: | :------: | :------: | :----------------------------------: |
|        id        |   INTEGER    |   int    |    是    |               自增主键               |
|     endpoint     | VARCHAR(255) |  String  |    是    |               服务网址               |
|       type       |   INTEGER    |   int    |    是    |   服务类型（第三方各个、自建各个）   |
|     username     | VARCHAR(255) |  String  |    否    |                用户名                |
|     password     | VARCHAR(255) |  String  |    否    |                 密码                 |
|      api_id      | VARCHAR(255) |  String  |    否    |                API ID                |
|     api_key      | VARCHAR(255) |  String  |    否    |               API KEY                |
|   fetch_limit    |   INTEGER    |   int    |    是    |               抓取上限               |
| last_sync_status |   INTEGER    |   int    |    否    | 上次同步状态（尚未同步、成功、失败） |
|  last_sync_time  |     LONG     |   long   |    否    |             上次同步时间             |
|      params      |     TEXT     |  String  |    否    |               其他参数               |

### 云同步服务

|       字段       |  数据库类型  | 代码类型 | 是否必需 |           备注           |
| :--------------: | :----------: | :------: | :------: | :----------------------: |
|        id        |   INTEGER    |   int    |    是    |         自增主键         |
|     endpoint     | VARCHAR(255) |  String  |    是    |         服务网址         |
|       type       |     int      |   int    |    是    | 服务类型（各云同步服务） |
|     username     | VARCHAR(255) |  String  |    否    |          用户名          |
|     password     | VARCHAR(255) |  String  |    否    |           密码           |
|      api_id      | VARCHAR(255) |  String  |    否    |          API ID          |
|     api_key      | VARCHAR(255) |  String  |    否    |         API KEY          |
| last_push_status |   INTEGER    |   int    |    否    |       上次备份状态       |
|  last_push_time  |     LONG     |   long   |    否    |       上次备份时间       |
| last_pull_status |   INTEGER    |   int    |    否    |       上次拉取状态       |
|  last_pull_time  |     LONG     |   long   |    否    |       上次拉取时间       |
|      params      |     TEXT     |  String  |    否    |         其他参数         |

### 笔记服务

|   字段   |  数据库类型  | 代码类型 | 是否必需 |   备注   |
| :------: | :----------: | :------: | :------: | :------: |
|    id    |   INTEGER    |   int    |    是    | 自增主键 |
|   name   | VARCHAR(255) |  String  |    是    | 服务名称 |
| endpoint | VARCHAR(255) |  String  |    是    | 服务网址 |
| username | VARCHAR(255) |  String  |    否    |  用户名  |
| password | VARCHAR(255) |  String  |    否    |   密码   |
|  api_id  | VARCHAR(255) |  String  |    否    |  API ID  |
| api_key  | VARCHAR(255) |  String  |    否    | API KEY  |

### 订阅源

|           字段            | 数据库类型 | 代码类型 | 是否必需 |                  备注                  |
| :-----------------------: | :--------: | :------: | :------: | :------------------------------------: |
|            id             |  INTEGER   |   int    |    是    |                自增主键                |
|        service_id         |  INTEGER   |   int    |    是    |            所属订阅源服务ID            |
|            sid            |    TEXT    |   int    |    是    |                订阅源ID                |
|            url            |    TEXT    |  String  |    否    |               订阅源地址               |
|         icon_url          |    TEXT    |  String  |    否    |             订阅源图标地址             |
|           name            |    TEXT    |  String  |    否    |               订阅源名称               |
|         open_type         |  INTEGER   |  String  |    否    |  文章抓取方式(RSS、全文、内置、外部)   |
|         view_type         |  INTEGER   |   int    |    是    |              文章列表视图              |
|         mobilizer         |  INTEGER   |   int    |    是    |               文章解析器               |
|      auto_pull_time       |  INTEGER   |   int    |    是    |          拉取频率（0不更新）           |
| remove_duplicate_articles |  INTEGER   |   int    |    是    |              移除重复文章              |
|     scroll_auto_read      |  INTEGER   |   int    |    是    | 滚动时自动已读（跟随全局设置、是、否） |
|        latest_time        |    LONG    |   long   |    否    |              最新文章时间              |
|     last_pull_status      |  INTEGER   |   int    |    否    |            上次拉取文章状态            |
|      last_pull_time       |    LONG    |   long   |    否    |              上次拉取时间              |
|          params           |    TEXT    |  String  |    否    |   其他参数（可以根据全局设置的参数）   |

### 文章项

|   字段   | 数据库类型 | 代码类型 | 是否必需 |                备注                |
| :------: | :--------: | :------: | :------: | :--------------------------------: |
|    id    |    Text    |  String  |    是    |             字符串主键             |
|  feedId  |  INTEGER   |   int    |    是    |            所属订阅源ID            |
|  title   |    TEXT    |  String  |    是    |                标题                |
|   url    |    TEXT    |  String  |    是    |              文章地址              |
|   date   |  INTEGER   |   int    |    是    |            文章发布时间            |
| content  |    TEXT    |  String  |    是    |            RSS文章内容             |
| snippet  |    TEXT    |  String  |    是    |              缩略片段              |
| creator  |    TEXT    |  String  |    否    |                作者                |
|  thumb   |    TEXT    |  String  |    否    |            移除重复文章            |
| hasRead  |  INTEGER   |   int    |    否    |              是否已读              |
| starred  |  INTEGER   |   int    |    否    |              是否标星              |
| readTime |  INTEGER   |   int    |    否    |              阅读时间              |
| starTime |  INTEGER   |   int    |    否    |              星标时间              |
|  params  |    TEXT    |  String  |    否    | 其他参数（可以根据全局设置的参数） |

### 文章

## Github API

### 获取最新版本

https://api.github.com/repos/Robert-Stackflow/CloudOTP/releases/latest

### 获取更新日志

