<%@ page import="java.util.Enumeration"%>

<%@ page contentType="text/html; charset=UTF-8"%>
<%@ include file="/WEB-INF/jspf/taglibs.jsp"%>

<div class="center1020">
	<h2>Отчет ТП "Аренда"</h2>
	
	<%--
	    Переменная form - объект класса ru.bgcrm.struts.form.DynActionForm, содержащий параметры запроса.
	--%>
	<c:set var="fromdate" value="${u:parseDate( form.param.fromdate, 'ymd' ) }"/>
	<c:set var="todate" value="${u:parseDate( form.param.todate, 'ymd' ) }"/>
	                
	
	<html:form action="/user/empty">
		<input type="hidden" name="forwardFile" value="/WEB-INF/jspf/user/plugin/custom.smartkom/report/old/custom_tp_arenda_report.jsp"/>
		
		Начало периода:
		<ui:date-time paramName="fromdate" value="first"/>
		
		Окончание периода:
		<ui:date-time paramName="todate" value="last"/>
		
		<br/>
		<br/>
		
		В указанный промежуток времени процесс был либо создан, либо закрыт, параметр "Аренда" в значении "ДА".
		
		<br/>
		
		<button type="button"  class="btn-grey ml1 mt05" onclick="openUrlToParent( formUrl( this.form ), $(this.form) )">Сформировать</button>
	</html:form>
	<%--
	Генерация отчёта, если в запросе пришёл параметр date.<>
	--%>
	<c:if test="${not empty fromdate}">
		<%-- в случае, если Slave база не настроена - будет использована обычная --%> 
		
		<sql:query var="result" dataSource="${ctxSlaveDataSource}">
	SELECT  process.id, DATE_FORMAT(process.create_dt, '%Y-%m-%d %H:%i:%s'), DATE_FORMAT(process.close_dt, '%Y-%m-%d %H:%i:%s'), customer.title, GROUP_CONCAT(param_address.value SEPARATOR ', '), 
		CASE 
			WHEN param_list.value=2 THEN "ДА"
		END AS param_list_value
	FROM process
		LEFT JOIN param_address ON process.id = param_address.id AND param_address.param_id = 42
		LEFT JOIN param_list ON process.id = param_list.id AND param_list.param_id = 98
		LEFT JOIN param_date AS podkl ON process.id = podkl.id AND podkl.param_id = 69
		LEFT JOIN param_text ON process.id = param_text.id AND param_text.param_id = 63
		LEFT JOIN param_text AS number ON process.id = number.id AND number.param_id = 78
		LEFT JOIN process_link ON process.id = process_link.process_id AND process_link.object_type = "customer"
		<%--Если несколько привязок в процессе (договоры и контрагент), отображает несколько раз процесс в отчете, хоть и поля контрагент пустые --%>
		LEFT JOIN customer ON process_link.object_id = customer.id 
	WHERE (process.close_dt BETWEEN ? AND  addtime(?, '23:59:59') OR process.create_dt BETWEEN ? AND  addtime(?, '23:59:59') )
		AND process.type_id IN(12,2,6,5,3,8,7,4,1,9,19,21,43,44,60,56)
		AND param_list.value=2
		
	GROUP BY process.id
	
	<sql:param value="${fromdate}"/>
	<sql:param value="${todate}"/>
	<sql:param value="${fromdate}"/>
	<sql:param value="${todate}"/>
	
	
	
	</sql:query>
		
		<table style="width: 100%;" class="data mt1">
	<tr>
		<td>Номер</td>
		<td>Cоздан</td>
		<td>Закрыт</td>
		<td>Контрагент</td>
		<td>Адрес</td>
		<td>Аренда</td>
	</tr>
		<c:forEach var="row" items="${result.rowsByIndex}">
		<c:set var="id" value="${row[0]}"/>
		<c:set var="addr" value="${row[1]}"/>
		<c:set var="status" value="${row[2]}"/>
		<c:set var="datepod" value="${row[3]}"/>
		<c:set var="comp" value="${row[4]}"/>
		<c:set var="contr" value="${row[5]}"/>
		
		
			<tr>
				<td><a href="UNDEF" onclick="openProcess( ${id} ); return false;">${id}</a></td>
				<td>${addr}</td>
				<td>${status}</td>
				<td>${datepod}</td>
				<td>${comp}</td>
				<td>${contr}</td>
				
				
			</tr>
				</c:forEach>
		</table>	
	</c:if>
	
	<%--<button type="button"  class="btn-grey ml1 mt05" >Выгрузить в xls</button> --%>
	    
</div>