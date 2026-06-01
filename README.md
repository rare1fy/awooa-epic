# AwooaEpic - 鱼人逆袭：潮涌军团

> Survivors-like 割草 + Brawl Stars 式角色收集养成  
> Godot 4.5 · 抖音小游戏

## 项目结构

```
AwooaEpic/
├── project.godot              # 项目配置
├── common/
│   ├── autoload/              # 全局管理器
│   │   ├── game_manager.gd    # 游戏状态管理
│   │   ├── save_manager.gd    # 存档管理（本地/抖音）
│   │   └── audio_manager.gd   # 音频管理
│   └── utils/                 # 工具类
│       ├── object_pool.gd     # 对象池
│       ├── spatial_hash.gd    # 空间哈希（碰撞检测）
│       └── weighted_random.gd # 加权随机
├── data/                      # 数据定义（Resource）
│   ├── characters/            # 主角鱼人数据
│   ├── allies/                # 队友鱼人数据
│   ├── enemies/               # 敌人数据
│   ├── stages/                # 关卡配置
│   └── chapters/              # 章节配置
├── scenes/
│   ├── main_menu/             # 主菜单
│   ├── chapter_map/           # 章节选关
│   ├── battle/                # 战斗场景
│   │   ├── player/            # 玩家角色
│   │   ├── allies/            # 队友
│   │   ├── enemies/           # 敌人
│   │   └── pickups/           # 拾取物
│   └── ui/                    # UI 组件
│       └── virtual_joystick   # 虚拟摇杆
└── docs/
    └── GDD_Core_Loop.md       # 核心循环设计文档
```

## 快速开始

1. 用 Godot 4.5 Standard 版打开此项目
2. 确认渲染器为 `GL Compatibility`
3. 运行 `main_menu.tscn` 即可

## 开发里程碑

- [ ] M1: 移动 + 敌人 + 碰撞
- [ ] M2: 队友系统 + 跟随 + 自动攻击
- [ ] M3: 升级 + 3选1招募 + 升星
- [ ] M4: 时间轴刷怪 + 尸潮
- [ ] M5: Boss 系统
- [ ] M6: 大招 + 结算 + 三星
- [ ] M7: 章节地图 + 关卡配置
- [ ] M8: 打磨 + 平衡

## 技术约束

- 渲染器：GL Compatibility（WebGL 2.0）
- 禁用：多线程、C#、GDExtension、GPU粒子
- 目标：200+ 敌人同屏 30FPS+
- 包体：首包 ≤ 20MB
