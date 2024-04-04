<%@ page import="java.util.Enumeration"%>

<%@ page contentType="text/html; charset=UTF-8"%>
<%@ include file="/WEB-INF/jspf/taglibs.jsp"%>

<div class="center1020">
	<h2>"1С - Отчёт по процессам"</h2>
	<br/>
	
	<%-- В таблице "Системное сопровождение" Итого считаться не будет, все выводы по клиентам это разные сущности!  --%>
	В указанный период попала дата начала или окончания работы
	<br/>
	<br/>
	
	<%--
    Переменная form - объект класса ru.bgcrm.struts.form.DynActionForm, содержащий параметры запроса.
    --%>
    <c:set var="fromdate" value="${tu.parse( form.param.fromdate, 'ymd' ) }"/>
    <c:set var="todate" value="${tu.parse( form.param.todate, 'ymd' ) }"/>
	<c:set var="listParamIds" value="${form.getSelectedValues('listParam')}"/>
	<c:set var="status" value="${form.getSelectedValues( 'status' )}"/>
	<html:form action="/user/empty">
	<%--	<input type="hidden" name="forwardFile" value="/WEB-INF/custom/plugin/report/test_report.jsp"/> --%>
	<input type="hidden" name="forwardFile" value="/WEB-INF/jspf/user/plugin/custom.smartkom/report/old/custom_1C_report.jsp"/>
		
		
		Начало периода:
		<ui:date-time paramName="fromdate" value="first"/>
		
		Окончание периода:
		<ui:date-time paramName="todate" value="last"/>
	
	
		<c:set var="listParam" value="${ctxParameterMap[u:int(114)]}"/>
	    <ui:combo-check
		    list="${listParam.listParamValues}" values="${listParamIds}"
		    prefixText="Организация:" widthTextValue="150px"
		    showFilter="1" paramName="listParam"/>	
				
		<ui:combo-check
			styleClass="ml05"
			list="${ctxProcessStatusList}" values="${status}"
			prefixText="Статус:" widthTextValue="150px"
			showFilter="1" paramName="status"/>
		
		<br/>
		<button type="button"  class="btn-grey ml1 mt05" onclick="$$.ajax.load(this, $(this.form).parent())">Сформировать</button>
	</html:form>
	
	
	

	<c:if test="${not empty fromdate}">
		
		<sql:query var="result" dataSource="${ctxSlaveDataSource}">
	SELECT row_number() over(ORDER BY DATE_FORMAT(vstart.value, '%Y-%m-%d')) num,
	DATE_FORMAT(vstart.value, '%Y-%m-%d'),
	NULL,
	DATE_FORMAT(vstart.value, '%H.%i'),
	CONCAT ('#',process.id,'  ', process.description),
	NULL,
	NULL,
	NULL,
	DATE_FORMAT(vend.value, '%H.%i'),
	param_text.value,
	NULL,
	'подпись заказчика',
	GROUP_CONCAT(DISTINCT user.title SEPARATOR ', '),
	param_list_value.title
	FROM process
	LEFT JOIN param_datetime AS vstart ON process.id = vstart.id AND vstart.param_id = 83
	LEFT JOIN param_datetime AS vend ON process.id = vend.id AND vend.param_id = 84
	LEFT JOIN param_text ON process.id = param_text.id AND param_text.param_id = 81
	LEFT JOIN process_status ON process.id = process_status.process_id
	LEFT JOIN process_status_title ON process.status_id=process_status_title.id
	LEFT JOIN process_executor ON process.id = process_executor.process_id AND process_executor.role_id = 0
	LEFT JOIN user ON process_executor.user_id = user.id
	LEFT JOIN param_list ON process.id = param_list.id AND param_list.param_id = 114
	LEFT JOIN param_list_value ON param_list_value.id=param_list.value AND param_list_value.param_id = 114
	WHERE (vstart.value BETWEEN ? AND addtime(?, '23:59:59') OR vend.value BETWEEN ? AND addtime(?, '23:59:59'))
	AND process.type_id IN(45,87,86)
	AND process_executor.group_id IN(12)
	<c:if test="${not empty listParamIds}">
	AND param_list.value IN(${u:toString( listParamIds )})
	</c:if>
	<c:if test="${not empty status}">
	And process.status_id IN(${u:toString( status )}) 
	</c:if>
<%--	AND param_list.value='3'выборка по параметру "Организация"--%> 
	
	GROUP BY process.id
	ORDER BY DATE_FORMAT(vstart.value, '%Y-%m-%d')
	
	<sql:param value="${fromdate}"/>
	<sql:param value="${todate}"/>
	<sql:param value="${fromdate}"/>
	<sql:param value="${todate}"/>
	
	
	
	</sql:query>
		
		<table style="width: 100%;"class="data mt1">
	<tr>
	<td>№</td>
	<td>Дата</td>
	<td>Выезд</td>
	<td>Время начала работы</td>
	<%--<td>Номер процесса</td>--%> 
	<td width="80%">Выполнение требований (содержание работы)</td>
	<td>Проведение испытаний на функц. (да/нет)</td>
	<td>№ релиза платформы</td>
	<td>№ релиза конфигурации</td>
	<td>Время окончания работы</td>
	<td>Кол-во отработанных часов</td>
	<td>Замечания к выполненной работе</td>
	<td>Работы выполнены</td>
	<td>Исполнитель</td>
	<td>Организация</td>
	</tr>
		<c:forEach var="row" items="${result.rowsByIndex}">
			<tr>
				<td>${row[0]}</td>
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
				<td><sub><small>${row[11]}</small></sub></td>
				<td>${row[12]}</td>
				<td>${row[13]}</td>
				
			
				</tr>
				</c:forEach>
				</table>
				</c:if>
</div>