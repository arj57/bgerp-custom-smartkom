package org.bgerp.plugin.custom.smartkom.procstatus;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.bgerp.app.cfg.ConfigMap;
import org.bgerp.app.cfg.Setup;
import org.bgerp.app.exception.BGException;
import org.bgerp.util.Log;
import org.bgerp.app.exec.scheduler.Task;
import org.bgerp.plugin.kernel.Plugin;

import ru.bgcrm.struts.action.ProcessAction;
import ru.bgcrm.struts.form.DynActionForm;
import ru.bgcrm.util.sql.SQLUtils;
import ru.bgcrm.dao.process.ProcessDAO;
import ru.bgcrm.dao.process.ProcessTypeDAO;
import ru.bgcrm.model.process.Process;
import ru.bgcrm.model.process.ProcessType;
import ru.bgcrm.model.process.StatusChange;
import ru.bgcrm.model.user.User;



/**
 *   Скрипт закрывает процессы, находящиется в статусе "Выполнен" дольше заданного
 *   количества дней. Параметры: 
 * custom.smartkom.ProcStatusChanger.allowedProcessTypes - Типы процессов через запятую. 
 *   Если не указаны, обрабатываются все типы.
 * custom.smartkom.ProcStatusChanger.lastStatusDaysAgo - Срок (в днях) со времени последнего изменения статуса процесса 
 *   перед его закрытием по умолчанию.
 *   Возможно изменение этого параметра для конкретных типов процессов 
 *   с помошью параметра: 
 * custom.smartkom.completedStatusDaysAgo=X
 *   Этот параметр нужно добавить в конфиг соответствующего типа процесса
 *
 * custom.smartkom.ProcStatusChanger.dryRun=false/true - Тестовый режим. Пишет в лог, но не закрывает процессы
 * 
 * @author alex
 */
public class ProcStatusChanger extends Task {

    private static final Log log = Log.getLog();
    private static final int PROCESS_STATUS_READY = 5;
    private static final int PROCESS_STATUS_CLOSED = 6;

    private Connection connection = null;
    private Set<Integer> procTypesIdsWithChildren;
    private Boolean dryRun;

    private Map<Integer, Integer> liveTimes = new HashMap<>();

    public ProcStatusChanger(ConfigMap config) {
        super(null);
    }
    
    @Override
    public String getTitle() {
        return Plugin.INSTANCE.getLocalizer().l("Smartkom Closer of completed processes");
    }

    @Override
    public void run() {

        this.init();
        LocalDate today = LocalDate.now();

        String query = "SELECT process.* FROM process AS process"
                + " WHERE process.status_id = ?" 
                + filterByProcessTypes();

        try {
            PreparedStatement ps = this.connection.prepareStatement(query);
            int pc = 1;
            ps.setInt(pc++, PROCESS_STATUS_READY);

            ResultSet rs = ps.executeQuery();

            String logStr;
            while (rs.next()) {
                Process process = ProcessDAO.getProcessFromRs(rs);
                int procTypeId = process.getTypeId();

//                log.info("Completed process: id: " + process.getId() + "; type: " + procTypeId + "; Date: " + process.getStatusTime());	
                if (this.procTypesIdsWithChildren.contains(procTypeId) && process.getStatusTime().toInstant().atZone(ZoneId.systemDefault())
                        .toLocalDate().plusDays(this.liveTimes.get(procTypeId)).compareTo(today) <= 0) {

                    if (this.dryRun) {
                        logStr = String.format("ТЕСТ закрытия процесса %d(%d), выполнен более %d дней назад.", process.getId(), process.getTypeId(),
                                this.liveTimes.get(procTypeId));
                    } else {

                        logStr = String.format("Процесс %d(%d) закрыт автоматически, был выполнен более %d дней назад.", process.getId(), procTypeId,
                                this.liveTimes.get(procTypeId));
                        StatusChange change = getNewChangeStatus(PROCESS_STATUS_CLOSED, process.getId(), logStr);
                        try {
                            ProcessAction.processStatusUpdate(DynActionForm.SYSTEM_FORM, connection, process, change);
                        }
                        catch( Exception e ){
                            log.warn( "Не могу закрыть процесс " + process.getId() + ": есть связанные процессы." );
                            continue;
                        }
                    }
                    log.info(logStr);
                }

                connection.commit();
            }
        } catch (SQLException e) {
            log.error(e.getMessage(), e);
        } finally {
            SQLUtils.closeConnection(connection);
        }

    }

    private void init(){
        this.connection = Setup.getSetup().getDBConnectionFromPool();

        try {
	        int defaultTtl = Setup.getSetup().getInt("custom.smartkom.ProcStatusChanger.lastStatusDaysAgo", 365);
	        this.dryRun = Setup.getSetup().getBoolean("custom.smartkom.ProcStatusChanger.dryRun", false);
	        String allowedProcTypes = Setup.getSetup().get("custom.smartkom.ProcStatusChanger.allowedProcessTypes", "");
	        this.procTypesIdsWithChildren = getProcessTypesIdsWithChildren(allowedProcTypes);

	        List<ProcessType> procTypesList = new ProcessTypeDAO(this.connection).getFullProcessTypeList();
	        for (ProcessType pt : procTypesList) {
	            if (this.procTypesIdsWithChildren.contains(pt.getId())) {
	                int ttl = pt.getProperties().getConfigMap().getInt("custom.smartkom.completedStatusDaysAgo", -1);
	                ttl = (ttl >= 0) ? ttl : defaultTtl;
	                this.liveTimes.put(pt.getId(), ttl);
	                log.info("Тип процесса: " + pt.getId() + "; Крайний срок: " + this.liveTimes.get(pt.getId()) + " дней");
	            }
	        }

            log.info(" Тестовый режим: " + this.dryRun + ".");
        }
        catch( Exception e ){
            log.error( e.getMessage(), e );
        }
    }

    private Set<Integer> getProcessTypesIdsWithChildren(String parentTypes) throws BGException {
        assert this.connection != null;

        List<Integer> ptList = ru.bgcrm.util.Utils.toIntegerList(parentTypes);
        Set<Integer> allTypes = new ProcessTypeDAO(this.connection).getTypeTreeRoot().getSelectedChildIds(new HashSet<>(ptList));

        return allTypes;
    }

    private StatusChange getNewChangeStatus(int status, int procId, String comment) {
        StatusChange change = new StatusChange();
        change.setProcessId(procId);
        change.setDate(new Date());
        change.setStatusId(PROCESS_STATUS_CLOSED);
        change.setUserId(User.USER_SYSTEM_ID);
        change.setComment(comment);
        return change;

    }

    private String filterByProcessTypes() {
        if (this.procTypesIdsWithChildren.isEmpty())
            return "";
        else
            return "  AND process.type_id IN(" + ru.bgcrm.util.Utils.toString(this.procTypesIdsWithChildren) + ")";
    }
}
