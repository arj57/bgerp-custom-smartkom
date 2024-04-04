<%@ page import="java.util.Enumeration"%>

<%@ page contentType="text/html; charset=UTF-8"%>
<%@ include file="/WEB-INF/jspf/taglibs.jsp"%>

<div class="center1020">
	<h2>"Отчет СМО - отчет по заполнению перечня работ"</h2>
	<br/>
	
	<%-- В таблице "Системное сопровождение" Итого считаться не будет, все выводы по клиентам это разные сущности!  --%>
	В указанный период было принятие подключения (Установлен статус "Подключен/Активен")
	<br/>
	<br/>
	
	<%--
    Переменная form - объект класса ru.bgcrm.struts.form.DynActionForm, содержащий параметры запроса.
    --%>
    <c:set var="fromdate" value="${tu.parse( form.param.fromdate, 'ymd' ) }"/>
    <c:set var="todate" value="${tu.parse( form.param.todate, 'ymd' ) }"/>
<%-- 	<c:set var="listParamIds" value="${form.getSelectedValues('listParam')}"/>
	<c:set var="status" value="${form.getSelectedValues( 'status' )}"/> --%>
	<html:form action="/user/empty">
	<%--	<input type="hidden" name="forwardFile" value="/WEB-INF/custom/plugin/report/test_report.jsp"/> --%>
	<input type="hidden" name="forwardFile" value="/WEB-INF/jspf/user/plugin/custom.smartkom/report/old/custom_smo_work_report.jsp"/>
		
		
		Начало периода:
		<ui:date-time paramName="fromdate" value="first"/>
		
		Окончание периода:
		<ui:date-time paramName="todate" value="last"/>
		
		<br/>
<%-- 		<c:set var="listParam" value="${ctxParameterMap[u:int(114)]}"/>
	    <ui:combo-check
		    list="${listParam.listParamValues}" values="${listParamIds}"
		    prefixText="Организация:" widthTextValue="150px"
		    showFilter="1" paramName="listParam"/>	
		
		
		<ui:combo-check
			styleClass="ml05"
			list="${ctxProcessStatusList}" values="${status}"
			prefixText="Статус:" widthTextValue="150px"
			showFilter="1" paramName="status"/>--%>
			<br/>
		<br/>
		<button type="button"  class="btn-grey ml1 mt05" onclick="$$.ajax.load(this, $(this.form).parent())">Сформировать</button>
	</html:form>
	
		
				

				
	<c:if test="${not empty fromdate}">
	<sql:query var="result" dataSource="${ctxSlaveDataSource}">
	
	SELECT 
	process.id,
	param_address.value,
	process_type.title,
	plv3.title,
	GROUP_CONCAT(DISTINCT plv.title SEPARATOR ', '),
	GROUP_CONCAT(DISTINCT plv2.title SEPARATOR ', ')
<%--	param_listcount_value.title,
	param_listcount_value2.title --%>
	from process
	LEFT JOIN param_address ON process.id = param_address.id AND param_address.param_id = 42
	LEFT JOIN process_status AS ps ON process.id=ps.process_id AND ps.status_id=28
	LEFT JOIN process_type ON process.type_id=process_type.id
	LEFT JOIN param_list AS param_list ON process.id = param_list.id AND param_list.param_id = 128
	LEFT JOIN param_list_value AS plv ON param_list.value=plv.id AND plv.param_id=128
	LEFT JOIN param_pref ON param_list.param_id=param_pref.id AND param_pref.id=128
	LEFT JOIN param_list AS param_list2 ON process.id = param_list2.id AND param_list2.param_id = 129
	LEFT JOIN param_list_value AS plv2 ON param_list2.value=plv2.id AND plv2.param_id=129
	LEFT JOIN param_pref AS ppr ON param_list2.param_id=ppr.id AND ppr.id=129
	LEFT JOIN param_list AS param_list3 ON process.id = param_list3.id AND param_list3.param_id = 123
	LEFT JOIN param_list_value AS plv3 ON param_list3.value=plv3.id AND plv3.param_id=123
	LEFT JOIN param_listcount AS param_listcount ON process.id=param_listcount.id AND param_listcount.param_id=130
	LEFT JOIN param_listcount_value ON param_listcount.value=param_listcount_value.id AND param_listcount_value.param_id=130
	LEFT JOIN param_listcount AS param_listcount2 ON process.id=param_listcount2.id AND param_listcount2.param_id=131
	LEFT JOIN param_listcount_value AS param_listcount_value2 ON param_listcount2.value=param_listcount_value2.id AND param_listcount_value2.param_id=131
	WHERE (ps.dt BETWEEN ? AND addtime(?, '23:59:59'))
	AND process.type_id IN(119,124)
	
	GROUP BY process.id
	<sql:param value="${fromdate}"/>
	<sql:param value="${todate}"/>
	
			
	</sql:query>
	
	
		
	<table style="width: 100%"class="data mt1">
	<tr>
	<td>Номер процесса</td>
	<td>Адрес</td>
	<td>Тип услуги</td>
	<td>Услуга</td>
	<td>Перечень сдельных монтажных работ</td>
	<td>Перечень сдельных проектных работ</td>
<%-- <td>Перечень сдельных монтажных работ(СКС)</td>
	<td>Перечень сдельных проектных работ(СКС)</td> --%>
	
	</tr>
		<c:forEach var="row" items="${result.rowsByIndex}">
			<tr   >
				<td><a href="UNDEF" onclick="$$.process.open( ${row[0]} ); return false;">${row[0]}</a></td>
				<td>${row[1]}</td>
				<td>${row[2]}</td>
				<td>${row[3]}</td>
				<td>${row[4]}</td>
				<td>${row[5]}</td>
				
</tr>
				</c:forEach>
				
			
				</table>
				</c:if> 
</div>