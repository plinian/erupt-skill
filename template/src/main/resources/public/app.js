// erupt 前端运行时配置：修改本文件即可定制后台外观与行为，无需改 Java、无需重新构建，重启后刷新页面生效
// 完整选项说明：https://github.com/erupts/erupt-web#runtime-configuration
window.eruptSiteConfig = {
    // 浏览器标题 & 登录页标题
    title: "__APP_TITLE__",
    // 登录页副标题 / 系统一句话描述
    desc: "__APP_DESC__",
    // 左上角 Logo 文字（logoPath 为空时显示）
    logoText: "__APP_TITLE__",
    // Logo 图片：放到 src/main/resources/public/assets/ 下，填 "assets/logo.png"
    logoPath: null,
    // 侧栏折叠时的小 Logo、登录页 Logo（为空时分别回退到 logoPath / logoText）
    logoFoldPath: null,
    loginLogoPath: null,
    // 页脚版权：copyright 控制显隐，copyrightTxt 自定义文案（支持 HTML）
    copyright: true,
    // copyrightTxt: "© 2026 __APP_TITLE__",
    // 主题：primaryColor 主色调，headerColor 顶栏背景色
    theme: {
        primaryColor: "#3f51b5"
        // headerColor: "#ffffff"
    },
    // 默认夜间模式 / 深色侧栏（用户可在右上角设置抽屉中自行覆盖）
    // darkTheme: false,
    // asideDark: false,
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
    //     icon: "fa fa-question-circle",
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
