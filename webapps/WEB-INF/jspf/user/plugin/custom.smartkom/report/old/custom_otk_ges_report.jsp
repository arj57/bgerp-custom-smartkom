<%@ page import="java.util.Enumeration"%>

<%@ page contentType="text/html; charset=UTF-8"%>
<%@ include file="/WEB-INF/jspf/taglibs.jsp"%>

<div class="center1020">
	<h2>ОТП - отчет ОТК</h2>
	
	<%--
	    Переменная form - объект класса ru.bgcrm.struts.form.DynActionForm, содержащий параметры запроса.
	--%>
	<c:set var="fromdate" value="${tu.parse( form.param.fromdate, 'ymd' ) }"/>
	<c:set var="todate" value="${tu.parse( form.param.todate, 'ymd' ) }"/>
	                
	
	<html:form action="/user/empty">
		<input type="hidden" name="forwardFile" value="/WEB-INF/jspf/user/plugin/custom.smartkom/report/old/custom_otk_ges_report.jsp"/>
		
		Начало периода:
		<ui:date-time paramName="fromdate" value="first"/>
		
		Окончание периода:
		<ui:date-time paramName="todate" value="last"/>
		
		<br/>
		<br/>
		
		В указанный промежуток времени процесс был выполнен.
		
		<br/>
		
		<button type="button"  class="btn-grey ml1 mt05" onclick="$$.ajax.load(this, $(this.form).parent())">Сформировать</button>
	</html:form>
	<%--
	Генерация отчёта, если в запросе пришёл параметр date.<>
	--%>
	<c:if test="${not empty fromdate}">
		<%-- в случае, если Slave база не настроена - будет использована обычная --%> 
		
		<sql:query var="result" dataSource="${ctxSlaveDataSource}">
	SELECT DATE_FORMAT(prstat.dt, '%Y-%m-%d %H.%i.%s'), process.id, param_text.value, param_address.value,
		CASE 
			WHEN param_list.value=1 THEN "Принят"
			WHEN param_list.value=2 THEN "Отменен"
			WHEN param_list.value=3 THEN "Проект не принят (нарушение тех политики)"
			WHEN param_list.value=4 THEN "Осмотр ОТК"
		END AS param_list_value, 
		CASE
			WHEN photo1.value=1 THEN "Размещены"
			WHEN photo1.value=2 THEN "Обновлены"
		END AS photo1_value,
		CASE
			WHEN photo2.value=1 THEN "Размещены"
			WHEN photo2.value=2 THEN "Обновлены"
		END AS photo2_value, 
		number2.value
	FROM process
		LEFT JOIN param_address ON process.id = param_address.id AND param_address.param_id = 42
		LEFT JOIN param_list ON process.id = param_list.id AND param_list.param_id = 68
		LEFT JOIN param_list AS photo1 ON process.id = photo1.id AND photo1.param_id = 117
		LEFT JOIN param_list AS photo2 ON process.id = photo2.id AND photo2.param_id = 119
		LEFT JOIN param_date AS podkl ON process.id = podkl.id AND podkl.param_id = 69
		LEFT JOIN param_text ON process.id = param_text.id AND param_text.param_id = 63
		LEFT JOIN param_text AS number ON process.id = number.id AND number.param_id = 78
		LEFT JOIN param_text AS number2 ON process.id = number2.id AND number2.param_id = 118
		LEFT JOIN process_link ON process.id = process_link.process_id AND process_link.object_type = "customer"
		LEFT JOIN process_status AS prstat ON process.id = prstat.process_id AND prstat.status_id = 5
		<%--Если несколько привязок в процессе (договоры и контрагент), отображает несколько раз процесс в отчете, хоть и поля контрагент пустые --%>
		LEFT JOIN customer ON process_link.object_id = customer.id 
	WHERE (prstat.dt BETWEEN ? AND ?)
		AND process.type_id = 24
		
		
		
	
	
	
	<sql:param value="${fromdate}"/>
	<sql:param value="${todate}"/>
	
	
	
	</sql:query>
		
		<table style="width: 100%;" class="data mt1">
	<tr>
		<td>Выполнен</td>
		<td>Номер процесса</td>
		<td>Компания</td>
		<td>Адрес</td>
		<td>Статус проекта</td>
		<td>Фото от монтажной бригады</td>
		<td>Фото по заявке ОТК</td>
		<td>Номер выездной заявки ОТК</td>
	</tr>
		<c:forEach var="row" items="${result.rowsByIndex}">
		<c:set var="compl" value="${row[0]}"/>
		<c:set var="id" value="${row[1]}"/>
		<c:set var="comp" value="${row[2]}"/>
		<c:set var="addr" value="${row[3]}"/>
		<c:set var="status" value="${row[4]}"/>
		<c:set var="photo1" value="${row[5]}"/>
		<c:set var="photo2" value="${row[6]}"/>
		<c:set var="number2" value="${row[7]}"/>
		
			<tr>
				<td>${compl}</td>
				<td><a href="UNDEF" onclick="$$.process.open( ${id} ); return false;">${id}</a></td>
				<td>${comp}</td>
				<td>${addr}</td>
				<td>${status}</td>
				<td>${photo1}</td>
				<td>${photo2}</td>
				<td>${number2}</td>
				
			</tr>
				</c:forEach>
		</table>	
	</c:if>
	
	<%--<button type="button"  class="btn-grey ml1 mt05" >Выгрузить в xls</button> --%>
	    
</div>