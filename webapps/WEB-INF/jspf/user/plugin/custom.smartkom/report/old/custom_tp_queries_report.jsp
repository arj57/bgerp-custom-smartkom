<%@ page import="java.util.Enumeration"%>

<%@ page contentType="text/html; charset=UTF-8"%>
<%@ include file="/WEB-INF/jspf/taglibs.jsp"%>

<div class="center1020">
	<h2>ТП - Отчет по процессам</h2>
	
	<%--
    Переменная form - объект класса ru.bgcrm.struts.form.DynActionForm, содержащий параметры запроса.
    --%>
    <c:set var="fromdate" value="${u:parseDate( form.param.fromdate, 'ymd' ) }"/>
    <c:set var="todate" value="${u:parseDate( form.param.todate, 'ymd' ) }"/>
	
	<html:form action="/user/empty">
<!--         <input type="hidden" name="forwardFile" value="/WEB-INF/custom/plugin/report/custom_tp_queries_report.jsp"/> -->
        <input type="hidden" name="forwardFile" value="/WEB-INF/jspf/user/plugin/custom.smartkom/report/old/custom_tp_queries_report.jsp"/>
		
		
		Начало периода:
		<ui:date-time paramName="fromdate" value="first"/>
		
		Окончание периода:
		<ui:date-time paramName="todate" value="last"/>
		
			
		<br/>
		
<!--         <button type="button"  class="btn-grey ml1 mt05" onclick="openUrlToParent( formUrl( this.form ), $(this.form) )">Сформировать</button> -->
        <button type="button"  class="btn-grey ml1 mt05" onclick="$$.ajax.load(this.form, $$.shell.$content(this))">Сформ</button>
	</html:form>
	
	<%--
	Генерация отчёта, если в запросе пришёл параметр date.	
	--%>		
	<c:if test="${not empty fromdate}">
        <%-- в случае, если Slave база не настроена - будет использована обычная --%>
        <sql:query var="result" dataSource="${ctxSlaveDataSource}">
            SELECT COUNT(DISTINCT tot_cli_created), COUNT(DISTINCT tp1_cli_closed), COUNT(DISTINCT oes_created), COUNT(DISTINCT oes_closed), COUNT(DISTINCT tp1_mag_created), COUNT(DISTINCT tp2_mag_closed)
            FROM
            (
            SELECT DISTINCT
            
            
<%--        Создано процессов (клиентская проблема) всего --%>
             CASE
            <%--  WHEN p.create_dt BETWEEN ? AND ?--%>
            WHEN p.create_dt BETWEEN ? AND addtime(?, '23:59:59')
               AND p.type_id IN(12,2,6,5,3,8,7,4,1,9,19,21,43,44,60,56)
              <%-- AND pg.role_id = 0--%>
              THEN p.id
             END AS tot_cli_created,
<%--        Процессы кроме ОЭС, выполненные (закрытые) 1-й линией (группа 3)--%>
             CASE
             <%-- WHEN p.close_dt BETWEEN ? AND ?--%>
             WHEN p.close_dt BETWEEN ? AND addtime(?, '23:59:59')
               AND pg.group_id = 3
               AND p.type_id IN(12,2,6,5,3,8,7,4,1,9,19,21,43,44,60,56)
               AND pg.role_id = 0
              THEN p.id
             END AS tp1_cli_closed,
<%--        Процессы ОЭС, созданные --%>         
             CASE
                <%--  WHEN p.create_dt BETWEEN ? AND ?--%>
            WHEN p.create_dt BETWEEN ? AND addtime(?, '23:59:59')
               AND p.type_id = 30
               AND pg.role_id = 0
              THEN p.id
             END AS oes_created,
<%--        Процессы ОЭС, выполненные (закрытые)    --%>         
             CASE
               <%-- WHEN p.close_dt BETWEEN ? AND ?--%>
             WHEN p.close_dt BETWEEN ? AND addtime(?, '23:59:59')
               AND p.type_id = 30
               AND pg.role_id = 0
              THEN p.id
             END AS oes_closed,
<%--        Процессы (магистальные заявки), созданные 1-й линией (куратор) --%>
             CASE
              <%--  WHEN p.create_dt BETWEEN ? AND ?--%>
            WHEN p.create_dt BETWEEN ? AND addtime(?, '23:59:59')
              AND pg.group_id = 3
              AND p.type_id IN(11,28,50,41,29)
              AND pg.role_id = 1
              THEN p.id
             END AS tp1_mag_created,
             
<%--        Процессы (магистральные заявки), закрытые 2-й линией (исполнитель) --%>
             CASE
             <%-- WHEN p.close_dt BETWEEN ? AND ?--%>
             WHEN p.close_dt BETWEEN ? AND addtime(?, '23:59:59')
              AND pg.group_id = 2
              AND p.type_id IN(11,28,50,41,29)
              AND pg.role_id = 0
              THEN p.id
             END AS tp2_mag_closed
             
            FROM process AS p
            JOIN process_group AS pg ON p.id = pg.process_id 
    <%--        JOIN process_status AS ps ON p.id=ps.process_id --%>
            
            
            
            <%--WHERE (p.close_dt BETWEEN ? AND ?
             OR p.create_dt BETWEEN ? AND ?)--%>
             
             
             WHERE (p.close_dt BETWEEN ? AND addtime(?, '23:59:59') OR p.create_dt BETWEEN ? AND addtime(?, '23:59:59'))
              
             ) AS t1;       
                        
            <sql:param value="${fromdate}"/>        
            <sql:param value="${todate}"/>
            <sql:param value="${fromdate}"/>        
            <sql:param value="${todate}"/>
            <sql:param value="${fromdate}"/>        
            <sql:param value="${todate}"/>
            <sql:param value="${fromdate}"/>        
            <sql:param value="${todate}"/>
            <sql:param value="${fromdate}"/>        
            <sql:param value="${todate}"/>
            <sql:param value="${fromdate}"/>        
            <sql:param value="${todate}"/>
            <sql:param value="${fromdate}"/>        
            <sql:param value="${todate}"/>
            <sql:param value="${fromdate}"/>        
            <sql:param value="${todate}"/>
        </sql:query>

<!--            WHERE close_dt>=? AND close_dt<DATE_ADD(?, INTERVAL 1 MONTH) -->

		<table style="width: 100%;" class="data mt1">
			<tr>
				
				<td>Принято клиентских заявок</td>
				<td>Выполнено клиентских(1L)</td>
				<td>Создано выездов ОЭС</td>
				<td>Вып. выездов ОЭС</td>
				<td>Принято маг. заявок(1L)</td>
				<td>Закрыто маг. заявок(2L)</td>
			</tr>	
<!--            tot_cli_created, tp1_cli_closed, oes_closed, tp1_mag_created, tp2_mag_closed -->

            <c:forEach var="row" items="${result.rowsByIndex}">
                
                <c:set var="tot_cli_created" value="${row[0]}"/>
                <c:set var="tp1_cli_closed" value="${row[1]}"/>
                <c:set var="oes_created" value="${row[2]}"/>
                <c:set var="oes_closed" value="${row[3]}"/>
                <c:set var="tp1_mag_created" value="${row[4]}"/>
                <c:set var="tp2_mag_closed" value="${row[5]}"/>
                <tr>
                    
                    <td>${tot_cli_created}</td>
                    <td>${tp1_cli_closed}</td>
                    <td>${oes_created}</td>
                    <td>${oes_closed}</td>
                    <td>${tp1_mag_created}</td>
                    <td>${tp2_mag_closed}</td>
                </tr>           
            </c:forEach>

		</table>	
	</c:if>
	
</div>