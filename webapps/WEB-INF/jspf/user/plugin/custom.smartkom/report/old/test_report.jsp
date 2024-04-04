<%@ page import="java.util.Enumeration"%>

<%@ page contentType="text/html; charset=UTF-8"%>
<%@ include file="/WEB-INF/jspf/taglibs.jsp"%>

<div class="center1020">
	<h2>"Отдел системного сопровождения"</h2>
	<br/>
	
	В таблице "Системное сопровождение " Итого считаться не будет, все выводы по клиентам это разные сущности.  
	
	<br/>
	<br/>
	
	<%--
    Переменная form - объект класса ru.bgcrm.struts.form.DynActionForm, содержащий параметры запроса.
    --%>
    <c:set var="fromdate" value="${u:parseDate( form.param.fromdate, 'ymd' ) }"/>
    <c:set var="todate" value="${u:parseDate( form.param.todate, 'ymd' ) }"/>
	
	<html:form action="/user/empty">
	<%--	<input type="hidden" name="forwardFile" value="/WEB-INF/custom/plugin/report/test_report.jsp"/> --%>
	<input type="hidden" name="forwardFile" value="/WEB-INF/jspf/user/plugin/custom.smartkom/report/old/test_report.jsp"/>
		
		
		Начало периода:
		<ui:date-time paramName="fromdate" value="first"/>
		
		Окончание периода:
		<ui:date-time paramName="todate" value="last"/>
		
			
		<br/>
		
		<button type="button"  class="btn-grey ml1 mt05" onclick="openUrlToParent( formUrl( this.form ), $(this.form) )">Сформировать</button>
	</html:form>
	
	
	
	 <c:if test="${not empty fromdate}">
		<%-- в случае, если Slave база не настроена - будет использована обычная --%>
		<sql:query var="result" dataSource="${ctxSlaveDataSource}">




	SELECT "Январь 2020 г." AS title,
	COUNT(tot_cli_created), COUNT(tp1_cli_closed)
	FROM
	 (
	 SELECT DISTINCT
     CASE
	 WHEN p.create_dt BETWEEN '2020-01-01' AND '2020-02-01'
	 AND p.type_id IN(12,2,6,5,3,8,7,4,1,9,19,21,43,44,60,56)
	 AND pg.role_id = 0
	 THEN p.id
	 END AS tot_cli_created,
	 
	 CASE
			
			 WHEN p.close_dt BETWEEN '2020-01-01' AND '2020-02-01'
			   AND pg.group_id = 3
			   AND p.type_id IN(12,2,6,5,3,8,7,4,1,9,19,21,43,44,60,56)
			   AND pg.role_id = 0
			  THEN p.id
			 END AS tp1_cli_closed
			 
			FROM process AS p
			JOIN process_group AS pg ON p.id = pg.process_id 
			JOIN process_status AS ps ON p.id=ps.process_id 
	 
	  WHERE (p.close_dt BETWEEN '2020-01-01' AND '2020-02-01' OR p.create_dt BETWEEN '2020-01-01' AND '2020-02-01')
			 
			  
			 ) AS t1 
			 	
    UNION
    
	SELECT "Февраль 2020 г." AS title,
	COUNT(tot_cli_created), COUNT(tp1_cli_closed)
	FROM
	 (
	 SELECT DISTINCT
     CASE
	 WHEN p.create_dt BETWEEN '2019-09-01' AND '2019-10-01'
	 AND p.type_id IN(12,2,6,5,3,8,7,4,1,9,19,21,43,44,60,56)
	 AND pg.role_id = 0
	 THEN p.id
	 END AS tot_cli_created,
	 
	 CASE
			
			 WHEN p.close_dt  BETWEEN '2019-09-01' AND '2019-10-01'
			   AND pg.group_id = 3
			   AND p.type_id IN(12,2,6,5,3,8,7,4,1,9,19,21,43,44,60,56)
			   AND pg.role_id = 0
			  THEN p.id
			 END AS tp1_cli_closed
			 
			FROM process AS p
			JOIN process_group AS pg ON p.id = pg.process_id 
			JOIN process_status AS ps ON p.id=ps.process_id 
	 
	  WHERE (p.close_dt BETWEEN '2019-09-01' AND '2019-10-01' OR p.create_dt BETWEEN '2019-09-01' AND '2019-10-01')
			 
			  
			 ) AS t2 ;	
			
		</sql:query>

		
		<table style="width: 100%;" class="data mt1">
			
		
			<tr>
				<td bgcolor=#E6E6FA width="300">Дата</td>
				<td bgcolor=#E6E6FA width="200">Принято клиентских заявок</td>
				<td bgcolor=#E6E6FA width="200">Выполнено клиентских</td>

				
			</tr>	
			
				<c:forEach var="row" items="${result.rowsByIndex}">
				<c:set var="sum_pr" value="${row[0]}"/>
				<c:set var="summa" value="${row[1]}"/>
				<c:set var="nothing1" value="${row[2]}"/>
	
							
			<tr>
					<td bgcolor=#F5F5F5>${sum_pr}</td>	
					<td>${summa}</td>
					<td>${nothing1}</td>
			</tr>	
				
						
			</c:forEach>
		</table>	
	</c:if>


	
	
	
	<c:if test="${not empty fromdate}">
		<%-- в случае, если Slave база не настроена - будет использована обычная --%>
		<sql:query var="result" dataSource="${ctxSlaveDataSource}">
	
			SELECT
			table_user.title AS title,			
			COUNT(DISTINCT table_process.CompletedProcesses) AS CompletedProcesses,
			COUNT(DISTINCT table_process.BeginningOfPeriod) AS BeginningOfPeriod,
			COUNT(DISTINCT table_process.EndOfPeriod) AS EndOfPeriod									
			FROM user AS table_user 
			
			LEFT JOIN (SELECT pe.user_id AS user_id,			
			CASE WHEN ps.status_id = 5 AND ps.dt BETWEEN ? AND addtime(?, '23:59:59') THEN p.id END AS CompletedProcesses,			
			CASE WHEN p.status_id IN(1,2) AND p.status_dt <= addtime(?, '23:59:59') THEN p.id END AS BeginningOfPeriod,			
			CASE WHEN p.status_id IN(1,2) AND p.status_dt <= addtime(?, '23:59:59') THEN p.id END AS EndOfPeriod			
			FROM process AS p			 
			JOIN process_status AS ps ON p.id=ps.process_id 
			JOIN process_executor AS pe ON p.id=pe.process_id 
			WHERE ps.dt <= addtime(?, '23:59:59')
			AND p.type_id IN(26,47,49,48)			 	 		
	 		AND pe.role_id = 0
	 		AND pe.user_id IN(41,62,75)
			AND ps.status_id IN(1,2,5)) AS table_process ON table_user.id = table_process.user_id      
			
			WHERE table_user.id IN(41,62,75)
			
			GROUP BY
			table_user.title
			
			
		 
			
			<sql:param value="${fromdate}"/>		
			<sql:param value="${todate}"/>
			<sql:param value="${fromdate}"/>
			<sql:param value="${todate}"/>
			<sql:param value="${todate}"/>			
			
		</sql:query>

		
		<table style="width: 100%;" class="data mt1">
			
		
			<tr>
				<td bgcolor=#E6E6FA width="300">Сотрудник</td>
				<td bgcolor=#E6E6FA width="200">Выполнено заявок</td>
				<td bgcolor=#E6E6FA width="200">Открытых заявок на начало периода</td>
				<td bgcolor=#E6E6FA width="200">Открытых заявок на конец периода</td>
			</tr>	


			<c:forEach var="row" items="${result.rowsByIndex}">
				
				<c:set var="sotrudniki" value="${row[0]}"/>
				<c:set var="CompletedProcesses" value="${row[1]}"/>
				<c:set var="BeginningOfPeriod" value="${row[2]}"/>
				<c:set var="EndOfPeriod" value="${row[3]}"/>
						
				<tr>
					<td bgcolor=#F5F5F5>${sotrudniki}</td>	
					<td>${CompletedProcesses}</td>
					<td>${BeginningOfPeriod}</td>
					<td>${EndOfPeriod}</td>					
				</tr>	
				
						
			</c:forEach>
		</table>	
	</c:if>
	
				<c:if test="${not empty fromdate}">
		<%-- в случае, если Slave база не настроена - будет использована обычная --%>
		<sql:query var="result" dataSource="${ctxSlaveDataSource}">
	
	
	
		 	SELECT "Потенциальное подключение 'Интернет'" AS title,
			COUNT(DISTINCT p.id)

			FROM process AS p
			JOIN process_group AS pg ON p.id = pg.process_id 
			JOIN process_status AS ps ON p.id=ps.process_id 
			JOIN process_executor AS pe ON p.id=pe.process_id
			JOIN param_list ON p.id = param_list.id AND param_list.param_id = 102 
			WHERE p.create_dt BETWEEN ? AND ?
			AND p.type_id IN(76,77)
	 		AND pg.role_id = 0
	 		AND pe.role_id = 0
	 		AND param_list.value=1
	 		
			
			UNION ALL
			
		    SELECT "Потенциальное подключение 'Смотрёшка'" AS title,
			COUNT(DISTINCT p.id)
			
			FROM process AS p
			JOIN process_group AS pg ON p.id = pg.process_id 
			JOIN process_status AS ps ON p.id=ps.process_id 
			JOIN process_executor AS pe ON p.id=pe.process_id
			JOIN param_list ON p.id = param_list.id AND param_list.param_id = 102 
			WHERE p.create_dt BETWEEN ? AND ?
			AND p.type_id IN(76,77)
	 		AND pg.role_id = 0
	 		AND pe.role_id = 0
	 		AND param_list.value=4
			
			UNION ALL 
			
			SELECT "Потенциальное подключение 'Видеонаблюдение'" AS title,
			COUNT(DISTINCT p.id)
			
			FROM process AS p
			JOIN process_group AS pg ON p.id = pg.process_id 
			JOIN process_status AS ps ON p.id=ps.process_id 
			JOIN process_executor AS pe ON p.id=pe.process_id
			JOIN param_list ON p.id = param_list.id AND param_list.param_id = 102 
			WHERE p.create_dt BETWEEN ? AND ?
			AND p.type_id IN(76,77)
	 		AND pg.role_id = 0
	 		AND pe.role_id = 0
	 		AND param_list.value=3
	 		
	 		UNION ALL 
			
			SELECT "Потенциальное подключение 'Интернет + видеонаблюдение'" AS title,
			COUNT(DISTINCT p.id)
			
			FROM process AS p
			JOIN process_group AS pg ON p.id = pg.process_id 
			JOIN process_status AS ps ON p.id=ps.process_id 
			JOIN process_executor AS pe ON p.id=pe.process_id
			JOIN param_list ON p.id = param_list.id AND param_list.param_id = 102 
			WHERE p.create_dt BETWEEN ? AND ?
			AND p.type_id IN(76,77)
	 		AND pg.role_id = 0
	 		AND pe.role_id = 0
	 		AND param_list.value=2
	 		
	 		UNION ALL 
			
			SELECT "Потенциальное подключение 'Кабельное ТВ'" AS title,
			COUNT(DISTINCT p.id)
			
			FROM process AS p
			JOIN process_group AS pg ON p.id = pg.process_id 
			JOIN process_status AS ps ON p.id=ps.process_id 
			JOIN process_executor AS pe ON p.id=pe.process_id
			JOIN param_list ON p.id = param_list.id AND param_list.param_id = 102 
			WHERE p.create_dt BETWEEN ? AND ?
			AND p.type_id IN(76,77)
	 		AND pg.role_id = 0
	 		AND pe.role_id = 0
	 		AND param_list.value=5
	 		
	 		UNION ALL 
			
			SELECT "Потенциальное подключение 'Телефония'" AS title,
			COUNT(DISTINCT p.id)
			
			FROM process AS p
			JOIN process_group AS pg ON p.id = pg.process_id 
			JOIN process_status AS ps ON p.id=ps.process_id 
			JOIN process_executor AS pe ON p.id=pe.process_id
			JOIN param_list ON p.id = param_list.id AND param_list.param_id = 102 
			WHERE p.create_dt BETWEEN ? AND ?
			AND p.type_id IN(76,77)
	 		AND pg.role_id = 0
	 		AND pe.role_id = 0
	 		AND param_list.value=6
			
 						
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

		
		<table style="width: 100%;" class="data mt1">
			
		
			<tr>
				<td bgcolor=#E6E6FA width="300">Тип услуги</td>
				<td bgcolor=#E6E6FA width="200">Количество</td>
				
				
			</tr>	


			<c:forEach var="row" items="${result.rowsByIndex}">
				<c:set var="sum_pr" value="${row[0]}"/>
				<c:set var="summa" value="${row[1]}"/>
				
	
				
	
	
						
				<tr>
					<td bgcolor=#F5F5F5>${sum_pr}</td>	
					<td>${summa}</td>
					
					
		
				</tr>	
				
						
			</c:forEach>
		</table>	
	</c:if>
	
	<c:if test="${not empty fromdate}">
		<%-- в случае, если Slave база не настроена - будет использована обычная --%>
		<sql:query var="result" dataSource="${ctxSlaveDataSource}">
	
	
	
		 	SELECT "Новое подключение 'Интернет'" AS title,
			COUNT(DISTINCT p.id)

			FROM process AS p
			JOIN process_group AS pg ON p.id = pg.process_id 
			JOIN process_status AS ps ON p.id=ps.process_id 
			JOIN process_executor AS pe ON p.id=pe.process_id
			JOIN param_list ON p.id = param_list.id AND param_list.param_id = 102 
			WHERE p.create_dt BETWEEN ? AND ?
			AND p.type_id IN(76,78)
	 		AND pg.role_id = 0
	 		AND pe.role_id = 0
	 		AND param_list.value=1
	 	
	 		
			
			UNION ALL
			
		    SELECT "Новое подключение 'Смотрёшка'" AS title,
			COUNT(DISTINCT p.id)
			
			FROM process AS p
			JOIN process_group AS pg ON p.id = pg.process_id 
			JOIN process_status AS ps ON p.id=ps.process_id 
			JOIN process_executor AS pe ON p.id=pe.process_id
			JOIN param_list ON p.id = param_list.id AND param_list.param_id = 102 
			WHERE p.create_dt BETWEEN ? AND ?
			AND p.type_id IN(76,78)
	 		AND pg.role_id = 0
	 		AND pe.role_id = 0
	 		AND param_list.value=4
			
			UNION ALL 
			
			SELECT "Новое подключение 'Видеонаблюдение'" AS title,
			COUNT(DISTINCT p.id)
			
			FROM process AS p
			JOIN process_group AS pg ON p.id = pg.process_id 
			JOIN process_status AS ps ON p.id=ps.process_id 
			JOIN process_executor AS pe ON p.id=pe.process_id
			JOIN param_list ON p.id = param_list.id AND param_list.param_id = 102 
			WHERE p.create_dt BETWEEN ? AND ?
			AND p.type_id IN(76,78)
	 		AND pg.role_id = 0
	 		AND pe.role_id = 0
	 		AND param_list.value=3
	 		
	 		UNION ALL 
			
			SELECT "Новое подключение 'Интернет + видеонаблюдение'" AS title,
			COUNT(DISTINCT p.id)
			
			FROM process AS p
			JOIN process_group AS pg ON p.id = pg.process_id 
			JOIN process_status AS ps ON p.id=ps.process_id 
			JOIN process_executor AS pe ON p.id=pe.process_id
			JOIN param_list ON p.id = param_list.id AND param_list.param_id = 102 
			WHERE p.create_dt BETWEEN ? AND ?
			AND p.type_id IN(76,78)
	 		AND pg.role_id = 0
	 		AND pe.role_id = 0
	 		AND param_list.value=2
	 		
	 		UNION ALL 
			
			SELECT "Новое подключение 'Кабельное ТВ'" AS title,
			COUNT(DISTINCT p.id)
			
			FROM process AS p
			JOIN process_group AS pg ON p.id = pg.process_id 
			JOIN process_status AS ps ON p.id=ps.process_id 
			JOIN process_executor AS pe ON p.id=pe.process_id
			JOIN param_list ON p.id = param_list.id AND param_list.param_id = 102 
			WHERE p.create_dt BETWEEN ? AND ?
			AND p.type_id IN(76,78)
	 		AND pg.role_id = 0
	 		AND pe.role_id = 0
	 		AND param_list.value=5
	 		
	 		UNION ALL 
			
			SELECT "Новое подключение 'Телефония'" AS title,
			COUNT(DISTINCT p.id)
			
			FROM process AS p
			JOIN process_group AS pg ON p.id = pg.process_id 
			JOIN process_status AS ps ON p.id=ps.process_id 
			JOIN process_executor AS pe ON p.id=pe.process_id
			JOIN param_list ON p.id = param_list.id AND param_list.param_id = 102 
			WHERE p.create_dt BETWEEN ? AND ?
			AND p.type_id IN(76,78)
	 		AND pg.role_id = 0
	 		AND pe.role_id = 0
	 		AND param_list.value=6
			
 						
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

		
		<table style="width: 100%;" class="data mt1">
			
		
			<tr>
				<td bgcolor=#E6E6FA width="300">Тип услуги</td>
				<td bgcolor=#E6E6FA width="200">Количество</td>
				
				
			</tr>	


			<c:forEach var="row" items="${result.rowsByIndex}">
				<c:set var="sum_pr" value="${row[0]}"/>
				<c:set var="summa" value="${row[1]}"/>
				
	
				
	
	
						
				<tr>
					<td bgcolor=#F5F5F5>${sum_pr}</td>	
					<td>${summa}</td>
					
					
		
				</tr>	
				
						
			</c:forEach>
		</table>	
	</c:if>
	
	
</div>