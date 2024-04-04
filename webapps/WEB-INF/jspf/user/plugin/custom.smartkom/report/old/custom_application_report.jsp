<%@ page import="java.util.Enumeration"%>

<%@ page contentType="text/html; charset=UTF-8"%>
<%@ include file="/WEB-INF/jspf/taglibs.jsp"%>

<div class="center1020">
	<h2>"Заявка - отчет по выполненным процессам"</h2>
	<br/>
	
	
	В указанный период было принятие подключения (Установлен статус "Подключен/Активен"). А также процесс на данный момент находится в статусе
	"Подключен/Активен", либо "Принят ОТК".
	<br/>
	<br/>
	
	<%--
    Переменная form - объект класса ru.bgcrm.struts.form.DynActionForm, содержащий параметры запроса.
    --%>
    <c:set var="fromdate" value="${tu.parse( form.param.fromdate, 'ymd' ) }"/>
    <c:set var="todate" value="${tu.parse( form.param.todate, 'ymd' ) }"/>
<%-- 	<c:set var="listParamIds" value="${form.getSelectedValues('listParam')}"/>
	<c:set var="status" value="${form.getSelectedValues( 'status' )}"/> --%>
	<html:form action="/user/empty">
	<%--	<input type="hidden" name="forwardFile" value="/WEB-INF/custom/plugin/report/test_report.jsp"/> --%>
	<input type="hidden" name="forwardFile" value="/WEB-INF/jspf/user/plugin/custom.smartkom/report/old/custom_application_report.jsp"/>
		
		
		Начало периода:
		<ui:date-time paramName="fromdate" value="first"/>
		
		Окончание периода:
		<ui:date-time paramName="todate" value="last"/>
		
		<br/>
<%-- 		<c:set var="listParam" value="${ctxParameterMap[u:int(114)]}"/>
	    <ui:combo-check
		    list="${listParam.listParamValues}" values="${listParamIds}"
		    prefixText="Организация:" widthTextValue="150px"
		    showFilter="1" paramName="listParam"/>	
		
		
		<ui:combo-check
			styleClass="ml05"
			list="${ctxProcessStatusList}" values="${status}"
			prefixText="Статус:" widthTextValue="150px"
			showFilter="1" paramName="status"/>--%>
			<br/>
		<br/>
		<button type="button"  class="btn-grey ml1 mt05" onclick="$$.ajax.load(this, $(this.form).parent())">Сформировать</button>
	</html:form>
				
 		<c:if test="${not empty fromdate}">
		
		<sql:query var="result" dataSource="${ctxSlaveDataSource}">
SELECT
users.title,
SUM(process.count_podk) as count_podk,
SUM(process.count_moder) as count_moder,
SUM(process.count_podk) + SUM(process.count_moder) as count_itog,
SUM(ROUND(process.cost / process.count_executors,2)) as cost_user,
GROUP_CONCAT(process.id SEPARATOR ', ')
FROM(
	SELECT 
	process_itog.id as id,
	CASE 
	 	WHEN process_itog.type_id = 119 THEN 1
	 	ElSE 0
	END as count_podk,
	CASE
	 	WHEN process_itog.type_id = 124 THEN 1
	 	ElSE 0
	END as count_moder,	
	SUM(process_itog.count_executors) as count_executors,
	SUM(process_itog.cost + process_itog.cost_sks) as cost	
	FROM(SELECT 
		process.id as id,
		process.type_id as type_id,
		COUNT(DISTINCT process_executor.user_id) AS count_executors,
		SUM(0) as cost,
		SUM(0) as cost_sks	
		FROM process	
		INNER JOIN (SELECT
				process_status.process_id
				FROM process_status
				WHERE (process_status.dt BETWEEN ? AND addtime(?, '23:59:59'))
				AND process_status.status_id=28   
				GROUP BY process_status.process_id) AS ps ON process.id = ps.process_id		
		INNER JOIN process_link on process.id = process_link.process_id and process_link.object_type = "processDepend" 
		INNER JOIN process as process_depend on process_link.object_id = process_depend.id and process_depend.type_id = 112
		INNER JOIN process_executor on process_depend.id = process_executor.process_id and process_executor.role_id = 0		
		WHERE
		process.type_id IN (119,124)
		AND process.status_id IN (28,31)
		GROUP BY process.id, process.type_id
		
		UNION ALL
		
		SELECT 
		process.id as id,
		process.type_id as type_id,
		SUM(0) as count_executors,
		SUM(plc.cost) as cost,
		SUM(0) as cost_sks	
		FROM process
		INNER JOIN (SELECT
				process_status.process_id
				FROM process_status
				WHERE (process_status.dt BETWEEN ? AND addtime(?, '23:59:59'))
				AND process_status.status_id=28   
				GROUP BY process_status.process_id) AS ps ON process.id = ps.process_id		
		INNER JOIN param_list AS pl ON process.id = pl.id AND pl.param_id = 128    	
    	INNER JOIN (SELECT
				plc.process_id as process_id,
				plc.param_id as param_id,
				plc.id as id,
				param_list_costs.cost as cost
				FROM (SELECT	
					  process.id as process_id, 
					  plc.param_id as param_id,
					  plc.id as id,
					  MAX(plc.dt) as dt		
					  FROM process
					  INNER JOIN (SELECT
								  process_status.process_id,
								  MAX(process_status.dt) as dt
								  FROM process_status
								  WHERE (process_status.dt BETWEEN ? AND addtime(?, '23:59:59'))
								  AND process_status.status_id=28   
								  GROUP BY process_status.process_id) AS ps ON process.id = ps.process_id					  
					  INNER JOIN param_list_costs as plc ON ps.dt >=  plc.dt					  
					  WHERE process.type_id IN(119,124)
					  AND process.status_id IN (28,31)
					  GROUP BY process.id,plc.param_id,plc.id) as plc
				INNER JOIN param_list_costs ON plc.param_id = param_list_costs.param_id and plc.id = param_list_costs.id and plc.dt = param_list_costs.dt) as plc	
		ON pl.id = plc.process_id AND pl.param_id = plc.param_id AND pl.value = plc.id    	
		WHERE
		process.type_id IN (119,124) 
		AND process.status_id IN (28,31)
		GROUP BY process.id, process.type_id
		
		UNION ALL
		
		SELECT 
		process.id as id,
		process.type_id as type_id,
		SUM(0) as count_executors,
		SUM(0) as cost,
		SUM(plc.count) as cost_sks	
		FROM process
		INNER JOIN (SELECT
				process_status.process_id
				FROM process_status
				WHERE (process_status.dt BETWEEN ? AND addtime(?, '23:59:59'))
				AND process_status.status_id=28   
				GROUP BY process_status.process_id) AS ps ON process.id = ps.process_id 
		INNER JOIN param_listcount AS plc ON process.id = plc.id AND plc.param_id = 130		   	  
		WHERE
		process.type_id IN (119,124)
		AND process.status_id IN (28,31)
		GROUP BY process.id, process.type_id		
		) as process_itog 
	GROUP BY id,count_podk,count_moder
	) AS process
INNER JOIN (
	SELECT		 
		process.id as id,
		user.title	
		FROM process	
		INNER JOIN (SELECT
				process_status.process_id
				FROM process_status
				WHERE (process_status.dt BETWEEN ? AND addtime(?, '23:59:59'))
				AND process_status.status_id=28   
				GROUP BY process_status.process_id) AS ps ON process.id = ps.process_id
		INNER JOIN process_link on process.id = process_link.process_id and process_link.object_type = "processDepend" 
		INNER JOIN process as process_depend on process_link.object_id = process_depend.id and process_depend.type_id = 112
		INNER JOIN process_executor on process_depend.id = process_executor.process_id and process_executor.role_id = 0		
		INNER JOIN user on process_executor.user_id = user.id
		WHERE
		process.type_id IN (119,124) 
		AND process.status_id IN (28,31)
		GROUP BY process.id, user.title) as users ON process.id = users.id

GROUP BY users.title
    
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
			
	<table style="width: 100%;"class="data mt1">
	<tr>
	
	<td>ФИО Исполнителя</td>
	<td>Общее кол-во процессов подключения, в кот-х участвовал</td>
	<td>Общее кол-во процессов переезд/модернизация, в кот-х участвовал</td>
	<td>Общее кол-во процессов, в кот-х участвовал</td>
<%--<td>Общая сумма за выполненные клиентские заявки</td>
	<td>Кол-во исполнителей в процессах</td>--%>
	<td>Сумма за выполненные клиентские заявки на исполнителя</td>
<%--	<td>ID</td> --%>
	</tr>
		<c:forEach var="row" items="${result.rowsByIndex}">
			<tr>
				<td>${row[0]}</td>
				<td>${row[1]}</td>
				<td>${row[2]}</td>
				<td>${row[3]}</td>
				<td>${row[4]}</td>
			<%--<td>${row[5]}</td> 
				<td>${row[6]}</td> --%>
				<c:set var="ItogKlient5" value= "${ItogKlient5 + row[4]}"/>
				</tr>
				</c:forEach>
				<tr>
				<td>Итого</td>
				<td></td>
				<td></td>
				<td></td>
				<td>${ItogKlient5}</td>
				</tr>
				</table>
				</c:if>  
				
		<c:if test="${not empty fromdate}">
		
		<sql:query var="result" dataSource="${ctxSlaveDataSource}">
SELECT
users.title,
SUM(process.count_podk) as count_podk,
SUM(process.count_moder) as count_moder,
SUM(process.count_podk) + SUM(process.count_moder) as count_itog,
SUM(ROUND(process.cost / process.count_executors,2)) as cost_user,
GROUP_CONCAT(process.id SEPARATOR ', ')
FROM(
	SELECT 
	process_itog.id as id,
	CASE 
	 	WHEN process_itog.type_id = 119 THEN 1
	 	ElSE 0
	END as count_podk,
	CASE
	 	WHEN process_itog.type_id = 124 THEN 1
	 	ElSE 0
	END as count_moder,	
	SUM(process_itog.count_executors) as count_executors,
	SUM(process_itog.cost + process_itog.cost_sks) as cost	
	FROM(SELECT 
		process.id as id,
		process.type_id as type_id,
		COUNT(DISTINCT process_executor.user_id) AS count_executors,
		SUM(0) as cost,
		SUM(0) as cost_sks	
		FROM process	
		INNER JOIN (SELECT
				process_status.process_id
				FROM process_status
				WHERE (process_status.dt BETWEEN ? AND addtime(?, '23:59:59'))
				AND process_status.status_id=28   
				GROUP BY process_status.process_id) AS ps ON process.id = ps.process_id
		INNER JOIN process_executor on process.id = process_executor.process_id and process_executor.role_id = 0 and process_executor.group_id=11		
		WHERE
		process.type_id IN (119,124)
		AND process.status_id IN (28,31)
		GROUP BY process.id, process.type_id
		
		UNION ALL
		
		SELECT 
		process.id as id,
		process.type_id as type_id,
		SUM(0) as count_executors,
		SUM(plc.cost) as cost,
		SUM(0) as cost_sks	
		FROM process
		INNER JOIN (SELECT
				process_status.process_id
				FROM process_status
				WHERE (process_status.dt BETWEEN ? AND addtime(?, '23:59:59'))
				AND process_status.status_id=28   
				GROUP BY process_status.process_id) AS ps ON process.id = ps.process_id
		INNER JOIN param_list AS pl ON process.id = pl.id AND pl.param_id = 129    	
    	INNER JOIN (SELECT
				plc.process_id as process_id,
				plc.param_id as param_id,
				plc.id as id,
				param_list_costs.cost as cost
				FROM (SELECT	
					  process.id as process_id, 
					  plc.param_id as param_id,
					  plc.id as id,
					  MAX(plc.dt) as dt		
					  FROM process
					  INNER JOIN (SELECT
								  process_status.process_id,
								  MAX(process_status.dt) as dt
								  FROM process_status
								  WHERE (process_status.dt BETWEEN ? AND addtime(?, '23:59:59'))
								  AND process_status.status_id=28   
								  GROUP BY process_status.process_id) AS ps ON process.id = ps.process_id					  
					  INNER JOIN param_list_costs as plc ON ps.dt >=  plc.dt					  
					  WHERE process.type_id IN(119,124)
					  AND process.status_id IN (28,31)
					  GROUP BY process.id,plc.param_id,plc.id) as plc
				INNER JOIN param_list_costs ON plc.param_id = param_list_costs.param_id and plc.id = param_list_costs.id and plc.dt = param_list_costs.dt) as plc	
		ON pl.id = plc.process_id AND pl.param_id = plc.param_id AND pl.value = plc.id    	
		WHERE
		process.type_id IN (119,124)
		AND process.status_id IN (28,31)
		GROUP BY process.id, process.type_id
		
		UNION ALL
		
		SELECT 
		process.id as id,
		process.type_id as type_id,
		SUM(0) as count_executors,
		SUM(0) as cost,
		SUM(plc.count) as cost_sks	
		FROM process
		INNER JOIN (SELECT
				process_status.process_id
				FROM process_status
				WHERE (process_status.dt BETWEEN ? AND addtime(?, '23:59:59'))
				AND process_status.status_id=28   
				GROUP BY process_status.process_id) AS ps ON process.id = ps.process_id
		INNER JOIN param_listcount AS plc ON process.id = plc.id AND plc.param_id = 131		   	  
		WHERE
		process.type_id IN (119,124)
		AND process.status_id IN (28,31)
		GROUP BY process.id, process.type_id		
		) as process_itog 
	GROUP BY id,count_podk,count_moder
	) AS process
INNER JOIN (
	SELECT		 
		process.id as id,
		user.title	
		FROM process	
		INNER JOIN (SELECT
				process_status.process_id
				FROM process_status
				WHERE (process_status.dt BETWEEN ? AND addtime(?, '23:59:59'))
				AND process_status.status_id=28   
				GROUP BY process_status.process_id) AS ps ON process.id = ps.process_id
		INNER JOIN process_executor on process.id = process_executor.process_id and process_executor.role_id = 0 and process_executor.group_id=11		
		INNER JOIN user on process_executor.user_id = user.id
		WHERE
		process.type_id IN (119,124)
		AND process.status_id IN (28,31)
		GROUP BY process.id, user.title) as users ON process.id = users.id

GROUP BY users.title
    
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
			
	<table style="width: 100%;"class="data mt1">
	<tr>
	
	<td>ФИО Исполнителя</td>
	<td>Общее кол-во процессов подключения, в кот-х участвовал</td>
	<td>Общее кол-во процессов переезд/модернизация, в кот-х участвовал</td>
	<td>Общее кол-во процессов, в кот-х участвовал</td>
<%--<td>Общая сумма за выполненные клиентские заявки</td>
	<td>Кол-во исполнителей в процессах</td>--%>
	<td>Сумма за выполненные клиентские заявки на исполнителя</td>
<%--	<td>ID</td> --%>
	</tr>
		<c:forEach var="row" items="${result.rowsByIndex}">
			<tr>
				<td>${row[0]}</td>
				<td>${row[1]}</td>
				<td>${row[2]}</td>
				<td>${row[3]}</td>
				<td>${row[4]}</td>
			<%--	<td>${row[5]}</td> --%>
			<%--	<td>${row[6]}</td> --%>
			<c:set var="ItogKlient12" value= "${ItogKlient12 + row[4]}"/>
			</tr>
				</c:forEach>
				<tr>
				<td>Итого</td>
				<td></td>
				<td></td>
				<td></td>
				<td>${ItogKlient12}</td>
				</tr>
				
				</table>
				</c:if>  
				
				
	<c:if test="${not empty fromdate}">		
	<sql:query var="result" dataSource="${ctxSlaveDataSource}">
	
	SELECT 
	itog.title,
 	CASE 
		WHEN itog.param_id IN (128,129) THEN
			CASE
				WHEN itog.value IN (1,2,3,9) AND itog.value_fl_uf = 1 THEN "интернет ЮЛ (коды 501,502,503)"				
				WHEN itog.value=4 THEN "телефон ЮЛ (510)"
				WHEN itog.value IN (5,6) THEN "видео ЮЛ (520,521)"				
				WHEN itog.value IN (7,8,9) AND itog.value_fl_uf = 2 THEN "интернет ФЛ (530,531)"				
				WHEN itog.value=10 THEN "прочие услуги (550)"
			ELSE ""	
			END	
		WHEN itog.param_id IN (130,131)	THEN		
			CASE	
				WHEN itog.value=1 THEN "СКС (560)"
			ELSE ""	
			END
		ELSE ""		
	END AS itog_value,
	count(distinct itog.id),
	SUM(itog.cost128) + SUM(itog.cost129), 
	SUM(itog.cost129),
	SUM(itog.cost128),	
	GROUP_CONCAT(distinct itog.id SEPARATOR ', ')
	FROM 
	(SELECT 
	process.id as id,
	process_type.title as title,
	param_list.param_id as param_id,
	param_list.value as value,
	pl_fl_uf.value as value_fl_uf,
	SUM(CASE 
		WHEN param_list.param_id = 128 THEN plc.cost
	ELSE 0
	END) as cost128,	
	SUM(CASE 
		WHEN param_list.param_id = 129 THEN plc.cost
	ELSE 0
	END) as cost129	
	from process
	INNER JOIN (SELECT
				process_status.process_id
				FROM process_status
				WHERE (process_status.dt BETWEEN ? AND addtime(?, '23:59:59'))
				AND process_status.status_id=28   
				GROUP BY process_status.process_id) AS ps ON process.id = ps.process_id
	INNER JOIN process_type ON process.type_id = process_type.id
	INNER JOIN param_list AS param_list ON process.id = param_list.id AND param_list.param_id IN (128,129)
	INNER JOIN param_list AS pl_fl_uf ON process.id = pl_fl_uf.id AND pl_fl_uf.param_id IN (127)	
	INNER JOIN (SELECT
				plc.process_id as process_id,
				plc.param_id as param_id,
				plc.id as id,
				param_list_costs.cost as cost
				FROM (SELECT	
					  process.id as process_id, 
					  plc.param_id as param_id,
					  plc.id as id,
					  MAX(plc.dt) as dt		
					  FROM process
					  INNER JOIN (SELECT
								  process_status.process_id,
								  MAX(process_status.dt) as dt
								  FROM process_status
								  WHERE (process_status.dt BETWEEN ? AND addtime(?, '23:59:59'))
								  AND process_status.status_id=28   
								  GROUP BY process_status.process_id) AS ps ON process.id = ps.process_id					  
					  INNER JOIN param_list_costs as plc ON ps.dt >=  plc.dt					  
					  WHERE process.type_id IN(119)
					  AND process.status_id IN (28,31)
					  GROUP BY process.id,plc.param_id,plc.id) as plc
				INNER JOIN param_list_costs ON plc.param_id = param_list_costs.param_id and plc.id = param_list_costs.id and plc.dt = param_list_costs.dt) as plc	
	ON param_list.id = plc.process_id AND param_list.param_id = plc.param_id AND param_list.value = plc.id AND param_list.param_id  = plc.param_id
			
	WHERE process.type_id IN(119)
	AND process.status_id IN (28,31)
	GROUP BY title,id,param_id,value,value_fl_uf
	
	UNION ALL
	
	SELECT 
	process.id as id,
	process_type.title as title,
	param_listcount.param_id as param_id,
	param_listcount.value as value,
	pl_fl_uf.value as value_fl_uf,	
	SUM(CASE 
		WHEN param_listcount.param_id = 130 THEN param_listcount.count
	ELSE 0
	END) as cost128,
	SUM(CASE 
		WHEN param_listcount.param_id = 131 THEN param_listcount.count
	ELSE 0
	END) as cost129
	from process
	INNER JOIN (SELECT
				process_status.process_id
				FROM process_status
				WHERE (process_status.dt BETWEEN ? AND addtime(?, '23:59:59'))
				AND process_status.status_id=28   
				GROUP BY process_status.process_id) AS ps ON process.id = ps.process_id
	INNER JOIN process_type ON process.type_id = process_type.id
	INNER JOIN param_listcount AS param_listcount ON process.id = param_listcount.id AND param_listcount.param_id IN (130,131)
	INNER JOIN param_list AS pl_fl_uf ON process.id = pl_fl_uf.id AND pl_fl_uf.param_id IN (127)	
	WHERE process.type_id IN(119)
	AND process.status_id IN (28,31)
	GROUP BY title,id,param_id,value,value_fl_uf	
	
	) as itog
	
	GROUP BY itog.title,itog_value
	
	<sql:param value="${fromdate}"/>
	<sql:param value="${todate}"/>		
	<sql:param value="${fromdate}"/>
	<sql:param value="${todate}"/>
	<sql:param value="${fromdate}"/>
	<sql:param value="${todate}"/>
			
	</sql:query>	
	
		
	<table style="width: 100%"class="data mt1">
	<tr>
	<td>Тип заявки</td>
	<td>Тип услуги</td>
	<td>Кол-во клиентских заявок</td>
	<td>Общая сумма за выполненные клиентские заявки</td>
	<td>Общая сумма за проектные работы</td>
	<td>Общая сумма за монтажные работы</td>
<%--	<td>ID</td> --%>
	</tr>
		<c:forEach var="row" items="${result.rowsByIndex}">
			<tr   >
				<td>${row[0]}</td>
				<td>${row[1]}</td>
				<td>${row[2]}</td>
				<td>${row[3]}</td>
				<td>${row[4]}</td>
				<td>${row[5]}</td>
		<%--		<td>${row[6]}</td> --%>
				<c:set var="ItogKlient" value= "${ItogKlient + row[2]}"/>
				<c:set var="ItogKlient2" value= "${ItogKlient2 + row[3]}"/>	
				<c:set var="ItogKlient3" value= "${ItogKlient3 + row[4]}"/>
				<c:set var="ItogKlient4" value= "${ItogKlient4 + row[5]}"/>			
				</tr>
				</c:forEach>
				<tr>
				<td>Итого</td>
				<td></td>
				<td>${ItogKlient}</td>
				<td>${ItogKlient2}</td>
				<td>${ItogKlient3}</td>
				<td>${ItogKlient4}</td>
				
				</tr>
				</table>
				</c:if> 
				
				
	<c:if test="${not empty fromdate}">		
	<sql:query var="result" dataSource="${ctxSlaveDataSource}">
	
	SELECT 
	itog.title,
 	CASE 
		WHEN itog.param_id IN (128,129) THEN
			CASE
				WHEN itog.value IN (1,2,3,9) AND itog.value_fl_uf = 1 THEN "интернет ЮЛ (коды 501,502,503)"				
				WHEN itog.value=4 THEN "телефон ЮЛ (510)"
				WHEN itog.value IN (5,6) THEN "видео ЮЛ (520,521)"				
				WHEN itog.value IN (7,8,9)  AND itog.value_fl_uf = 2 THEN "интернет ФЛ (530,531)"				
				WHEN itog.value=10 THEN "прочие услуги (550)"
			ELSE ""	
			END	
		WHEN itog.param_id IN (130,131)	THEN		
			CASE	
				WHEN itog.value=1 THEN "СКС (560)"
			ELSE ""	
			END
		ELSE ""		
	END AS itog_value,
	count(distinct itog.id),
	SUM(itog.cost128) + SUM(itog.cost129), 
	SUM(itog.cost129),
	SUM(itog.cost128),	
	GROUP_CONCAT(distinct itog.id SEPARATOR ', ')
	FROM 
	(SELECT 
	process.id as id,
	process_type.title as title,
	param_list.param_id as param_id,
	param_list.value as value,
	pl_fl_uf.value as value_fl_uf,
	SUM(CASE 
		WHEN param_list.param_id = 128 THEN plc.cost
	ELSE 0
	END) as cost128,	
	SUM(CASE 
		WHEN param_list.param_id = 129 THEN plc.cost
	ELSE 0
	END) as cost129	
	from process
	INNER JOIN (SELECT
				process_status.process_id
				FROM process_status
				WHERE (process_status.dt BETWEEN ? AND addtime(?, '23:59:59'))
				AND process_status.status_id=28   
				GROUP BY process_status.process_id) AS ps ON process.id = ps.process_id
	INNER JOIN process_type ON process.type_id = process_type.id
	INNER JOIN param_list AS param_list ON process.id = param_list.id AND param_list.param_id IN (128,129)
	INNER JOIN param_list AS pl_fl_uf ON process.id = pl_fl_uf.id AND pl_fl_uf.param_id IN (127)	
	INNER JOIN (SELECT
				plc.process_id as process_id,
				plc.param_id as param_id,
				plc.id as id,
				param_list_costs.cost as cost
				FROM (SELECT	
					  process.id as process_id, 
					  plc.param_id as param_id,
					  plc.id as id,
					  MAX(plc.dt) as dt		
					  FROM process
					  INNER JOIN (SELECT
								  process_status.process_id,
								  MAX(process_status.dt) as dt
								  FROM process_status
								  WHERE (process_status.dt BETWEEN ? AND addtime(?, '23:59:59'))
								  AND process_status.status_id=28   
								  GROUP BY process_status.process_id) AS ps ON process.id = ps.process_id					  
					  INNER JOIN param_list_costs as plc ON ps.dt >=  plc.dt					  
					  WHERE process.type_id IN(124)
					  AND process.status_id IN (28,31)
					  GROUP BY process.id,plc.param_id,plc.id) as plc
				INNER JOIN param_list_costs ON plc.param_id = param_list_costs.param_id and plc.id = param_list_costs.id and plc.dt = param_list_costs.dt) as plc	
	ON param_list.id = plc.process_id AND param_list.param_id = plc.param_id AND param_list.value = plc.id AND param_list.param_id  = plc.param_id
			
	WHERE process.type_id IN(124)
	AND process.status_id IN (28,31)
	GROUP BY title,id,param_id,value,value_fl_uf
	
	UNION ALL
	
	SELECT 
	process.id as id,
	process_type.title as title,
	param_listcount.param_id as param_id,
	param_listcount.value as value,
	pl_fl_uf.value as value_fl_uf,	
	SUM(CASE 
		WHEN param_listcount.param_id = 130 THEN param_listcount.count
	ELSE 0
	END) as cost128,
	SUM(CASE 
		WHEN param_listcount.param_id = 131 THEN param_listcount.count
	ELSE 0
	END) as cost129
	from process
	INNER JOIN (SELECT
				process_status.process_id
				FROM process_status
				WHERE (process_status.dt BETWEEN ? AND addtime(?, '23:59:59'))
				AND process_status.status_id=28   
				GROUP BY process_status.process_id) AS ps ON process.id = ps.process_id
	INNER JOIN process_type ON process.type_id = process_type.id
	INNER JOIN param_listcount AS param_listcount ON process.id = param_listcount.id AND param_listcount.param_id IN (130,131)
	INNER JOIN param_list AS pl_fl_uf ON process.id = pl_fl_uf.id AND pl_fl_uf.param_id IN (127)	
	WHERE process.type_id IN(124)
	AND process.status_id IN (28,31)
	GROUP BY title,id,param_id,value,value_fl_uf	
	
	) as itog
	
	GROUP BY itog.title,itog_value
	
	<sql:param value="${fromdate}"/>
	<sql:param value="${todate}"/>		
	<sql:param value="${fromdate}"/>
	<sql:param value="${todate}"/>
	<sql:param value="${fromdate}"/>
	<sql:param value="${todate}"/>
			
	</sql:query>	
	
		
	<table style="width: 100%"class="data mt1">
	<tr>
	<td>Тип заявки</td>
	<td>Тип услуги</td>
	<td>Кол-во клиентских заявок</td>
	<td>Общая сумма за выполненные клиентские заявки</td>
	<td>Общая сумма за проектные работы</td>
	<td>Общая сумма за монтажные работы</td>
<%--	<td>ID</td> --%>
	</tr>
		<c:forEach var="row" items="${result.rowsByIndex}">
			<tr   >
				<td>${row[0]}</td>
				<td>${row[1]}</td>
				<td>${row[2]}</td>
				<td>${row[3]}</td>
				<td>${row[4]}</td>
				<td>${row[5]}</td>
		<%--		<td>${row[6]}</td> --%>
				<c:set var="ItogKlient1" value= "${ItogKlient1 + row[2]}"/>
				<c:set var="ItogKlient22" value= "${ItogKlient22 + row[3]}"/>	
				<c:set var="ItogKlient33" value= "${ItogKlient33 + row[4]}"/>
				<c:set var="ItogKlient44" value= "${ItogKlient44 + row[5]}"/>			
				</tr>
				</c:forEach>
				<tr>
				<td>Итого</td>
				<td></td>
				<td>${ItogKlient1}</td>
				<td>${ItogKlient22}</td>
				<td>${ItogKlient33}</td>
				<td>${ItogKlient44}</td>
				
				</tr>
				</table>
				</c:if> 
				
				<c:if test="${not empty fromdate}">		
	<sql:query var="result" dataSource="${ctxSlaveDataSource}">
		
	select 
	process_type.title,
			CASE
				WHEN param_list3.value IN (1,2,12,13) AND pl_fl_uf.value = 1 THEN "Интернет ЮЛ"				
				WHEN param_list3.value IN (6,7)  THEN "Телефон ЮЛ"  
				WHEN param_list3.value IN (4) THEN "Видео ЮЛ"				
				WHEN param_list3.value IN (1,2,3) AND pl_fl_uf.value = 2 THEN "Интернет ФЛ"				
				WHEN param_list3.value IN (8,14) THEN "Прочие услуги"
				WHEN param_list3.value IN (10) THEN "СКС"
			ELSE ""	
			END AS itog_value,
	count(process.id),
	GROUP_CONCAT(distinct process.id SEPARATOR ', ')
	from process
	INNER JOIN (SELECT
				process_status.process_id
				FROM process_status
				WHERE (process_status.dt BETWEEN ? AND addtime(?, '23:59:59'))
				AND process_status.status_id=28   
				GROUP BY process_status.process_id) AS ps ON process.id = ps.process_id
	LEFT JOIN param_list AS param_list3 ON process.id = param_list3.id AND param_list3.param_id = 123
	INNER JOIN process_type ON process.type_id = process_type.id
	INNER JOIN param_list AS pl_fl_uf ON process.id = pl_fl_uf.id AND pl_fl_uf.param_id IN (127)
	WHERE process.type_id IN(119)
	AND process.status_id IN (28,31)
	GROUP BY itog_value
	<sql:param value="${fromdate}"/>
	<sql:param value="${todate}"/>
	
	</sql:query>
	
	
		
	<table style="width: 100%"class="data mt1">
	<tr>
	<td>Тип процесса</td>
	<td>Услуга</td>
	<td>Кол-во процессов</td>
	

	</tr>
		<c:forEach var="row" items="${result.rowsByIndex}">
			<tr>
			<td>${row[0]}</td>
			<td>${row[1]}</td>
			<td>${row[2]}</td>
			
			<c:set var="ItogKlient01" value= "${ItogKlient01 + row[2]}"/>
			</tr>
				</c:forEach>
				<tr>
				<td>Итого</td>
				<td></td>
				<td>${ItogKlient01}</td>
				
				</tr>
				</table>
				</c:if> 
				
	<c:if test="${not empty fromdate}">		
	<sql:query var="result" dataSource="${ctxSlaveDataSource}">
		
	select 
	process_type.title,
			CASE
				WHEN param_list3.value IN (1,2,12,13) AND pl_fl_uf.value = 1 THEN "Интернет ЮЛ"				
				WHEN param_list3.value IN (6,7)  THEN "Телефон ЮЛ"  
				WHEN param_list3.value IN (4) THEN "Видео ЮЛ"				
				WHEN param_list3.value IN (1,2,3) AND pl_fl_uf.value = 2 THEN "Интернет ФЛ"				
				WHEN param_list3.value IN (8,14) THEN "Прочие услуги"
				WHEN param_list3.value IN (10) THEN "СКС"
			ELSE ""	
			END AS itog_value,
	count(process.id),
	GROUP_CONCAT(distinct process.id SEPARATOR ', ')
	from process
	INNER JOIN (SELECT
				process_status.process_id
				FROM process_status
				WHERE (process_status.dt BETWEEN ? AND addtime(?, '23:59:59'))
				AND process_status.status_id=28   
				GROUP BY process_status.process_id) AS ps ON process.id = ps.process_id
	LEFT JOIN param_list AS param_list3 ON process.id = param_list3.id AND param_list3.param_id = 123
	INNER JOIN process_type ON process.type_id = process_type.id
	INNER JOIN param_list AS pl_fl_uf ON process.id = pl_fl_uf.id AND pl_fl_uf.param_id IN (127)
	WHERE process.type_id IN(124)
	AND process.status_id IN (28,31)
	GROUP BY itog_value
	<sql:param value="${fromdate}"/>
	<sql:param value="${todate}"/>
	
	</sql:query>
	
	
		
	<table style="width: 100%"class="data mt1">
	<tr>
	<td>Тип процесса</td>
	<td>Услуга</td>
	<td>Кол-во процессов</td>
	

	</tr>
		<c:forEach var="row" items="${result.rowsByIndex}">
			<tr>
			<td>${row[0]}</td>
			<td>${row[1]}</td>
			<td>${row[2]}</td>
			
			<c:set var="ItogKlient02" value= "${ItogKlient02 + row[2]}"/>
			</tr>
				</c:forEach>
				<tr>
				<td>Итого</td>
				<td></td>
				<td>${ItogKlient02}</td>
				
				</tr>
				</table>
				</c:if> 

</div>