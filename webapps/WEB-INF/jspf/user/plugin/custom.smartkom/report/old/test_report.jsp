<%@ page import="java.util.Enumeration"%>

<%@ page contentType="text/html; charset=UTF-8"%>
<%@ include file="/WEB-INF/jspf/taglibs.jsp"%>

<div>
	<h2>"Отчет Тест"</h2>
	<br/>
	

	В указанный период был установлен статус "Принят ОТК".
	
	<br/>
	<br/>
	
	<%--
    Переменная form - объект класса ru.bgcrm.struts.form.DynActionForm, содержащий параметры запроса.
    --%>
    <c:set var="fromdate" value="${u:parseDate( form.param.fromdate, 'ymd' ) }"/>
    <c:set var="todate" value="${u:parseDate( form.param.todate, 'ymd' ) }"/>
<%-- 	<c:set var="listParamIds" value="${form.getSelectedValues('listParam')}"/>
	<c:set var="status" value="${form.getSelectedValues( 'status' )}"/> --%>
	<html:form action="/user/empty">
	<%--	<input type="hidden" name="forwardFile" value="/WEB-INF/custom/plugin/report/test_report.jsp"/> --%>
	<input type="hidden" name="forwardFile" value="/WEB-INF/jspf/user/plugin/custom.smartkom/report/old/test_report.jsp"/>
		
		
		Начало периода:
		<ui:date-time paramName="fromdate" value="first"/>
		
		Окончание периода:
		<ui:date-time paramName="todate" value="last"/>		
		<br/>
		<br/>
		<br/>
		<button type="button"  class="btn-grey ml1 mt05" onclick="openUrlToParent( formUrl( this.form ), $(this.form) )">Сформировать</button>
	</html:form>
	
	<c:if test="${not empty fromdate}">
	<sql:query var="result" dataSource="${ctxSlaveDataSource}">
	
	SELECT 
	process.id,
	DATE_FORMAT(process.create_dt, '%Y-%m-%d'),
	param_date.value,
	DATE_FORMAT(ps.dt, '%Y-%m-%d'),
	"Дней на проект",
	process.description,
	param_address.value,
	process_type.title,
	"Есть",
	param_text.value,
	param_text1.value,
	plv.title,
	"Дата назначения проектировщика",
	GROUP_CONCAT(DISTINCT user.title SEPARATOR ', '),
	"Дата готовности проекта",
	"Дней на проект от заявки",
	param_date1.value,
	DATE_FORMAT(ps1.dt, '%Y-%m-%d'),
	"Дней на стройку",
	DATE_FORMAT(ps.dt, '%Y-%m-%d'),
	DATEDIFF(ps.dt,ps1.dt),
	param_text2.value,
	param_text3.value
	FROM process
	INNER JOIN (SELECT
				process_status.process_id,
				MAX(process_status.dt) as dt,
				process_status.status_id as status_id
				FROM process_status
				WHERE (process_status.dt BETWEEN ? AND addtime(?, '23:59:59'))
				AND process_status.status_id=31   
				GROUP BY process_status.process_id) AS ps ON process.id = ps.process_id AND ps.status_id=31
	LEFT JOIN (SELECT
				process_status.process_id,
				MAX(process_status.dt) as dt,
				process_status.status_id as status_id
				FROM process_status
				WHERE process_status.status_id=33   
				GROUP BY process_status.process_id) AS ps1 ON process.id = ps1.process_id AND ps1.status_id=33			
	LEFT JOIN param_date AS param_date ON process.id = param_date.id AND param_date.param_id = 133
	LEFT JOIN param_address ON process.id = param_address.id AND param_address.param_id = 42
	LEFT JOIN param_date AS param_date1 ON process.id = param_date1.id AND param_date1.param_id = 85
	LEFT JOIN process_type ON process.type_id=process_type.id
	LEFT JOIN param_text AS param_text ON process.id = param_text.id AND param_text.param_id = 134
	LEFT JOIN param_text AS param_text1 ON process.id = param_text1.id AND param_text1.param_id = 135
	LEFT JOIN param_text AS param_text2 ON process.id = param_text2.id AND param_text2.param_id = 137
	LEFT JOIN param_text AS param_text3 ON process.id = param_text3.id AND param_text3.param_id = 138
	LEFT JOIN param_list AS param_list ON process.id = param_list.id AND param_list.param_id = 120
	LEFT JOIN param_list_value AS plv ON param_list.value=plv.id AND plv.param_id=120
	LEFT JOIN process_executor ON process.id = process_executor.process_id AND process_executor.role_id = 0 AND process_executor.group_id=11
	LEFT JOIN user ON process_executor.user_id = user.id
	WHERE process.type_id IN (116,117,118)
	
	GROUP BY process.id
	<sql:param value="${fromdate}"/>
	<sql:param value="${todate}"/>

		
	</sql:query>
			
	<table style="width: 100%"class="data mt1">
	<tr>
	<td>Номер процесса</td>
	<td>Дата заявки</td>
	<td>Требуемая дата завершения</td>
	<td>Дата завершения(факт.)</td>
	<td>Дней на проект</td>
	<td>Краткое наименование</td>
	<td>Адрес</td>
	<td>Тип заявки</td>
	<td>Согласование</td>
	<td>Ёмкость новых абонпортов</td>
	<td>Прирост новых зданий</td>
	<td>Тип проекта</td>
	<td>Дата назначение проектировщика</td>
	<td>Проектировщик</td>
	<td>Дата готовности проекта</td>
	<td>Дней на проект от заявки</td>
	<td>Планируема дата проведения монтажных работ</td>
	<td>Дата окончания строительства</td>
	<td>Дней на стройку</td>
	<td>Дата приемки проекта</td>
	<td>Дней на приемку от стройки</td>
	<td>Стоимость работ по проекту</td>
	<td>Стоимость монтажных работ</td>
	</tr>
		<c:forEach var="row" items="${result.rowsByIndex}">
			<tr>
				<td><a href="UNDEF" onclick="openProcess( ${row[0]} ); return false;">${row[0]}</a></td>
				<td>${row[1]}</td>
				<td>${row[2]}</td>
				<td>${row[3]}</td>
				<td>${row[4]}</td>
				<td>${row[5]}</td>
				<td>${row[6]}</td>
				<td>${row[7]}</td>
				<td>${row[8]}</td>
				<td>${row[9]}</td>
				<td>${row[10]}</td>
				<td>${row[11]}</td>
				<td>${row[12]}</td>
				<td>${row[13]}</td>
				<td>${row[14]}</td>
				<td>${row[15]}</td>
				<td>${row[16]}</td>
				<td>${row[17]}</td>
				<td>${row[18]}</td>
				<td>${row[19]}</td>
				<td>${row[20]}</td>
				<td>${row[21]}</td>
				<td>${row[22]}</td>
				
			</tr>
				</c:forEach>
				
			
				</table>
				</c:if> 
</div>