<%@ page import="java.util.Enumeration"%>

<%@ page contentType="text/html; charset=UTF-8"%>
<%@ include file="/WEB-INF/jspf/taglibs.jsp"%>

<div class="center1020">
	<h2>"Отчет по подключению услуг для физ.лиц"</h2>
	<br/>

	
	<%--
    Переменная form - объект класса ru.bgcrm.struts.form.DynActionForm, содержащий параметры запроса.
    --%>
    <c:set var="fromdate" value="${tu.parse( form.param.fromdate, 'ymd' ) }"/>
    <c:set var="todate" value="${tu.parse( form.param.todate, 'ymd' ) }"/>
	
	<html:form action="/user/empty">
		<input type="hidden" name="forwardFile" value="/WEB-INF/jspf/user/plugin/custom.smartkom/report/old/custom_podkl_fiz_report.jsp"/>
		
		
		Начало периода:
		<ui:date-time paramName="fromdate" value="first"/>
		
		Окончание периода:
		<ui:date-time paramName="todate" value="last"/>
		
			
		<br/>
		
		<button type="button"  class="btn-grey ml1 mt05" onclick="$$.ajax.load(this, $(this.form).parent())">Сформировать</button>
	</html:form>
	
	
	
	
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
			AND p.type_id IN(76,77,78)
	 		AND pg.role_id = 0
	 		AND pe.role_id = 0
	 		AND param_list.value=1
	 		
	 		UNION ALL
			
		    SELECT "Потенциальное подключение 'Интернет + ТВ'" AS title,
			COUNT(DISTINCT p.id)
			
			FROM process AS p
			JOIN process_group AS pg ON p.id = pg.process_id 
			JOIN process_status AS ps ON p.id=ps.process_id 
			JOIN process_executor AS pe ON p.id=pe.process_id
			JOIN param_list ON p.id = param_list.id AND param_list.param_id = 102 
			WHERE p.create_dt BETWEEN ? AND ?
			AND p.type_id IN(76,77,78)
	 		AND pg.role_id = 0
	 		AND pe.role_id = 0
	 		AND param_list.value=2
			
			UNION ALL
			
		    SELECT "Потенциальное подключение 'Интернет + видеонаблюдение'" AS title,
			COUNT(DISTINCT p.id)
			
			FROM process AS p
			JOIN process_group AS pg ON p.id = pg.process_id 
			JOIN process_status AS ps ON p.id=ps.process_id 
			JOIN process_executor AS pe ON p.id=pe.process_id
			JOIN param_list ON p.id = param_list.id AND param_list.param_id = 102 
			WHERE p.create_dt BETWEEN ? AND ?
			AND p.type_id IN(76,77,78)
	 		AND pg.role_id = 0
	 		AND pe.role_id = 0
	 		AND param_list.value=3
			
			UNION ALL 
			
			SELECT "Потенциальное подключение 'Видеонаблюдение'" AS title,
			COUNT(DISTINCT p.id)
			
			FROM process AS p
			JOIN process_group AS pg ON p.id = pg.process_id 
			JOIN process_status AS ps ON p.id=ps.process_id 
			JOIN process_executor AS pe ON p.id=pe.process_id
			JOIN param_list ON p.id = param_list.id AND param_list.param_id = 102 
			WHERE p.create_dt BETWEEN ? AND ?
			AND p.type_id IN(76,77,78)
	 		AND pg.role_id = 0
	 		AND pe.role_id = 0
	 		AND param_list.value=4
	 		
	 		
	 		UNION ALL 
			
			SELECT "Потенциальное подключение 'Кабельное ТВ'" AS title,
			COUNT(DISTINCT p.id)
			
			FROM process AS p
			JOIN process_group AS pg ON p.id = pg.process_id 
			JOIN process_status AS ps ON p.id=ps.process_id 
			JOIN process_executor AS pe ON p.id=pe.process_id
			JOIN param_list ON p.id = param_list.id AND param_list.param_id = 102 
			WHERE p.create_dt BETWEEN ? AND ?
			AND p.type_id IN(76,77,78)
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
			AND p.type_id IN(76,77,78)
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
			
		    SELECT "Новое подключение 'Интернет + ТВ'" AS title,
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
	 		AND param_list.value=3
	 		
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
	 		AND param_list.value=4
	 		
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