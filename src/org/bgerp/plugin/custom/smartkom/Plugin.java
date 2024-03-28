package org.bgerp.plugin.custom.smartkom;

import java.sql.Connection;
import java.util.List;
import java.util.Map;

import ru.bgcrm.event.EventProcessor;
import ru.bgcrm.event.ParamChangedEvent;
import ru.bgcrm.plugin.Endpoint;

/**
 * BGERP Custom Smartkom Plugin.
 * Copied from Demo plugin
 * @author Shamil Vakhitov
 */
public class Plugin extends ru.bgcrm.plugin.Plugin {
    public static final String ID = "custom.smartkom";

    public static final String PATH_JSP_OPEN = PATH_JSP_OPEN_PLUGIN + "/" + ID;
    public static final String PATH_JSP_USER = PATH_JSP_USER_PLUGIN + "/" + ID;

    public Plugin() {
        super(ID);
    }

//    @Override
//    protected Map<String, List<String>> loadEndpoints() {
//        return Map.of(Endpoint.JS, List.of(Endpoint.getPathPluginJS(ID)));
//    }

    @Override
    public void init(Connection con) throws Exception {
        super.init(con);

        EventProcessor.subscribe((e, conSet) -> {
            //log
        }, ParamChangedEvent.class);
    }
}
