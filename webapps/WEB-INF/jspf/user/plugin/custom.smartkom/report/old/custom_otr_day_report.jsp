<%@ page import="java.util.Enumeration"%>

<%@ page contentType="text/html; charset=UTF-8"%>
<%@ include file="/WEB-INF/jspf/taglibs.jsp"%>

<div class="center1020">
	<h2>ОТР - Отчет по работе за день</h2>
	
	<%--
	    Переменная form - объект класса ru.bgcrm.struts.form.DynActionForm, содержащий параметры запроса.
	--%>
	<c:set var="fromdate" value="${tu.parse( form.param.fromdate, 'ymd' ) }"/>
	<c:set var="todate" value="${tu.parse( form.param.todate, 'ymd' ) }"/>
	                
	
	<html:form action="/user/empty">
		<input type="hidden" name="forwardFile" value="/WEB-INF/jspf/user/plugin/custom.smartkom/report/old/custom_otr_day_report.jsp"/>
		
		Начало периода:
		<ui:date-time paramName="fromdate" value="first"/>
		
		Окончание периода:
		<ui:date-time paramName="todate" value="last"/>
		
		<br/>
		<br/>
		
		В указанный промежуток было изменение параметра "Кол-во отработанных часов", группировка по исполнителю.
		<br/>
		<br/>
		Отчет актуален только на текущий день, т.к. ежедневно меняются одни и те же параметры.
		<br/>
		<br/>
		Если у Вас совпало "Кол-во отработанных часов" с предыдущим значением, необходимо сначала поменять его на любое другое значение,
		а затем ввести нужное корректное. 
		<br/>
		
<%-- 		<p>**${fromdate}</p><p>${form.param.fromdate}</p> --%>
		
		<br/>
		
		<button type="button"  class="btn-grey ml1 mt05" onclick="$$.ajax.load(this, $(this.form).parent())">Сформировать</button>
	</html:form>
	<%--
	Генерация отчёта, если в запросе пришёл параметр date.<>
	--%>
	<c:if test="${not empty fromdate}">
	    
		<%-- в случае, если Slave база не настроена - будет использована обычная --%>
		<sql:query var="result" dataSource="${ctxSlaveDataSource}">
			SELECT user.title, 
			SUM(ROUND(time.value,2))
		FROM process
		LEFT JOIN process_executor ON process.id = process_executor.process_id AND process_executor.role_id = 0		
		LEFT JOIN user ON process_executor.user_id = user.id		
		LEFT JOIN param_text AS time ON process.id = time.id AND time.param_id = 81		
		JOIN (SELECT 
					param_date.object_id AS id,
					MAX(param_date.dt) AS dt	
					FROM param_log as param_date 
					WHERE
					param_date.dt BETWEEN ? AND addtime(?, '23:59:59')
					AND param_date.param_id = 81
					GROUP BY param_date.object_id) AS param_date ON process.id = param_date.id		
		
			WHERE process.status_id IN (2,5,6)
			AND user.id IN (3,4,2,24,9,10,52,31,85)
       
            GROUP BY user.title
            ORDER BY user.title
						
			<sql:param value="${fromdate}"/>
			<sql:param value="${todate}"/>
			
		</sql:query>
		
		<table style="width: 100%;" class="data mt1">
			<tr>
				<td>Исполнитель</td>
				<td>Время</td>
			</tr>	

			<c:forEach var="row" items="${result.rowsByIndex}">
				<c:set var="exec" value="${row[0]}"/>
		        <c:set var="time" value="${row[1]}"/>
				
				<tr>
					<td>${exec}</td>
					<td>${time}</td>
				</tr>	
						
			</c:forEach>
		</table>
			
	</c:if>
	
	
	<c:if test="${not empty fromdate}">
	    
		<%-- в случае, если Slave база не настроена - будет использована обычная --%>
		<sql:query var="result" dataSource="${ctxSlaveDataSource}">
			SELECT process.id, 
			DATE_FORMAT(process.create_dt, '%Y-%m-%d'), 
			date.value, 
			DATE_FORMAT(process.close_dt, '%Y-%m-%d'),
			zad.value, 
			rez.value,
			NULL,
			GROUP_CONCAT(DISTINCT user.title SEPARATOR ', '),
			GROUP_CONCAT(DISTINCT us.title SEPARATOR ', '),
			time.value
		FROM process
		LEFT JOIN process_type ON process.type_id = process_type.id 
		LEFT JOIN process_executor ON process.id = process_executor.process_id AND process_executor.role_id = 0
		LEFT JOIN process_executor AS pe ON process.id = pe.process_id AND pe.role_id = 1
		LEFT JOIN user AS us ON pe.user_id = us.id
		LEFT JOIN user ON process_executor.user_id = user.id
		LEFT JOIN param_blob AS zad ON process.id = zad.id AND zad.param_id = 73
		LEFT JOIN param_blob AS rez ON process.id = rez.id AND rez.param_id = 74
		LEFT JOIN param_text AS time ON process.id = time.id AND time.param_id = 81
		LEFT JOIN param_log ON process.id = param_log.object_id AND param_log.param_id = 81
		LEFT JOIN param_date AS date ON process.id = date.id AND date.param_id = 61
		
		WHERE param_log.dt BETWEEN ? AND addtime(?, '23:59:59')
			AND process.status_id IN (2,5,6)
			AND user.id IN (3,4,2,24,9,10,52,31,85)
       
            GROUP BY process.id
            ORDER BY user.title
						
			<sql:param value="${fromdate}"/>
			<sql:param value="${todate}"/>
			
		</sql:query>
		
		<table style="width: 100%;" class="data mt1">
			<tr>
				<td>Номер процесса</td>
				<td>Дата постановки задачи</td>
				<td>Планируемая дата результата</td>
				<td>Дата результата</td>
				<td>Задача</td>
				<td>Результат</td>
				<td>Причина, если нарушены сроки</td>
				<td>Исполнитель</td>
				<td>Куратор</td>
				<td>Время</td>
			</tr>	

			<c:forEach var="row" items="${result.rowsByIndex}">
				<c:set var="id" value="${row[0]}"/>
				<c:set var="createTime" value="${row[1]}"/>
				<c:set var="plancomplDate" value="${row[2]}"/>
				<c:set var="complDate" value="${row[3]}"/>
				<c:set var="zad" value="${row[4]}"/>
				<c:set var="rez" value="${row[5]}"/>
				<c:set var="srok" value="${row[6]}"/>
				<c:set var="exec" value="${row[7]}"/>
				<c:set var="kurator" value="${row[8]}"/>
		        <c:set var="time" value="${row[9]}"/>
				<tr>
					<td><a href="UNDEF" onclick="$$.process.open( ${id} ); return false;">${id}</a></td>
					<td>${createTime}</td>
					<td>${plancomplDate}</td>
					<td>${complDate}</td>
					<td>${zad}</td>
					<td>${rez}</td>
					<td>${srok}</td>
					<td>${exec}</td>
					<td>${kurator}</td>
					<td>${time}</td>
				</tr>			
			</c:forEach>
		</table>	
	</c:if>
	
	    
</div>