<%@ page import="java.util.Enumeration"%>

<%@ page contentType="text/html; charset=UTF-8"%>
<%@ include file="/WEB-INF/jspf/taglibs.jsp"%>

<div class="center1020">
	<h2>ОСС - Отчет по работе отдела</h2>
	<br/>
	
	<%--В таблице "Системное сопровождение" Итого считаться не будет, все выводы по клиентам это разные сущности.--%>

	
	<%--
    Переменная form - объект класса ru.bgcrm.struts.form.DynActionForm, содержащий параметры запроса.
    --%>
    <c:set var="fromdate" value="${u:parseDate( form.param.fromdate, 'ymd' ) }"/>
    <c:set var="todate" value="${u:parseDate( form.param.todate, 'ymd' ) }"/>
	<c:set var="processTypeIds" value="${form.getSelectedValues('type')}" scope="request"/>
	
	<html:form action="/user/empty">
		<input type="hidden" name="forwardFile" value="/WEB-INF/jspf/user/plugin/custom.smartkom/report/old/custom_ossitogo_report.jsp"/>
		
		
		Начало периода:
		<ui:date-time paramName="fromdate" value="first"/>
		
		Окончание периода:
		<ui:date-time paramName="todate" value="last"/>
		
			
		<br/>
		
		Типы:
		<p>"${ctxProcessTypeTreeRoot.children}"</p>
		<c:set var="treeId" value="${u:uiid()}"/>
		<ul id="${treeId}" style="display: block; height: 300px; overflow: auto;">
			<c:forEach var="node" items="${ctxProcessTypeTreeRoot.children}">
				<c:set var="node" value="${node}" scope="request"/>
				<jsp:include page="/WEB-INF/jspf/admin/process/process_type_check_tree_item.jsp"/>
			</c:forEach>
		</ul>
		
		<script>
			$( function() 
			{
				$("#${treeId}").Tree();
			} );															
		</script>
		
		<button type="button"  class="btn-grey ml1 mt05" onclick="openUrlToParent( formUrl( this.form ), $(this.form) )">Сформировать</button>
	</html:form>
	
	
	<%--
	Генерация отчёта, если в запросе пришёл параметр date.	
	--%>		
	<c:if test="${not empty fromdate}">
		<%-- в случае, если Slave база не настроена - будет использована обычная --%>
		<sql:query var="result" dataSource="${ctxSlaveDataSource}">
			SELECT COUNT(p.id), NULL, SUM(transp.value)
			FROM process AS p
			LEFT JOIN param_text AS transp ON p.id = transp.id AND transp.param_id = 94
			WHERE p.close_dt BETWEEN ? AND addtime(?, '23:59:59')
			AND p.type_id = 55
 						
			
			<sql:param value="${fromdate}"/>		
			<sql:param value="${todate}"/>	
			
		</sql:query>



		
		<table style="width: 100%;" class="data mt1">
			<tr>
				<td colspan="5" height="40"><center>Аудит сети клиентов (служит целью привлечения клиентов)</center></td>
			</tr>
		
			<tr>
				<td bgcolor=#E6E6FA>Количество заявок</td>
				<td bgcolor=#E6E6FA>Заключенных договоров</td>	
				<td bgcolor=#E6E6FA>Транспортные расходы</td>	
			</tr>	


			<c:forEach var="row" items="${result.rowsByIndex}">
				<c:set var="process" value="${row[0]}"/>
				<c:set var="nothing" value="${row[1]}"/>
				<c:set var="transport" value="${row[2]}"/>
						
				<tr>
					<td>${process}</td>	
					<td>${nothing}</td>
					<td>${transport}</td>
				</tr>			
			</c:forEach>
		</table>	
	</c:if>
	
		<c:if test="${not empty fromdate}">
		<%-- в случае, если Slave база не настроена - будет использована обычная --%>
		<sql:query var="result" dataSource="${ctxSlaveDataSource}">
			SELECT COUNT(p.id), SUM(summa.value), SUM(oplata.value), 
			SUM(summa.value)-SUM(oplata.value) as loyalvalue,
			SUM(transp.value)
			FROM process AS p
			LEFT JOIN param_text AS summa ON p.id = summa.id AND summa.param_id = 92
			LEFT JOIN param_text AS oplata ON p.id = oplata.id AND oplata.param_id = 93
			LEFT JOIN param_text AS transp ON p.id = transp.id AND transp.param_id = 94
			WHERE p.close_dt BETWEEN ? AND addtime(?, '23:59:59')
			AND p.type_id = 58
			  		 
 						
			<sql:param value="${fromdate}"/>		
			<sql:param value="${todate}"/>
			
			
		</sql:query>



		
		<table style="width: 100%;" class="data mt1">
			<tr>
				<td colspan="5" height="40"><center>Разовый аутсорс</center></td>
			</tr>
		
			<tr>
				<td bgcolor=#E6E6FA>Количество заявок</td>
				<td bgcolor=#E6E6FA>Стоимость работ</td>
				<td bgcolor=#E6E6FA>Выставлено счетов</td>	
				<td bgcolor=#E6E6FA>Оказано аутсорсов в рамках "лояльности к клиенту"</td>	
				<td bgcolor=#E6E6FA>Транспортные расходы</td>			
			</tr>	


			<c:forEach var="row" items="${result.rowsByIndex}">
				<c:set var="all_pr" value="${row[0]}"/>
				<c:set var="summa" value="${row[1]}"/>
				<c:set var="oplata" value="${row[2]}"/>
				<c:set var="loyality" value="${row[3]}"/>
				<c:set var="transport" value="${row[4]}"/>
						
				<tr>
					<td>${all_pr}</td>	
					<td>${summa}</td>
					<td>${oplata}</td>
					<td>${loyality}</td>
					<td>${transport}</td>
				</tr>			
			</c:forEach>
		</table>	
	</c:if>
	
	

	  <c:if test="${not empty fromdate}">
		<%-- в случае, если Slave база не настроена - будет использована обычная --%>
		<sql:query var="result" dataSource="${ctxSlaveDataSource}">


SELECT
Dannie.title,
Dannie.CountID,
Dannie.summa,
CASE Dannie.oplata WHEN 0 THEN "Нет" ELSE Dannie.oplata END AS oplata,
Dannie.transp
FROM 
(SELECT
'ФГБОУ ВО ОмГМУ Минздрава России' AS title,
COUNT(p.id) AS CountID,
20900 AS SUMMA,
SUM(CAST(oplata.value AS decimal(15,2))) AS oplata,
SUM(transp.value) AS transp
FROM process AS p
LEFT JOIN process_link ON p.id = process_link.process_id AND process_link.object_type = "customer"
LEFT JOIN customer ON process_link.object_id = customer.id
LEFT JOIN param_text AS summa ON p.id = summa.id AND summa.param_id = 92
LEFT JOIN param_text AS oplata ON p.id = oplata.id AND oplata.param_id = 93
LEFT JOIN param_text AS transp ON p.id = transp.id AND transp.param_id = 94
WHERE p.close_dt BETWEEN ? AND addtime(?, '23:59:59')
AND p.type_id = 53 AND customer.id = 1177


UNION ALL

SELECT
'ИП Кушнаренко Валерий Вячеславович' AS title,
COUNT(p.id) AS CountID,
1500,
SUM(CAST(oplata.value AS decimal(15,2))) AS oplata,
SUM(transp.value) AS transp
FROM process AS p
LEFT JOIN process_link ON p.id = process_link.process_id AND process_link.object_type = "customer"
LEFT JOIN customer ON process_link.object_id = customer.id
LEFT JOIN param_text AS summa ON p.id = summa.id AND summa.param_id = 92
LEFT JOIN param_text AS oplata ON p.id = oplata.id AND oplata.param_id = 93
LEFT JOIN param_text AS transp ON p.id = transp.id AND transp.param_id = 94
WHERE p.close_dt BETWEEN ? AND addtime(?, '23:59:59')
AND p.type_id = 53 AND customer.id = 896


UNION ALL

SELECT
'Омский региональный фонд поддержки и развития малого предпринимательства' AS title,
COUNT(p.id) AS CountID,
5600,
SUM(CAST(oplata.value AS decimal(15,2))) AS oplata,
SUM(transp.value) AS transp
FROM process AS p
LEFT JOIN process_link ON p.id = process_link.process_id AND process_link.object_type = "customer"
LEFT JOIN customer ON process_link.object_id = customer.id
LEFT JOIN param_text AS summa ON p.id = summa.id AND summa.param_id = 92
LEFT JOIN param_text AS oplata ON p.id = oplata.id AND oplata.param_id = 93
LEFT JOIN param_text AS transp ON p.id = transp.id AND transp.param_id = 94
WHERE p.close_dt BETWEEN ? AND addtime(?, '23:59:59')
AND p.type_id = 53 AND customer.id = 1216

UNION ALL

SELECT
'ИП Чащин Юрий Евгеньевич' AS title,
COUNT(p.id) AS CountID,
3500,
SUM(CAST(oplata.value AS decimal(15,2))) AS oplata,
SUM(transp.value) AS transp
FROM process AS p
LEFT JOIN process_link ON p.id = process_link.process_id AND process_link.object_type = "customer"
LEFT JOIN customer ON process_link.object_id = customer.id
LEFT JOIN param_text AS summa ON p.id = summa.id AND summa.param_id = 92
LEFT JOIN param_text AS oplata ON p.id = oplata.id AND oplata.param_id = 93
LEFT JOIN param_text AS transp ON p.id = transp.id AND transp.param_id = 94
WHERE p.close_dt BETWEEN ? AND addtime(?, '23:59:59')
AND p.type_id = 53 AND customer.id = 1930


UNION ALL

SELECT
'ООО "Флагман-Сервис"' AS title,
COUNT(p.id) AS CountID,
1000,
SUM(CAST(oplata.value AS decimal(15,2))) AS oplata,
SUM(transp.value) AS transp
FROM process AS p
LEFT JOIN process_link ON p.id = process_link.process_id AND process_link.object_type = "customer"
LEFT JOIN customer ON process_link.object_id = customer.id
LEFT JOIN param_text AS summa ON p.id = summa.id AND summa.param_id = 92
LEFT JOIN param_text AS oplata ON p.id = oplata.id AND oplata.param_id = 93
LEFT JOIN param_text AS transp ON p.id = transp.id AND transp.param_id = 94
WHERE p.close_dt BETWEEN ? AND addtime(?, '23:59:59')
AND p.type_id = 53 AND customer.id = 3190

<%--UNION ALL

SELECT
'ИП Лысенок Людмила Степановна' AS title,
COUNT(p.id) AS CountID,
2300,
SUM(CAST(oplata.value AS decimal(15,2))) AS oplata,
SUM(transp.value) AS transp
FROM process AS p
LEFT JOIN process_link ON p.id = process_link.process_id AND process_link.object_type = "customer"
LEFT JOIN customer ON process_link.object_id = customer.id
LEFT JOIN param_text AS summa ON p.id = summa.id AND summa.param_id = 92
LEFT JOIN param_text AS oplata ON p.id = oplata.id AND oplata.param_id = 93
LEFT JOIN param_text AS transp ON p.id = transp.id AND transp.param_id = 94
WHERE p.close_dt BETWEEN ? AND addtime(?, '23:59:59')
AND p.type_id = 53 AND customer.id = 952

UNION ALL

SELECT
'ООО "КРАСАВЧИК"' AS title,
COUNT(p.id) AS CountID,
3000,
SUM(CAST(oplata.value AS decimal(15,2))) AS oplata,
SUM(transp.value) AS transp
FROM process AS p
LEFT JOIN process_link ON p.id = process_link.process_id AND process_link.object_type = "customer"
LEFT JOIN customer ON process_link.object_id = customer.id
LEFT JOIN param_text AS summa ON p.id = summa.id AND summa.param_id = 92
LEFT JOIN param_text AS oplata ON p.id = oplata.id AND oplata.param_id = 93
LEFT JOIN param_text AS transp ON p.id = transp.id AND transp.param_id = 94
WHERE p.close_dt BETWEEN ? AND addtime(?, '23:59:59')
AND p.type_id = 53 AND customer.id = 3463--%>

UNION ALL

SELECT
'ИП Коган Сергей Алексеевич' AS title,
COUNT(p.id) AS CountID,
1500,
SUM(CAST(oplata.value AS decimal(15,2))) AS oplata,
SUM(transp.value) AS transp
FROM process AS p
LEFT JOIN process_link ON p.id = process_link.process_id AND process_link.object_type = "customer"
LEFT JOIN customer ON process_link.object_id = customer.id
LEFT JOIN param_text AS summa ON p.id = summa.id AND summa.param_id = 92
LEFT JOIN param_text AS oplata ON p.id = oplata.id AND oplata.param_id = 93
LEFT JOIN param_text AS transp ON p.id = transp.id AND transp.param_id = 94
WHERE p.close_dt BETWEEN ? AND addtime(?, '23:59:59')
AND p.type_id = 53 AND customer.id = 795



UNION ALL

SELECT
'ЗАО Смартком' AS title,
COUNT(p.id),
80000,
0,
SUM(transp.value) AS transp
FROM process AS p
<%-- LEFT JOIN process_link ON p.id = process_link.process_id AND process_link.object_type = "customer" 
LEFT JOIN customer ON process_link.object_id = customer.id--%>
LEFT JOIN param_text AS transp ON p.id = transp.id AND transp.param_id = 94
WHERE p.close_dt BETWEEN ? AND addtime(?, '23:59:59')
AND p.type_id = 54) AS Dannie


			  		 
 						
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

		
		<table style="width: 100%;" class="data mt1">
			<tr>
				<td colspan="6" height="40"><center>Системное сопровождение</center></td>
			</tr>
		
			<tr>
				<td bgcolor=#E6E6FA width="300">Клиент</td>
				<td bgcolor=#E6E6FA width="200">Количество заявок</td>
				<td bgcolor=#E6E6FA width="200">Абонентская плата (руб)</td>
				<td bgcolor=#E6E6FA width="200">Дополнительные (руб)</td>	
				<td bgcolor=#E6E6FA>Транспортные расходы</td>
				
			</tr>	


			<c:forEach var="row" items="${result.rowsByIndex}">
				<c:set var="sum_pr" value="${row[0]}"/>
				<c:set var="summa" value="${row[1]}"/>
				<c:set var="nothing1" value="${row[2]}"/>
				<c:set var="dop" value="${row[3]}"/>
				<c:set var="transport" value="${row[4]}"/>
				
	
	
						
				<tr>
					<td bgcolor=#F5F5F5>${sum_pr}</td>	
					<td>${summa}</td>
					<td>${nothing1}</td>
					<td>${dop}</td>
					<td>${transport}</td>
					
					
				</tr>	
				
						
			</c:forEach>
		</table>	
	</c:if>
	
	
 
<%-- 	<table style="width: 100%;" class="data mt1">
		
		
			<tr style='display:none;'>
				<td  width="300" height="0"></td>
				<td  width="200"></td>
				<td  width="200"></td>
					
			</tr>	


			
					<td bgcolor=#F5F5F5 width="530">Итого</td>	
					<td width="200"></td>
					<td width="200"></td>
					
				</tr>			

				
			
		</table>	
		
		<table style="width: 100%;" class="data mt1">
			<tr>
				<td colspan="5" height="40"><center>Общий итог</center></td>
			</tr>
			
			<tr>
					<td bgcolor=#F5F5F5 width="200">Сумма:</td>	
					<td width="450"></td>	
					
			</tr>		
		
			

				
			
		</table>	
	--%>
	  <%--
	Генерация отчёта, если в запросе пришёл параметр date.	
	--%>		
	<c:if test="${not empty fromdate}">
		<%-- в случае, если Slave база не настроена - будет использована обычная --%>
		<sql:query var="result" dataSource="${ctxSlaveDataSource}">
	
	
	
		 	SELECT "Довлатов Дмитрий" AS title,
			COUNT(DISTINCT p.id), GROUP_CONCAT(p.id SEPARATOR ',  ')

			FROM process AS p
			JOIN process_group AS pg ON p.id = pg.process_id 
			JOIN process_status AS ps ON p.id=ps.process_id 
			JOIN process_executor AS pe ON p.id=pe.process_id 
			WHERE ps.dt BETWEEN ? AND ?
			AND p.type_id IN(51,55,54,58,53)
	 		AND pg.role_id = 0
	 		AND pe.role_id = 0
	 		AND pe.user_id = 169
			AND ps.status_id = 5
			
			UNION ALL
			
		    SELECT "Коденёв Сергей" AS title,
			COUNT(DISTINCT p.id), GROUP_CONCAT(p.id SEPARATOR ',  ')
			
			FROM process AS p
			JOIN process_group AS pg ON p.id = pg.process_id 
			JOIN process_status AS ps ON p.id=ps.process_id 
			JOIN process_executor AS pe ON p.id=pe.process_id 
			WHERE ps.dt BETWEEN ? AND ?
			AND p.type_id IN(51,55,54,58,53)
	 		AND pg.role_id = 0
	 		AND pe.role_id = 0
	 		AND pe.user_id = 124
			AND ps.status_id = 5
			
			UNION ALL 
			
			SELECT "Кучерявенко Илья" AS title,
			COUNT(DISTINCT p.id), GROUP_CONCAT(p.id SEPARATOR ',  ')
			
			FROM process AS p
			JOIN process_group AS pg ON p.id = pg.process_id 
			JOIN process_status AS ps ON p.id=ps.process_id 
			JOIN process_executor AS pe ON p.id=pe.process_id 
			WHERE ps.dt BETWEEN ? AND ?
			AND p.type_id IN(51,55,54,58,53)
	 		AND pg.role_id = 0
	 		AND pe.role_id = 0
	 		AND pe.user_id = 84
			AND ps.status_id = 5
			
			UNION ALL 
			
			SELECT "Заволнуев Константин" AS title,
			COUNT(DISTINCT p.id), GROUP_CONCAT(p.id SEPARATOR ',  ')
			
			FROM process AS p
			JOIN process_group AS pg ON p.id = pg.process_id 
			JOIN process_status AS ps ON p.id=ps.process_id 
			JOIN process_executor AS pe ON p.id=pe.process_id 
			WHERE ps.dt BETWEEN ? AND ?
			AND p.type_id IN(51,55,54,58,53)
	 		AND pg.role_id = 0
	 		AND pe.role_id = 0
	 		AND pe.user_id = 130
			AND ps.status_id = 5
			
 						
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
				<td bgcolor=#E6E6FA width="300">Сотрудник</td>
				<td bgcolor=#E6E6FA width="200">Выполнено заявок</td>
				<td bgcolor=#E6E6FA width="200">Номера заявок</td>
				
			</tr>	


			<c:forEach var="row" items="${result.rowsByIndex}">
				<c:set var="sum_pr" value="${row[0]}"/>
				<c:set var="summa" value="${row[1]}"/>
				<c:set var="id" value="${row[2]}"/>
	
				
	
	
						
				<tr>
					<td bgcolor=#F5F5F5>${sum_pr}</td>	
					<td>${summa}</td>
					<%-- <td><a href="UNDEF" onclick="openProcess( ${id} ); return false;">${id}</a></td> --%>
					<td>${id}</td>
		
				</tr>	
				
						
			</c:forEach>
		</table>	
	</c:if>
	
	<%--
	Генерация отчёта, если в запросе пришёл параметр date.	
	--%>		
	<c:if test="${not empty fromdate}">
	    
		<%-- в случае, если Slave база не настроена - будет использована обычная --%>
		<sql:query var="result" dataSource="${ctxSlaveDataSource}">
			SELECT  process.id, 
			customer.title, 
			DATE_FORMAT(process.create_dt, '%Y-%m-%d %H.%i.%s'), 
			<%--DATE_FORMAT(prstat.dt, '%Y-%m-%d %H.%i.%s'), --%>	
			DATE_FORMAT(process.status_dt, '%Y-%m-%d %H.%i.%s'),
			GROUP_CONCAT(user.title SEPARATOR ', '), 
			hours.value, 
			summa.value,
			oplata.value,
			summa.value-oplata.value as loyalvalue,
			transp.value
			<%--COUNT(prlink.object_id)--%>
		FROM process
		LEFT JOIN process_type ON process.type_id = process_type.id 
		<%--LEFT JOIN process_status AS prstat ON process.id = prstat.process_id AND prstat.status_id = 2--%>	
		LEFT JOIN process_executor ON process.id = process_executor.process_id AND process_executor.role_id = 1
		LEFT JOIN user ON process_executor.user_id = user.id
		<%-- LEFT JOIN message AS zadmes ON process.id = zadmes.process_id AND zadmes.type_id = 7
		LEFT JOIN message AS rezmes ON process.id = rezmes.process_id AND rezmes.type_id = 8--%>
		LEFT JOIN param_blob AS opis ON process.id = opis.id AND opis.param_id = 72
		LEFT JOIN param_text AS hours ON process.id = hours.id AND hours.param_id = 81
		LEFT JOIN param_text AS summa ON process.id = summa.id AND summa.param_id = 92
		LEFT JOIN param_text AS oplata ON process.id = oplata.id AND oplata.param_id = 93
		LEFT JOIN param_text AS transp ON process.id = transp.id AND transp.param_id = 94
		LEFT JOIN process_link AS prlink ON process.id = prlink.process_id AND prlink.object_type = "processDepend"
		LEFT JOIN process_link ON process.id = process_link.process_id AND process_link.object_type = "customer"
		LEFT JOIN customer ON process_link.object_id = customer.id
			<%--WHERE process.status_dt BETWEEN ? AND ?--%>
			WHERE process.close_dt BETWEEN ? AND addtime(?, '23:59:59')
			AND process.status_id IN (5,6)
			<c:if test="${not empty processTypeIds}">
                 AND process.type_id IN (${u:toString(processTypeIds)})
            </c:if>
       
            GROUP BY process.id
            ORDER BY user.title
						
			<sql:param value="${fromdate}"/>		
			<sql:param value="${todate}"/>
		</sql:query>
		
		<table style="width: 100%;" class="data mt1">
			<tr>
				<td>ID</td>
				<td>Контрагент</td>
				<td>Дата создания</td>
			<%--	<td>Дата принятия в исполнение</td>--%>
				<td>Дата выполнения</td>
				<td>Куратор</td>
				<td>Кол-во отработанных часов</td>
				<td>Стоимость услуг</td>
				<td>Выставлено счетов</td>
				<td>Оказано аутсорсов в рамках «лояльности к клиенту»</td>
				<td>Транспортные расходы</td>
			<%--	<td>Кол-во связанных процессов</td>--%>
				
			</tr>	

			<c:forEach var="row" items="${result.rowsByIndex}">
				<c:set var="id" value="${row[0]}"/>
				<c:set var="customer" value="${row[1]}"/>
				<c:set var="createTime" value="${row[2]}"/>
			<%--	<c:set var="adaptDate" value="${row[3]}"/>--%>
				<c:set var="complDate" value="${row[3]}"/>
				<c:set var="exec" value="${row[4]}"/>
				<c:set var="hours" value="${row[5]}"/>
				<c:set var="summa" value="${row[6]}"/>
				<c:set var="oplata" value="${row[7]}"/>
				<c:set var="loyal" value="${row[8]}"/>
				<c:set var="transp" value="${row[9]}"/>
		<%--		<c:set var="link" value="${row[9]}"/>--%>
				
		
				<tr>
					<td><a href="UNDEF" onclick="openProcess( ${id} ); return false;">${id}</a></td>
					<td>${customer}</td>
					<td>${createTime}</td>
				<%--	<td>${adaptDate}</td>--%>
					<td>${complDate}</td>
					<td>${exec}</td>
					<td>${hours}</td>
					<td>${summa}</td>
					<td>${oplata}</td>
					<td>${loyal}</td>
					<td>${transp}</td>
			<%--		<td>${link}</td>--%>
					
				</tr>			
			</c:forEach>
		</table>	
	</c:if>
	
	
</div>