<%@ page import="java.util.Enumeration"%>

<%@ page contentType="text/html; charset=UTF-8"%>
<%@ include file="/WEB-INF/jspf/taglibs.jsp"%>

<div class="center1020">
	<h2>Контрагенты - Отчет по кол-ву процессов</h2>
	
	<%--
	    Переменная form - объект класса ru.bgcrm.struts.form.DynActionForm, содержащий параметры запроса.
	--%>
	<c:set var="fromdate" value="${u:parseDate( form.param.fromdate, 'ymd' ) }"/>
	<c:set var="todate" value="${u:parseDate( form.param.todate, 'ymd' ) }"/>
	                
	
	<html:form action="/user/empty">
		<input type="hidden" name="forwardFile" value="/WEB-INF/jspf/user/plugin/custom.smartkom/report/old/custom_cust_report.jsp"/>
		
		Начало периода:
		<ui:date-time paramName="fromdate" value="first"/>
		
		Окончание периода:
		<ui:date-time paramName="todate" value="last"/>
		<br/>
		<br/>
		В указанный промежуток времени было больше трех процессов у данных контрагентов по одному адресу, указанному в таблице.
		<br/>
		<br/>
		<button type="button"  class="btn-grey ml1 mt05" onclick="openUrlToParent( formUrl( this.form ), $(this.form) )">Сформировать</button>
	</html:form>
	<%--
	Генерация отчёта, если в запросе пришёл параметр date.<>
	--%>
	<c:if test="${not empty fromdate}">
		<%-- в случае, если Slave база не настроена - будет использована обычная --%> 
		
		<sql:query var="result" dataSource="${ctxSlaveDataSource}">
	SELECT 
	GROUP_CONCAT(process.id SEPARATOR ',  '),
	customer.title,
	GROUP_CONCAT(DATE_FORMAT(process.create_dt, '%Y-%m-%d')SEPARATOR ',  '),
	<%--GROUP_CONCAT(process_type.title SEPARATOR ',  '),
	GROUP_CONCAT(param_address.value SEPARATOR ',  ') --%> 
	param_address.value
	FROM process
		LEFT JOIN process_type ON process.type_id = process_type.id 
		LEFT JOIN param_address ON process.id = param_address.id AND param_address.param_id = 42
		JOIN process_link ON process.id = process_link.process_id AND process_link.object_type = "customer"
		JOIN customer ON process_link.object_id = customer.id 
	WHERE (process.close_dt BETWEEN ? AND ? OR process.create_dt BETWEEN ? AND ?)
		AND process.type_id IN (12,21,19,9,1,4,7,8,3,5,6,2)
		
	    GROUP BY customer.title, param_address.value HAVING COUNT(process.id) > 3
	
	
	<sql:param value="${fromdate}"/>
	<sql:param value="${todate}"/>
	<sql:param value="${fromdate}"/>
	<sql:param value="${todate}"/>
	
	
	
	</sql:query>
		
		<table style="width: 100%;" class="data mt1">
	<tr>
		<td>Номера процессов</td>
		<td>Контрагент</td>
		<td>Дата создания процесса</td>
		<td>Адрес</td>
	</tr>
		<c:forEach var="row" items="${result.rowsByIndex}">
		<c:set var="id" value="${row[0]}"/>
		<c:set var="contr" value="${row[1]}"/>
		<c:set var="type" value="${row[2]}"/>
		<c:set var="addr" value="${row[3]}"/>
		
			<tr>
			<%--	<td><a href="UNDEF" onclick="openProcess( ${id} ); return false;">${id}</a></td> --%> 
				<td>${id}</td>
				<td>${contr}</td>
				<td>${type}</td>
				<td>${addr}</td>
			</tr>
				</c:forEach>
		</table>	
	</c:if>
	
	<%--<button type="button"  class="btn-grey ml1 mt05" >Выгрузить в xls</button> --%>
	    
</div>