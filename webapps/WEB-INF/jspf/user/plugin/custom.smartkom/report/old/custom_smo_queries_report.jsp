<%@ page import="java.util.Enumeration"%>

<%@ page contentType="text/html; charset=UTF-8"%>
<%@ include file="/WEB-INF/jspf/taglibs.jsp"%>

<div class="center1020">
	<h2>Отчет по выездам СМО</h2>
	
	<html:form action="/user/empty">
		<input type="hidden" name="forwardFile" value="/WEB-INF/jspf/user/plugin/custom.smartkom/report/old/custom_smo_queries_report.jsp"/>
		
		<br/>
		
		Отчет формируется за вчерашний день (процесс был закрыт вчера)
		<br/>
		<%--<button type="button"  class="btn-grey ml1 mt05" onclick="$$.ajax.load(this, $(this.form).parent())">Сформировать</button> --%>
	</html:form>
		<%-- в случае, если Slave база не настроена - будет использована обычная --%> 
		<sql:query var="result" dataSource="${ctxSlaveDataSource}">
	SELECT process.id, process.description, user.title, param_address.value, 
		CASE 
		WHEN param_list.value=1 THEN "ДА"
		WHEN param_list.value=2 THEN "НЕТ"
		END AS param_list_value,
	DATE_FORMAT(vstart.value, '%Y-%m-%d %H.%i.%s'), DATE_FORMAT(vend.value, '%Y-%m-%d %H.%i.%s'), zadmes.text, rezmes.text
	FROM process
	LEFT JOIN process_executor ON process.id = process_executor.process_id AND process_executor.role_id = 0
	LEFT JOIN user ON process_executor.user_id = user.id
	LEFT JOIN param_address ON process.id = param_address.id AND param_address.param_id = 42
	LEFT JOIN param_list ON process.id = param_list.id AND param_list.param_id = 65
	LEFT JOIN param_datetime AS vstart ON process.id = vstart.id AND vstart.param_id = 66
	LEFT JOIN param_datetime AS vend ON process.id = vend.id AND vend.param_id = 67
	LEFT JOIN message AS zadmes ON process.id = zadmes.process_id AND zadmes.type_id = 7
	LEFT JOIN message AS rezmes ON process.id = rezmes.process_id AND rezmes.type_id = 8
	LEFT JOIN process_group ON process.id = process_group.process_id AND process_group.group_id = 7
	WHERE process.close_dt >= (CURDATE()-1) AND CURDATE() > process.close_dt
	AND process.type_id = 30
	AND process_executor.group_id IN(13,14)
	</sql:query>
		
		<table style="width: 100%;" class="data mt1">
	<tr>
		<td>Номер</td>
		<td>Описание</td>
		<td>Исполнители</td>
		<td>Адрес</td>
		<td>Передача в ПО</td>
		<td>Время начала выезда</td>
		<td>Время окончания выезда</td>
		<td>Задача на выезд</td>
		<td>Результат выезда</td>
	</tr>
		<c:forEach var="row" items="${result.rowsByIndex}">
		<c:set var="id" value="${row[0]}"/>
		<c:set var="description" value="${row[1]}"/>
		<c:set var="exec" value="${row[2]}"/>
		<c:set var="addr" value="${row[3]}"/>
		<c:set var="PO" value="${row[4]}"/>
		<c:set var="TS" value="${row[5]}"/>
		<c:set var="TSt" value="${row[6]}"/>
		<c:set var="zad" value="${row[7]}"/>
		<c:set var="rez" value="${row[8]}"/>
			<tr>
				<td>${id}</td>
				<td>${description}</td>
				<td>${exec}</td>
				<td>${addr}</td>
				<td>${PO}</td>
				<td>${TS}</td>
				<td>${TSt}</td>
				<td>${zad}</td>
				<td>${rez}</td>
			</tr>
				</c:forEach>
		</table>	
	
	<%--<button type="button"  class="btn-grey ml1 mt05" >Выгрузить в xls</button> --%>
	

	
	    
</div>