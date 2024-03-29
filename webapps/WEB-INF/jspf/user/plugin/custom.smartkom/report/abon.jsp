<%@ page contentType="text/html; charset=UTF-8"%>
<%@ include file="/WEB-INF/jspf/taglibs.jsp"%>

<shell:title text="${l.l('Отчет')}"/>
<shell:state text="${l.l('Отчет Абонгруппы')}"/>

<div class="report center1020">
        <%--                                                                                                                                                                                         
            Переменная form - объект класса ru.bgcrm.struts.form.DynActionForm, содержащий параметры запроса.                                                                                        
        --%>                                                                                                                                                                                         
<%--         <c:set var="fromdate" value="${u:parseDate( form.param.fromdate, 'ymd' ) }"/>                                                                                                                 --%>
<%--         <c:set var="todate" value="${u:parseDate( form.param.todate, 'ymd' ) }"/>                                                                                                                     --%>

<!-- The form action must correspond with the @Action annotation in model? script -->
        <html:form action="/user/plugin/custom.smartkom/report/abon">
            ${l.l("Начало периода")}:
            <ui:date-time paramName="dateFrom" value="${form.param.dateFrom}"/>
            &nbsp;&nbsp;${l.l("Окончание периода")}:
            <ui:date-time paramName="dateTo" value="${form.param.dateTo}"/>
            
            <ui:button type="out" styleClass="ml1 mr1 more out" onclick="$$.ajax.load(this.form, $$.shell.$content(this))"/>
        </html:form>
        
        
    <div class="data mt1 w100p" style="overflow: auto;">
        <table class="data">
            <tr>
                <td>${l.l('Создано заявок \"Изменения в услуге\"')}</td>
                <td>${l.l('Закрыто заявок \"Изменения в услуге\" 2-ой линией')}</td>
                <td>${l.l('Отключения')}</td>
                <td>${l.l('Отключения 2-ой линией')}</td>
            </tr>
            
            <c:forEach var="r" items="${form.response.data.list}">
                <tr>
                    <td>${r.get('cnt_izm_created')}</td>
                    <td>${r.get('cnt_izm_closed')}</td>
                    <td>${r.get('cnt_otkl_created')}</td>
                    <td>${r.get('cnt_otkl_closed')}</td>
                </tr>
            </c:forEach>
            
        </table>
    
    </div>
        

</div>