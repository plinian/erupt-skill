package modtpl;

import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import xyz.erupt.core.annotation.EruptScan;
import xyz.erupt.core.module.EruptModule;
import xyz.erupt.core.module.EruptModuleInvoke;
import xyz.erupt.core.module.MetaMenu;
import xyz.erupt.core.module.ModuleInfo;

import java.util.ArrayList;
import java.util.List;

/**
 * 模块入口：与应用模板的 Application.java 同一机制（EruptModule + initMenus），
 * 仅去掉 main/@SpringBootApplication，改由 META-INF/spring/...AutoConfiguration.imports 被宿主自动装配。
 */
@Configuration
@ComponentScan
@EruptScan
@EntityScan
public class ModuleAutoConfiguration implements EruptModule {

    static {
        EruptModuleInvoke.addEruptModule(ModuleAutoConfiguration.class);
    }

    @Override
    public ModuleInfo info() {
        return ModuleInfo.builder().name("__ARTIFACT_ID__").build();
    }

    @Override
    public List<MetaMenu> initMenus() {
        List<MetaMenu> menus = new ArrayList<>();
        // 在此注册实体菜单（每个 @Erupt 实体一行，宿主应用启动后自动出现在后台菜单）：
        // menus.add(MetaMenu.createRootMenu("$mod", "模块名", "fa fa-cube", 30));
        // menus.add(MetaMenu.createEruptClassMenu(Xxx.class, menus.get(0), 10));
        // 树形实体（@Erupt 带 tree 配置）需指定 TREE 类型（MenuTypeEnum 位于 xyz.erupt.core.constant）：
        // menus.add(MetaMenu.createEruptClassMenu(Category.class, menus.get(0), 20, MenuTypeEnum.TREE));
        // 隐藏菜单（如仅供 Drill 下钻的页面，注册以获得权限但不显示，MenuStatus 位于 xyz.erupt.core.constant）：
        // menus.add(MetaMenu.createEruptClassMenu(XxxLog.class, menus.get(0), 25, MenuStatus.HIDE));
        // 自定义整页 TPL 页面（HTML 放 resources/tpl/ 下，value = 文件名，type 固定 "tpl"）：
        // menus.add(MetaMenu.createSimpleMenu("dashboard", "数据大屏", "dashboard.html", menus.get(0), 5, "tpl"));
        return menus;
    }

}
