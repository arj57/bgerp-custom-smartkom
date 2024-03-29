package org.bgerp.plugin.custom.smartkom.action.report;

import java.util.Calendar;
import java.util.Date;

import org.apache.struts.action.ActionForward;
import org.bgerp.plugin.custom.smartkom.Plugin;
import org.bgerp.plugin.report.action.ReportActionBase;
import org.bgerp.plugin.report.model.Column;
import org.bgerp.plugin.report.model.Columns;
import org.bgerp.plugin.report.model.Data;
import org.bgerp.util.sql.PreparedQuery;

import static  ru.bgcrm.dao.process.Tables.*;
import ru.bgcrm.servlet.ActionServlet.Action;
import ru.bgcrm.struts.form.DynActionForm;
import ru.bgcrm.util.TimeUtils;
import ru.bgcrm.util.sql.ConnectionSet;

/**
 * This class marked as action for specified path.
 * It matches the form action specified in the .jsp code.
 */
@Action(path = "/user/plugin/custom.smartkom/report/abon")
public class AbonReport extends ReportActionBase {

    /**
     * This overwritten method is required because of action specification.
     */
    @Override
    public ActionForward unspecified(DynActionForm form, ConnectionSet conSet) throws Exception {
        return super.unspecified(form, conSet);
    }

    @Override
    public String getTitle() {
        return Plugin.INSTANCE.getLocalizer().l("Отчет Абонгруппы");
    }

    @Override
    protected String getHref() {
        // URL suffix for 'user' interface
        // TODO: must be "report/custom.smartkom/magistral", but not handled properly on frontend
        return "report/custom/smartkom/abon";
    }

    @Override
    public Columns getColumns() {
        final Columns COLUMNS = new Columns(
                new Column.ColumnInteger("cnt_izm_created", null, "Создано заявок \"Изменения в услуге\""),
                new Column.ColumnInteger("cnt_izm_closed", null, "Закрыто заявок \"Изменения в услуге\" 2-ой линией"),
                new Column.ColumnInteger("cnt_otkl_created", null, "Отключения"),
                new Column.ColumnInteger("cnt_otkl_closed", null, "Отключения 2-ой линией")
                );

        return COLUMNS;
    }

    @Override
    protected String getJsp() {
        return Plugin.PATH_JSP_USER + "/report/abon.jsp";
    }

    @Override
    protected Selector getSelector() {
        return new Selector() {
            @Override
            protected void select(ConnectionSet conSet, Data data) throws Exception {
                Calendar cal = Calendar.getInstance();
                cal.set(Calendar.DAY_OF_MONTH, 1);

                final var form = data.getForm();
                final var dateFrom = form.getParamDate("dateFrom", cal.getTime(), true);
                final var dateTo = TimeUtils.getNextDay(form.getParamDate("dateTo", new Date(), true));
                final int CHANGE_OF_SERVICES_PROC_TYPE_ID = 13;
                final int CLIENTS_DISABLING__PROC_TYPE_ID = 14;
                final int EXECUTER_ROLE_ID = 0;

                try(PreparedQuery pq = new PreparedQuery(conSet.getSlaveConnection());) {
                    pq.addQuery(SQL_SELECT_COUNT_ROWS);
                    pq.addQuery(" COUNT(izm_created) AS cnt_izm_created, COUNT(izm_closed) AS cnt_izm_closed,");
                    pq.addQuery(" COUNT(otkl_created) AS cnt_otkl_created, COUNT(otkl_closed) AS cnt_otkl_closed");
                    pq.addQuery(SQL_FROM + " (");
                    pq.addQuery(SQL_SELECT + " DISTINCT");
    //                Создано процессов (Изменения в услуге) всего
                    pq.addQuery(" CASE WHEN p.create_dt BETWEEN ? AND ?");
                    pq.addDate(dateFrom);
                    pq.addDate(dateTo);
                    pq.addQuery("  AND p.type_id = ?");
                    pq.addInt(CHANGE_OF_SERVICES_PROC_TYPE_ID);
    //                pd.addQuery("  AND pg.role_id = ?");
    //                pd.addInt(EXECUTER_ROLE_ID);
                    pq.addQuery(" THEN p.id");
                    pq.addQuery(" END AS izm_created,");
    //              Процессы Изменения в услуге выполненные (закрытые) 2-й линией (группа 2)--
                    pq.addQuery(" CASE WHEN p.close_dt BETWEEN ? AND ?");
                    pq.addDate(dateFrom);
                    pq.addDate(dateTo);
                    pq.addQuery("  AND pg.group_id = 2");
                    pq.addQuery("  AND p.type_id = ?");
                    pq.addInt(CHANGE_OF_SERVICES_PROC_TYPE_ID);
    //                pd.addQuery("  AND pg.role_id = ?");
    //                pd.addInt(EXECUTER_ROLE_ID);
                    pq.addQuery("  THEN p.id");
                    pq.addQuery(" END AS izm_closed,");
    //              Создано процессов (Отключения) всего --%>
                    pq.addQuery(" CASE WHEN p.create_dt BETWEEN ? AND ?");
                    pq.addDate(dateFrom);
                    pq.addDate(dateTo);
                    pq.addQuery("  AND p.type_id = ?");
                    pq.addInt(CLIENTS_DISABLING__PROC_TYPE_ID);
    //                pd.addQuery("  AND pg.role_id = ?");
    //                pd.addInt(EXECUTER_ROLE_ID);
                    pq.addQuery(" THEN p.id");
                    pq.addQuery(" END AS otkl_created,");
    //              Процессы (Отключения), закрытые 2-й линией (исполнитель)
                    pq.addQuery(" CASE WHEN p.close_dt BETWEEN ? AND ?");
                    pq.addDate(dateFrom);
                    pq.addDate(dateTo);
                    pq.addQuery(" AND pg.group_id = 2");
                    pq.addQuery("  AND p.type_id = ?");
                    pq.addInt(CLIENTS_DISABLING__PROC_TYPE_ID);
    //                pd.addQuery("  AND pg.role_id = ?");
    //                pd.addInt(EXECUTER_ROLE_ID);
                    pq.addQuery(" THEN p.id");
                    pq.addQuery(" END AS otkl_closed");
                    pq.addQuery(SQL_FROM + TABLE_PROCESS + " AS p");
                    pq.addQuery(SQL_INNER_JOIN + TABLE_PROCESS_GROUP + " AS pg ON p.id = pg.process_id");
                    pq.addQuery(SQL_WHERE);
                    pq.addQuery(" p.close_dt BETWEEN ? AND ?");
    //                        "  OR p.create_dt BETWEEN ? AND ?
                    pq.addDate(dateFrom);
                    pq.addDate(dateTo);
                    pq.addQuery("  AND pg.role_id = ?");
                    pq.addInt(EXECUTER_ROLE_ID);
                    pq.addQuery(" ) AS t1");
    
                    var rs = pq.executeQuery();
                    while(rs.next()) {
                        final var rec = data.addRecord();
                        rec.add(rs.getInt("cnt_izm_created"));
                        rec.add(rs.getInt("cnt_izm_closed"));
                        rec.add(rs.getInt("cnt_otkl_created"));
                        rec.add(rs.getInt("cnt_otkl_closed"));
                    }
    
                    setRecordCount(form.getPage(), pq.getPrepared());
                }
            }
        };
    }
}
