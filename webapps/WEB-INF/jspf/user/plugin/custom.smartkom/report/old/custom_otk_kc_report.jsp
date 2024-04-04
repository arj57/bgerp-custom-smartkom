<%@ page import="java.util.Enumeration"%>

<%@ page contentType="text/html; charset=UTF-8"%>
<%@ include file="/WEB-INF/jspf/taglibs.jsp"%>

<div class="center1020">
	<h2>ОТК - Отчет КЦ</h2>
	
	<%--
	    Переменная form - объект класса ru.bgcrm.struts.form.DynActionForm, содержащий параметры запроса.
	--%>
	<c:set var="fromdate" value="${tu.parse( form.param.fromdate, 'ymd' ) }"/>
	<c:set var="todate" value="${tu.parse( form.param.todate, 'ymd' ) }"/>
	                
	
	<html:form action="/user/empty">
		<input type="hidden" name="forwardFile" value="/WEB-INF/jspf/user/plugin/custom.smartkom/report/old/custom_otk_kc_report.jsp"/>
		
		Начало периода:
		<ui:date-time paramName="fromdate" value="first"/>
		
		Окончание периода:
		<ui:date-time paramName="todate" value="last"/>
		
		<br/>
		<br/>
		
		В указанный промежуток времени процесс был либо создан, либо закрыт.
		
		<br/>
		
		<button type="button"  class="btn-grey ml1 mt05" onclick="$$.ajax.load(this, $(this.form).parent())">Сформировать</button>
	</html:form>
	<%--
	Генерация отчёта, если в запросе пришёл параметр date.<>
	--%>
	<c:if test="${not empty fromdate}">
		<%-- в случае, если Slave база не настроена - будет использована обычная --%> 
		
		<sql:query var="result" dataSource="${ctxSlaveDataSource}">
	SELECT process.id, 
	customer.title, 
	param_text.value,
	param_address.value, 
		DATE_FORMAT(process.create_dt, '%Y-%m-%d %H.%i.%s'),
		DATE_FORMAT(prstat.dt, '%Y-%m-%d %H.%i.%s'), 
		prlink.process_id,
		process_type.title,
		DATE_FORMAT(process.close_dt, '%Y-%m-%d %H.%i.%s') 
	FROM process
		LEFT JOIN param_address ON process.id = param_address.id AND param_address.param_id = 42
		LEFT JOIN process_status AS prstat ON process.id = prstat.process_id AND prstat.status_id = 5
		LEFT JOIN process_link ON process.id = process_link.process_id AND process_link.object_type = "customer"
		LEFT JOIN param_text ON process.id = param_text.id AND param_text.param_id = 63
		LEFT JOIN process_link AS prlink ON process.id = prlink.object_id AND prlink.object_type = "processLink"
		LEFT JOIN process AS pr2 ON prlink.process_id = pr2.id 
		LEFT JOIN process_type ON pr2.type_id = process_type.id
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
		<td>Номер процесса</td>
		<td>Контрагент</td>
		<td>Компания</td>
		<td>Адрес</td>
		<td>Дата создания</td>
		<td>Дата выполнения</td>
		<td>Связанный процесс</td>
		<td>Тип связанного процесса</td>
		<td>Дата закрытия</td>
	</tr>
		<c:forEach var="row" items="${result.rowsByIndex}">
		<c:set var="id" value="${row[0]}"/>
		<c:set var="contr" value="${row[1]}"/>
		<c:set var="comp" value="${row[2]}"/>
		<c:set var="addr" value="${row[3]}"/>
		<c:set var="createTime" value="${row[4]}"/>
		<c:set var="complDate" value="${row[5]}"/>
		<c:set var="linkProcess" value="${row[6]}"/>
		<c:set var="typeLinkProcess" value="${row[7]}"/>
		<c:set var="closeDate" value="${row[8]}"/>
		
			<tr>
				<td><a href="UNDEF" onclick="$$.process.open( ${id} ); return false;">${id}</a></td>
				<td>${contr}</td>
				<td>${comp}</td>
				<td>${addr}</td>
				<td>${createTime}</td>
				<td>${complDate}</td>
				<td><a href="UNDEF" onclick="openProcess( ${linkProcess} ); return false;">${linkProcess}</a></td>
				<td>${typeLinkProcess}</td>
				<td>${closeDate}</td>
				
			</tr>
				</c:forEach>
		</table>	
	</c:if>
	
	<%--<button type="button"  class="btn-grey ml1 mt05" >Выгрузить в xls</button> --%>
	    
</div>