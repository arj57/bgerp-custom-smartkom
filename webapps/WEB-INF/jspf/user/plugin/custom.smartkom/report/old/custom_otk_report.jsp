<%@ page import="java.util.Enumeration"%>

<%@ page contentType="text/html; charset=UTF-8"%>
<%@ include file="/WEB-INF/jspf/taglibs.jsp"%>

<div class="center1020">
	<h2>ОТК - Отчет</h2>
	
	<%--
	    Переменная form - объект класса ru.bgcrm.struts.form.DynActionForm, содержащий параметры запроса.
	--%>
	<c:set var="fromdate" value="${u:parseDate( form.param.fromdate, 'ymd' ) }"/>
	<c:set var="todate" value="${u:parseDate( form.param.todate, 'ymd' ) }"/>
	                
	
	<html:form action="/user/empty">
		<input type="hidden" name="forwardFile" value="/WEB-INF/jspf/user/plugin/custom.smartkom/report/old/custom_otk_report.jsp"/>
		
		Начало периода:
		<ui:date-time paramName="fromdate" value="first"/>
		
		Окончание периода:
		<ui:date-time paramName="todate" value="last"/>
		
		<br/>
		<br/>
		
		В указанный промежуток времени процесс был либо создан, либо закрыт.
		
		<br/>
		
		<button type="button"  class="btn-grey ml1 mt05" onclick="openUrlToParent( formUrl( this.form ), $(this.form) )">Сформировать</button>
	</html:form>
	<%--
	Генерация отчёта, если в запросе пришёл параметр date.<>
	--%>
	<c:if test="${not empty fromdate}">
		<%-- в случае, если Slave база не настроена - будет использована обычная --%> 
		
		<sql:query var="result" dataSource="${ctxSlaveDataSource}">
	SELECT process.id, param_address.value, 
		CASE 
			WHEN param_list.value=1 THEN "Принят"
			WHEN param_list.value=2 THEN "Отменен"
			WHEN param_list.value=3 THEN "Проект не принят (нарушение тех политики)"
			WHEN param_list.value=4 THEN "Осмотр ОТК"
		END AS param_list_value,
		podkl.value, 
		param_text.value, 
		customer.title,
		number.value
	FROM process
		LEFT JOIN param_address ON process.id = param_address.id AND param_address.param_id = 42
		LEFT JOIN param_list ON process.id = param_list.id AND param_list.param_id = 68
		LEFT JOIN param_date AS podkl ON process.id = podkl.id AND podkl.param_id = 69
		LEFT JOIN param_text ON process.id = param_text.id AND param_text.param_id = 63
		LEFT JOIN param_text AS number ON process.id = number.id AND number.param_id = 78
		LEFT JOIN process_link ON process.id = process_link.process_id AND process_link.object_type = "customer"
		<%--Если несколько привязок в процессе (договоры и контрагент), отображает несколько раз процесс в отчете, хоть и поля контрагент пустые --%>
		LEFT JOIN customer ON process_link.object_id = customer.id 
	WHERE (process.close_dt BETWEEN ? AND ? OR process.create_dt BETWEEN ? AND ?)
		AND process.type_id = 24
		
		
		
	
	
	<sql:param value="${fromdate}"/>
	<sql:param value="${todate}"/>
	<sql:param value="${fromdate}"/>
	<sql:param value="${todate}"/>
	
	
	
	</sql:query>
		
		<table style="width: 100%;" class="data mt1">
	<tr>
		<td>Номер</td>
		<td>Адрес</td>
		<td>Статус проекта</td>
		<td>Дата подключения</td>
		<td>Компания</td>
		<td>Контрагент</td>
		<td>Номер наряда</td>
	</tr>
		<c:forEach var="row" items="${result.rowsByIndex}">
		<c:set var="id" value="${row[0]}"/>
		<c:set var="addr" value="${row[1]}"/>
		<c:set var="status" value="${row[2]}"/>
		<c:set var="datepod" value="${row[3]}"/>
		<c:set var="comp" value="${row[4]}"/>
		<c:set var="contr" value="${row[5]}"/>
		<c:set var="number" value="${row[6]}"/>
		
			<tr>
				<td><a href="UNDEF" onclick="openProcess( ${id} ); return false;">${id}</a></td>
				<td>${addr}</td>
				<td>${status}</td>
				<td>${datepod}</td>
				<td>${comp}</td>
				<td>${contr}</td>
				<td>${number}</td>
				
			</tr>
				</c:forEach>
		</table>	
	</c:if>
	
	<%--<button type="button"  class="btn-grey ml1 mt05" >Выгрузить в xls</button> --%>
	    
</div>