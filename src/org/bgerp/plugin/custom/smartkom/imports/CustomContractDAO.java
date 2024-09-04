package org.bgerp.plugin.custom.smartkom.imports;

import org.bgerp.model.base.IdTitle;

import com.fasterxml.jackson.databind.JsonNode;

import ru.bgcrm.model.user.User;
import ru.bgcrm.plugin.bgbilling.RequestJsonRpc;
import ru.bgcrm.plugin.bgbilling.proto.dao.ContractDAO;


/*
Примерный URL запроса:

http://127.0.0.1:8080/bgbilling/executer/json/ru.bitel.bgbilling.kernel.contract.api/ContractService
   {"method" : "contractList",
   "user" :{ "user" : "shamil", "pswd" : "xxxx" },
   "params" : {
   "title" : "0",
   "fc" : -1,
   "groupMask" : 0,
   "subContracts" : false,
   "closed" : true,
   "hidden" : false,
   "page" : { "pageIndex" : 2, "pageSize" : 2 }
   } }

Примерный ответ:

{"status":"ok","message":"",
   "data":
   {
    "page":{"pageSize":2,"pageIndex":2,"pageCount":49,"recordCount":97,"pageFirstRecordNumber":2},
    "return":
    [{"id":353023,"title":"0022010","groups":0,"password":"bg2rFZ2PEX","dateFrom":"2010-01-02","dateTo":null,"balanceMode":0,"paramGroupId":14,"personType":0,"comment":"","hidden":false,"superCid":0,"dependSubList":"","status":0,"statusTimeChange":"2010-01-13","titlePatternId":0,"balanceSubMode":0,"sub":false,"independSub":false,"balanceLimit":0.00,"super":false,"dependSub":false},
    {"id":353209,"title":"06-10-10/И-Г/0","groups":0,"password":"9351220759","dateFrom":"2010-10-06","dateTo":null,"balanceMode":1,"paramGroupId":14,"personType":0,"comment":"","hidden":false,"superCid":0,"dependSubList":"","status":0,"statusTimeChange":"2010-10-06","titlePatternId":0,"balanceSubMode":0,"sub":false,"independSub":false,"balanceLimit":0.00,"super":false,"dependSub":false}]}}

Примеры.

Преобразование в тип:
 TypeTreeItem childItem = jsonMapper.convertValue(transferData.postDataReturn(req, user), TypeTreeItem.class);

Получение как List:
 readJsonValue(transferData.postDataReturn(req, user).traverse(),
                jsonTypeFactory.constructCollectionType( List.class, IdTitle.class ) )

Ссылки:
 http://www.bgbilling.ru/v6.1/doc/ch02s08.html
 http://wiki.fasterxml.com/JacksonInFiveMinutes

*/

public class CustomContractDAO extends ContractDAO {

    public CustomContractDAO(User user, String billingId) {
        super(user, billingId);
    }

/*
    TransferData - https://billing.smartkom.ru:7443/bgbilling/executer/json/ru.bitel.bgbilling.kernel.contract.api/ContractService
    TransferData - {"method":"contractByTitle","user":{"user":"importer","pswd":"FmT"},"params":{"contractTitle":"100978"}}
    TransferData - [ length = 672 ] JSON = {"status":"ok","exception":null,"message":"","tag":null,"data":{"return":{"id":21739,"title":"100978","groups":256,"password":"672678","dateFrom":"2018-03-27","dateTo":null,"balanceMode":0,"paramGroupId":1,"personType":1,"comment":"ПАО АКБ \"АВАНГАРД\"","hidden":false,"superCid":-1,"dependSubList":"21740,21741,21807,21808,21809,21810,21811,21812,21813,21814,21815,21816,21817,21818,21820,21821,21822,21823,23047,23362,23653,23731,23733,23774,23939,24100,25316,27447,28610,29090,29600,29818","status":0,"statusTimeChange":"2018-03-27","titlePatternId":1,"balanceSubMode":0,"domainId":0,"super":true,"dependSub":false,"balanceLimit":0.00,"sub":false,"independSub":false}}}
*/
    public IdTitle getContractIdTitleByTitle(String title) {
        IdTitle result = null;
        RequestJsonRpc req = new RequestJsonRpc(KERNEL_CONTRACT_API, "ContractService", "contractByTitle");
        req.setParam("contractTitle", title);
        
        JsonNode res = transferData.postDataReturn(req, user);
        JsonNode titleNode = res.get("title");
        if (titleNode != null) {
            int id = res.get("id").asInt();
            result = new IdTitle(id, title);
        }
        return result;
    }
    
    public IdTitle getContractIdTitleById(int contractId) {
        IdTitle result = null;
        RequestJsonRpc req = new RequestJsonRpc(KERNEL_CONTRACT_API, "ContractService", "contractGet");
        req.setParam("contractId", contractId);

        JsonNode res = transferData.postDataReturn(req, user);
        JsonNode idNode = res.get("id");
        if (idNode != null) {
            String t = res.get("title").asText();
            result = new IdTitle(contractId, t);
        }
        
        return result;
    }
}
