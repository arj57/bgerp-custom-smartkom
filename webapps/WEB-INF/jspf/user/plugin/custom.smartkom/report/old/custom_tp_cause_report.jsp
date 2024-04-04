<%@ page import="java.util.Enumeration"%>

<%@ page contentType="text/html; charset=UTF-8"%>
<%@ include file="/WEB-INF/jspf/taglibs.jsp"%>

<div class="center1020">
	<h2>Отчет ТП</h2>
	<h2>Причины процессов "Клиентская проблема"</h2>
	
	<%--
	    Переменная form - объект класса ru.bgcrm.struts.form.DynActionForm, содержащий параметры запроса.
	--%>
	<c:set var="fromdate" value="${tu.parse( form.param.fromdate, 'ymd' ) }"/>
	<c:set var="todate" value="${tu.parse( form.param.todate, 'ymd' ) }"/>
	                
	
	<html:form action="/user/empty">
		<input type="hidden" name="forwardFile" value="/WEB-INF/jspf/user/plugin/custom.smartkom/report/old/custom_tp_cause_report.jsp"/>
		
		Начало периода:
		<ui:date-time paramName="fromdate" value="first"/>
		
		Окончание периода:
		<ui:date-time paramName="todate" value="last"/>
		
		<br/>
		<br/>
		
		В указанный промежуток времени процесс был закрыт.
		
		<br/>
		
		<button type="button"  class="btn-grey ml1 mt05" onclick="$$.ajax.load(this, $(this.form).parent())">Сформировать</button>
	</html:form>
	<%--
	Генерация отчёта, если в запросе пришёл параметр date.<>
	--%>
	<c:if test="${not empty fromdate}">
		<%-- в случае, если Slave база не настроена - будет использована обычная --%> 
		
		<sql:query var="result" dataSource="${ctxSlaveDataSource}">
	SELECT  process.id, DATE_FORMAT(process.close_dt, '%Y-%m-%d %H:%i:%s'), customer.title, GROUP_CONCAT(DISTINCT param_address.value SEPARATOR ', '), 
		CASE 
			WHEN param_list.value=1 THEN "Авария на узле"
			WHEN param_list.value=2 THEN "Последняя миля: Радио"
			WHEN param_list.value=3 THEN "Последняя миля: Аренда"
			WHEN param_list.value=4 THEN "Последняя миля: Медная линия связи"
			WHEN param_list.value=5 THEN "Последняя миля: Оптическая линия связи"
			WHEN param_list.value=6 THEN "Последняя миля: Коннектор медь"
			WHEN param_list.value=7 THEN "Последняя миля: Коннектор оптика"
			WHEN param_list.value=8 THEN "Оборудование: PON"
			WHEN param_list.value=9 THEN "Оборудование: Камера"
			WHEN param_list.value=10 THEN "Оборудование: Шлюз"
			WHEN param_list.value=11 THEN "Оборудование: Роутер"
			WHEN param_list.value=12 THEN "Оборудование: Зашумленность Wi-Fi"
			WHEN param_list.value=13 THEN "Оборудование: Зона покрытия Wi-Fi"
			WHEN param_list.value=14 THEN "Аутсорс: ПК + периферия"
			WHEN param_list.value=15 THEN "Аутсорс: сетевое оборудование"
			WHEN param_list.value=16 THEN "Доступность ресурса в интернете"
			WHEN param_list.value=17 THEN "Сервис: телефонии"
			WHEN param_list.value=18 THEN "Сервис: видеонаблюдения"
			WHEN param_list.value=19 THEN "Сервис: WNAM"
			WHEN param_list.value=20 THEN "Сервис: Смотрешка"
			WHEN param_list.value=21 THEN "Сервис: Forpost"
			WHEN param_list.value=22 THEN "Ошибка сотрудника"
			WHEN param_list.value=23 THEN "Не технический запрос"
			WHEN param_list.value=24 THEN "Техническая консультация"
		END AS param_list_value,
		GROUP_CONCAT(DISTINCT user.title SEPARATOR ', ')
	FROM process
		LEFT JOIN param_address ON process.id = param_address.id AND param_address.param_id = 42
		LEFT JOIN param_list ON process.id = param_list.id AND param_list.param_id = 115
		LEFT JOIN process_link ON process.id = process_link.process_id AND process_link.object_type = "customer"
		LEFT JOIN customer ON process_link.object_id = customer.id 
		LEFT JOIN process_executor ON process.id = process_executor.process_id AND process_executor.role_id = 0
		LEFT JOIN user ON process_executor.user_id = user.id
	WHERE (process.close_dt BETWEEN ? AND  addtime(?, '23:59:59'))
		AND process.type_id IN(12,2,6,5,3,8,7,4,1,9,19,21,43,44,60,56)
		
		
	GROUP BY process.id
	
	<sql:param value="${fromdate}"/>
	<sql:param value="${todate}"/>
	
	
	
	
	</sql:query>
		
		<table style="width: 100%;" class="data mt1">
	<tr>
		<td>Номер</td>
		<td>Закрыт</td>
		<td>Контрагент</td>
		<td>Адрес</td>
		<td>Причина</td>
		<td>Исполнители</td>
	</tr>
		<c:forEach var="row" items="${result.rowsByIndex}">
		<c:set var="id" value="${row[0]}"/>
		<c:set var="close" value="${row[1]}"/>
		<c:set var="contr" value="${row[2]}"/>
		<c:set var="addr" value="${row[3]}"/>
		<c:set var="cause" value="${row[4]}"/>
		<c:set var="exec" value="${row[5]}"/>
		
		
			<tr>
				<td><a href="UNDEF" onclick="$$.process.open( ${id} ); return false;">${id}</a></td>
				<td>${close}</td>
				<td>${contr}</td>
				<td>${addr}</td>
				<td>${cause}</td>
				<td>${exec}</td>
				
				
			</tr>
				</c:forEach>
		</table>	
	</c:if>
	
	<%--<button type="button"  class="btn-grey ml1 mt05" >Выгрузить в xls</button> --%>
	    
</div>