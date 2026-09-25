// erupt 前端运行时配置：修改本文件即可定制后台外观与行为，无需改 Java、无需重新构建，重启后刷新页面生效
// 完整选项说明：https://docs.erupt.xyz/zh/guide/config-frontend
window.eruptSiteConfig = {
    // 浏览器标题 & 登录页标题
    title: "__APP_TITLE__",
    // 登录页副标题 / 系统一句话描述
    desc: "__APP_DESC__",
    // 左上角 Logo 旁的文字
    logoText: "__APP_TITLE__",
    // Logo 三个键的规则：不写 = 用内置 erupt 标识；写 null 或 '' = 该位置不显示 Logo
    // 自定义 Logo：图片放到 src/main/resources/public/assets/ 下，取消注释并填路径
    // logoPath: "assets/logo.png",        // 顶栏 Logo
    // logoFoldPath: "assets/logo-s.png",  // 侧栏折叠后的小 Logo（默认跟随 logoPath；无 Logo 时显示站点名首字母）
    // loginLogoPath: "assets/logo.png",   // 登录页 Logo（默认跟随 logoPath）
    // 浏览器标签图标，支持 ico / png / svg
    // faviconPath: "assets/favicon.svg",
    // 页脚版权：copyright 控制显隐，copyrightTxt 自定义文案（支持 HTML）
    copyright: true,
    // copyrightTxt: "© 2026 __APP_TITLE__",
    // 主题：以下都是「默认值」，用户在右上角设置抽屉里选过之后以用户选择为准
    theme: {
        // 是否允许用户自行修改品牌外观（主题色、顶栏色、皮肤、导航配色、菜单模式）；false 时全员统一用这里的配置
        customizable: true,
        // 主色调
        primaryColor: "#3f51b5",
        // 顶栏背景色："primary" 跟随主题色，或任意 CSS 颜色
        // headerColor: "#ffffff",
        // 暗色模式：true / false / "auto"（跟随操作系统）
        // dark: "auto",
        // 紧凑模式（行高与间距更小，一屏放更多数据）
        // compact: false,
        // 皮肤风格："default" / "workspace"（Slack、飞书式一体化导航，配 workspaceFrame 选配色）
        //   / "classic"（Ant Design Pro 深色侧栏）/ "brutalist"（硬边高对比）/ "liquid-glass"（玻璃拟态）
        // skin: "default",
        // 仅 workspace 皮肤：导航框架配色预设，如 "sky" / "mint" / "peach"（浅色）、"deep-sea" / "indigo" / "graphite"（深色），不设则由主题色推导
        // workspaceFrame: "sky",
        // 菜单模式："normal" 侧栏 / "group" 一级分类作分组标题 / "dual" 双栏侧栏 / "split" 一级分类放顶栏
        //   / "top" 全部菜单放顶栏 / "top-split" 一级分类在顶栏、子菜单在第二行
        // menuMode: "normal",
        // 记录表单的打开形态："center" 居中弹窗 / "side" 侧边面板 / "full" 全屏
        // formPanelMode: "center",
        // 登录页布局："center" 居中卡片 / "cover" 侧边面板 / "wide" 宽卡分栏 / "wallpaper" 壁纸玻璃 / "poster" 品牌满屏
        // loginLayout: "center",
        // 登录页背景图（一张图替换所有布局中的默认插画，图片放 assets/ 下或填完整 URL）
        // loginBackground: "assets/login-bg.jpg",
    },
    // 安装为桌面应用（PWA）：应用名 / 描述 / 颜色自动取自 logoText、title、desc 与顶栏，这里只补图标与右键快捷入口
    // pwa: {
    //     icon: "assets/pwa-icon.svg",              // svg，或 512px 以上的 png / jpg / webp
    //     shortcuts: [{ name: "首页", url: "./#/" }],
    // },
    // 多页签模式（默认关闭，用户可在设置抽屉中开启）
    tabReuse: false,
    // 顶栏右侧自定义内容，render 返回 HTML 字符串
    // r_tools: [{
    //     mobileHidden: true,
    //     render: () => '<a href="https://example.com/help" target="_blank">帮助中心</a>'
    // }],
    // 用户头像下拉菜单自定义项
    // userTools: [{
    //     text: "帮助中心",
    //     icon: "fa fa-circle-question",
    //     click: function () { window.open("https://example.com/help"); }
    // }],
};

// 生命周期钩子（可选）：startup 应用加载完成、login 登录成功、logout 退出登录
// window.notify / window.msg / window.modal 为前端暴露的 ng-zorro 服务，可在钩子中直接调用
window.eruptEvent = {
    startup: function () {
    },
    login: function () {
        // 例：登录成功后弹出欢迎提示
        // window.notify.success("欢迎回来", "登录成功", { nzPlacement: "bottomRight" });
    },
    logout: function () {
    }
};

// 路由钩子（可选）：key 为路由名（如 login、tenant，$ 表示所有路由），load / unload 在页面进入 / 离开时触发
window.eruptRouterEvent = {
    // login: {
    //     load: function (e) {
    //     },
    //     unload: function (e) {
    //     }
    // }
};
