<%@ page import="java.util.Enumeration"%>

<%@ page contentType="text/html; charset=UTF-8"%>
<%@ include file="/WEB-INF/jspf/taglibs.jsp"%>

<div class="center1020">
	<h2>ОТР - Отчет выполненных работ</h2>
	<%--
	    Переменная form - объект класса ru.bgcrm.struts.form.DynActionForm, содержащий параметры запроса.
	--%>
	<c:set var="fromdate" value="${tu.parse( form.param.fromdate, 'ymd' ) }"/>
	<c:set var="todate" value="${tu.parse( form.param.todate, 'ymd' ) }"/>
	<c:set var="processTypeIds" value="${form.getSelectedValues('type')}" scope="request"/>
	
	
	<html:form action="/user/empty">
		<input type="hidden" name="forwardFile" value="/WEB-INF/jspf/user/plugin/custom.smartkom/report/old/custom_compl_otr_report.jsp"/>
		
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
			DATE_FORMAT(process.create_dt, '%Y-%m-%d %H.%i.%s'), 
			DATE_FORMAT(prstat.dt, '%Y-%m-%d %H.%i.%s'), 
			DATE_FORMAT(process.status_dt, '%Y-%m-%d %H.%i.%s'),
			GROUP_CONCAT(DISTINCT user.title SEPARATOR ', '), 
			zad.value, 
			process.description,
			rez.value,
			process_type.title
		FROM process
		LEFT JOIN process_type ON process.type_id = process_type.id 
		LEFT JOIN process_status AS prstat ON process.id = prstat.process_id AND prstat.status_id = 2
		LEFT JOIN process_executor ON process.id = process_executor.process_id AND process_executor.role_id = 0
		LEFT JOIN user ON process_executor.user_id = user.id
		<%-- LEFT JOIN message AS zadmes ON process.id = zadmes.process_id AND zadmes.type_id = 7
		LEFT JOIN message AS rezmes ON process.id = rezmes.process_id AND rezmes.type_id = 8--%>
		<%-- LEFT JOIN param_blob AS opis ON process.id = opis.id AND opis.param_id = 72--%>
		LEFT JOIN param_blob AS zad ON process.id = zad.id AND zad.param_id = 73
		LEFT JOIN param_blob AS rez ON process.id = rez.id AND rez.param_id = 74
			WHERE process.status_dt BETWEEN ? AND ?
			AND process.status_id IN (5,6)
			<c:if test="${not empty processTypeIds}">
                 AND process.type_id IN (${u:toString(processTypeIds)})
            </c:if>
       
            GROUP BY process.id
            ORDER BY process_type.title
						
			<sql:param value="${fromdate}"/>		
			<sql:param value="${todate}"/>
		</sql:query>
		
		<table style="width: 100%;" class="data mt1">
			<tr>
				<td>ID</td>
				<td>Дата создания</td>
				<td>Дата принятия в исполнение</td>
				<td>Дата выполнения</td>
				<td>Исполнитель</td>
				<td>Задача</td>
				<td>Описание</td>
				<td>Результат</td>
				<td>Тип</td>
			</tr>	

			<c:forEach var="row" items="${result.rowsByIndex}">
				<c:set var="id" value="${row[0]}"/>
				<c:set var="createTime" value="${row[1]}"/>
				<c:set var="adaptDate" value="${row[2]}"/>
				<c:set var="complDate" value="${row[3]}"/>
				<c:set var="exec" value="${row[4]}"/>
				<c:set var="zad" value="${row[5]}"/>
				<c:set var="opis" value="${row[6]}"/>
				<c:set var="rez" value="${row[7]}"/>
				<c:set var="type" value="${row[8]}"/>
		
				<tr>
					<td><a href="UNDEF" onclick="$$.process.open( ${id} ); return false;">${id}</a></td>
					<td>${createTime}</td>
					<td>${adaptDate}</td>
					<td>${complDate}</td>
					<td>${exec}</td>
					<td>${zad}</td>
					<td>${opis}</td>
					<td>${rez}</td>
					<td>${type}</td>
				</tr>			
			</c:forEach>
		</table>	
	</c:if>
	    
</div>