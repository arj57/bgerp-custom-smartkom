<%@ page import="java.util.Enumeration"%>

<%@ page contentType="text/html; charset=UTF-8"%>
<%@ include file="/WEB-INF/jspf/taglibs.jsp"%>

<div class="center1020">
	<h2>Отчет Абон.группы</h2>
	
	<%--
    Переменная form - объект класса ru.bgcrm.struts.form.DynActionForm, содержащий параметры запроса.
    --%>
    <c:set var="fromdate" value="${u:parseDate( form.param.fromdate, 'ymd' ) }"/>
    <c:set var="todate" value="${u:parseDate( form.param.todate, 'ymd' ) }"/>
	
	<html:form action="/user/empty">
		<input type="hidden" name="forwardFile" value="//WEB-INF/jspf/user/plugin/custom.smartkom/report/old/custom_ag_report.jsp"/>
		
		
		Начало периода:
		<ui:date-time paramName="fromdate" value="first"/>
		
		Окончание периода:
		<ui:date-time paramName="todate" value="last"/>
		
			
		<br/>
		
		<button type="button"  class="btn-grey ml1 mt05" onclick="openUrlToParent( formUrl( this.form ), $(this.form) )">Сформировать</button>
	</html:form>
	
	<%--
	Генерация отчёта, если в запросе пришёл параметр date.	
	--%>		
	<c:if test="${not empty fromdate}">
		<%-- в случае, если Slave база не настроена - будет использована обычная --%>
		<sql:query var="result" dataSource="${ctxSlaveDataSource}">
			SELECT COUNT(izm_created), COUNT(izm_closed), COUNT(otkl_created), COUNT(otkl_closed)
			FROM
			(
			SELECT DISTINCT
<%--		Создано процессов (Изменения в услуге) всего --%>
			 CASE
			  WHEN p.create_dt BETWEEN ? AND ?
			   AND p.type_id = 13
			   AND pg.role_id = 0
			  THEN p.id
			 END AS izm_created,
<%--		Процессы Изменения в услуге выполненные (закрытые) 2-й линией (группа 2)--%>
			 CASE
			  WHEN p.close_dt BETWEEN ? AND ?
			   AND pg.group_id = 2
			   AND p.type_id = 13
			   AND pg.role_id = 0
			  THEN p.id
			 END AS izm_closed,
<%--		Создано процессов (Отключения) всего --%>
			 CASE
			  WHEN p.create_dt BETWEEN ? AND ?
			   AND p.type_id = 14
			   AND pg.role_id = 0
			  THEN p.id
			 END AS otkl_created,
			 
<%--		Процессы (Отключения), закрытые 2-й линией (исполнитель) --%>
			 CASE
			  WHEN p.close_dt BETWEEN ? AND ?
			  AND pg.group_id = 2
			  AND p.type_id = 14
			  AND pg.role_id = 0
			  THEN p.id
			 END AS otkl_closed
			 
			FROM process AS p
			JOIN process_group AS pg ON p.id = pg.process_id 
			
			WHERE (p.close_dt BETWEEN ? AND ?
			 OR p.create_dt BETWEEN ? AND ?)
			  
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
			
		</sql:query>

<!-- 			WHERE close_dt>=? AND close_dt<DATE_ADD(?, INTERVAL 1 MONTH) -->

		
		<table style="width: 100%;" class="data mt1">
			<tr>
				<td>Создано заявок "Изменения в услуге"</td>
				<td>Закрыто заявок "Изменения в услуге" 2-ой линией</td>
				<td>Создано заявок "Отключения"</td>
				<td>Закрыто заявок "Отключения" 2-ой линией</td>
				
			</tr>	
<!-- 			tot_cli_created, tp1_cli_closed, oes_closed, tp1_mag_created, tp2_mag_closed -->

			<c:forEach var="row" items="${result.rowsByIndex}">
				<c:set var="izm_created" value="${row[0]}"/>
				<c:set var="izm_closed" value="${row[1]}"/>
				<c:set var="otkl_created" value="${row[2]}"/>
				<c:set var="otkl_closed" value="${row[3]}"/>
				
				<tr>
					<td>${izm_created}</td>
					<td>${izm_closed}</td>
					<td>${otkl_created}</td>
					<td>${otkl_closed}</td>
				</tr>			
			</c:forEach>
		</table>	
	</c:if>
	    
</div>