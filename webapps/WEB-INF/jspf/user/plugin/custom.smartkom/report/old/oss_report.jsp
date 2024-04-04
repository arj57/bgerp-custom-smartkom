<%@ page import="java.util.Enumeration"%>

<%@ page contentType="text/html; charset=UTF-8"%>
<%@ include file="/WEB-INF/jspf/taglibs.jsp"%>

<div class="center1020">
	<h2>ОСС - Отчет по кол-ву выполненных процессов Разового аутсорса/аудита</h2>
	<%--
	    Переменная form - объект класса ru.bgcrm.struts.form.DynActionForm, содержащий параметры запроса.
	--%>
	<c:set var="fromdate" value="${tu.parse( form.param.fromdate, 'ymd' ) }"/>
	<c:set var="todate" value="${tu.parse( form.param.todate, 'ymd' ) }"/>
	<c:set var="processTypeIds" value="${form.getSelectedValues('type')}" scope="request"/>
	
	
	<html:form action="/user/empty">
		<input type="hidden" name="forwardFile" value="/WEB-INF/custom/plugin/report/oss_report.jsp"/>
		
		Начало периода:
		<ui:date-time paramName="fromdate" value="first"/>
		
		Окончание периода:
		<ui:date-time paramName="todate" value="last"/>
		
		<br/>
	
		Типы:
		<c:set var="treeId" value="${u:uiid()}"/>
		<ul id="${treeId}" style="display: block; height: 300px; overflow: auto;">
			<c:forEach var="node" items="${ctxProcessTypeTreeRoot.childs}">
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
		
		<button type="button"  class="btn-grey ml1 mt05" onclick="$$.ajax.load(this, $(this.form).parent())">Сформировать</button>
	</html:form>
	
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
				<td>Выставлено клиенту</td>
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
				<c:set var="transp" value="${row[8]}"/>
		<%--		<c:set var="link" value="${row[9]}"/>--%>
				
		
				<tr>
					<td><a href="UNDEF" onclick="$$.process.open( ${id} ); return false;">${id}</a></td>
					<td>${customer}</td>
					<td>${createTime}</td>
				<%--	<td>${adaptDate}</td>--%>
					<td>${complDate}</td>
					<td>${exec}</td>
					<td>${hours}</td>
					<td>${summa}</td>
					<td>${oplata}</td>
					<td>${transp}</td>
			<%--		<td>${link}</td>--%>
					
				</tr>			
			</c:forEach>
		</table>	
	</c:if>
	
	
	    
</div>