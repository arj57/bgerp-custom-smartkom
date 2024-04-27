package org.bgerp.plugin.custom.smartkom.imports;

import org.bgerp.model.base.IdTitle;
//import org.json.JSONObject;

import com.fasterxml.jackson.databind.JsonNode;

import ru.bgcrm.model.user.User;
import ru.bgcrm.plugin.bgbilling.RequestJsonRpc;
import ru.bgcrm.plugin.bgbilling.proto.dao.ContractDAO;
//import ru.bgcrm.plugin.bgbilling.proto.dao.version.v8x.ContractDAO8x;

public class CustomContractDAO extends ContractDAO {

    protected CustomContractDAO(User user, String billingId) {
        super(user, billingId);
    }

    public static CustomContractDAO getInstance(User user, String billingId) {
        return new CustomContractDAO(user, billingId);
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
        
        JsonNode res = transferData.postData(req, user);
        res = res.path("return");
//        JSONObject jo = new JSONObject("{\"id\":21739,\"title\":\"100978\"}"); // работает
//        String res = "{\"id\":21739,\"title\":\"100978\",\"groups\":256,\"password\":\"672678\",\"dateFrom\":\"2018-03-27\",\"dateTo\":null,\"balanceMode\":0,\"paramGroupId\":1,\"personType\":1,\"comment\":\"ПАО АКБ \\\"АВАНГАРД\\\"\",\"hidden\":false,\"superCid\":-1,\"dependSubList\":\"21740,21741,21807,21808,21809,21810,21811,21812,21813,21814,21815,21816,21817,21818,21820,21821,21822,21823,23047,23362,23653,23731,23733,23774,23939,24100,25316,27447,28610,29090,29600,29818\",\"status\":0,\"statusTimeChange\":\"2018-03-27\",\"titlePatternId\":1,\"balanceSubMode\":0,\"domainId\":0,\"super\":true,\"dependSub\":false,\"balanceLimit\":0.00,\"sub\":false,\"independSub\":false}";
//        JSONObject contract = jsonMapper.convertValue(res, JSONObject.class); // null :((
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
