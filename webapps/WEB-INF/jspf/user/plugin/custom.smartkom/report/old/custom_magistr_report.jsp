<%@ page import="java.util.Enumeration"%>

<%@ page contentType="text/html; charset=UTF-8"%>
<%@ include file="/WEB-INF/jspf/taglibs.jsp"%>

<div class="center1020">
	<h2>Магистральная проблема - Отчет по кол-ву процессов</h2>
	
	<%--
	    Переменная form - объект класса ru.bgcrm.struts.form.DynActionForm, содержащий параметры запроса.
	--%>
	<c:set var="fromdate" value="${u:parseDate( form.param.fromdate, 'ymd' ) }"/>
	<c:set var="todate" value="${u:parseDate( form.param.todate, 'ymd' ) }"/>
	                
	
	<html:form action="/user/empty">
		<input type="hidden" name="forwardFile" value="/WEB-INF/jspf/user/plugin/custom.smartkom/report/old/custom_magistr_report.jsp"/>
		
		Начало периода:
		<ui:date-time paramName="fromdate" value="first"/>
		
		Окончание периода:
		<ui:date-time paramName="todate" value="last"/>
		
		<br/>
		<br/>
		
		В указанный промежуток времени процесс был создан.
		
		<br/>
		
		<button type="button"  class="btn-grey ml1 mt05" onclick="openUrlToParent( formUrl( this.form ), $(this.form) )">Сформировать</button>
	</html:form>
	<%--
	Генерация отчёта, если в запросе пришёл параметр date.<>
	--%>
	<c:if test="${not empty fromdate}">
		<%-- в случае, если Slave база не настроена - будет использована обычная --%> 
		
		<sql:query var="result" dataSource="${ctxSlaveDataSource}">
	SELECT process.id, 
	param_address.value, 
	process.description,
	status.title,
	DATE_FORMAT(process.create_dt, '%Y-%m-%d %H.%i.%s'),
		CASE 
			WHEN param_list.value=1 THEN "Да" 
			WHEN param_list.value=2 THEN "Нет"
		END AS param_list_value,
		GROUP_CONCAT(DISTINCT user.title SEPARATOR ', ')
	FROM process
		LEFT JOIN param_address ON process.id = param_address.id AND param_address.param_id = 42
		LEFT JOIN param_list ON process.id = param_list.id AND param_list.param_id = 75
		LEFT JOIN process_status_title AS status ON process.status_id=status.id
		
		LEFT JOIN process_executor ON process.id = process_executor.process_id AND process_executor.role_id = 0
		
		LEFT JOIN user ON process_executor.user_id = user.id
	
	WHERE process.create_dt BETWEEN ? AND addtime(?, '23:59:59')
		AND process.type_id IN (11,28,41,29)
		
		GROUP BY process.id
		ORDER BY process.id
	
	
	
	<sql:param value="${fromdate}"/>
	<sql:param value="${todate}"/>
	
	
	
	</sql:query>
		
		<table style="width: 100%;" class="data mt1">
	<tr>
		<td>Номер</td>
		<td>Адрес</td>
		<td>Описание</td>
		<td>Статус</td>
		<td>Создан</td>
		<td>Выезд</td>
		<td>Исполнители</td>
		
	</tr>
		<c:forEach var="row" items="${result.rowsByIndex}">
		<c:set var="id" value="${row[0]}"/>
		<c:set var="addr" value="${row[1]}"/>
		<c:set var="descr" value="${row[2]}"/>
		<c:set var="status" value="${row[3]}"/>
		<c:set var="create" value="${row[4]}"/>
		<c:set var="viezd" value="${row[5]}"/>
		<c:set var="exec" value="${row[6]}"/>
		
		
			<tr>
				<td><a href="UNDEF" onclick="openProcess( ${id} ); return false;">${id}</a></td>
				<td>${addr}</td>
				<td>${descr}</td>
				<td>${status}</td>
				<td>${create}</td>
				<td>${viezd}</td>
				<td>${exec}</td>
			</tr>
				</c:forEach>
		</table>	
	</c:if>
	
	<%--<button type="button"  class="btn-grey ml1 mt05" >Выгрузить в xls</button> --%>
	    
</div>