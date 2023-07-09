package org.bgerp.plugin.custom.demo;

import org.bgerp.util.Log;

/**
 * May be started in Administration / Run tool.
 * Or via HTTP call:
 * http://[host]:[port]/admin/run.do?action=runClass&iface=event&class=org.bgerp.plugin.custom.demo.DemoRunnable&j_username=[user]&j_password=[pswd]
 */
public class DemoRunnable implements Runnable {
    private static final Log log = Log.getLog();

    @Override
    public void run() {
        log.info("Started.");
    }
}
