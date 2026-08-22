package app;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.stereotype.Component;
import xyz.erupt.core.annotation.EruptScan;
import xyz.erupt.core.module.EruptModule;
import xyz.erupt.core.module.EruptModuleInvoke;
import xyz.erupt.core.module.MetaMenu;
import xyz.erupt.core.module.ModuleInfo;

import java.util.ArrayList;
import java.util.List;

@SpringBootApplication
@EruptScan
@EntityScan
@Component
public class Application implements EruptModule {

    static {
        EruptModuleInvoke.addEruptModule(Application.class);
    }

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

    @Override
    public ModuleInfo info() {
        return ModuleInfo.builder().name("__ARTIFACT_ID__").build();
    }

    @Override
    public List<MetaMenu> initMenus() {
        List<MetaMenu> menus = new ArrayList<>();
        // 在此注册实体菜单（每个 @Erupt 实体一行，重启后自动出现在后台菜单）：
        // menus.add(MetaMenu.createRootMenu("$app", "业务管理", "fa fa-th-large", 10));
        // menus.add(MetaMenu.createEruptClassMenu(Book.class, menus.get(0), 10));
        // 树形实体（@Erupt 带 tree 配置）需指定 TREE 类型：
        // menus.add(MetaMenu.createEruptClassMenu(Category.class, menus.get(0), 20, MenuTypeEnum.TREE));
        return menus;
    }

}
