package org.bgerp.plugin.custom.smartkom.imports;

import java.util.List;
import java.util.stream.Collectors;

import org.bgerp.util.Log;

import org.bgerp.app.exception.BGException;
import org.bgerp.model.base.IdTitle;

import ru.bgcrm.model.user.User;
import ru.bgcrm.plugin.bgbilling.proto.dao.*;
import ru.bgcrm.plugin.bgbilling.proto.dao.ContractHierarchyDAO;
import org.bgerp.app.cfg.Setup;

class BgbContracts {

    private static final Log logger = Log.getLog();
    private static final int CONTRAGENT_ID_BGB_PARAMETER_ID = Setup.getSetup().getInt("custom.smartkom.ContragentsImport.contragentId.billingParameterId");

    private User user;
    private CustomContractDAO conDao;
    private ContractParamDAO contractParameterDao;
    private ContractHierarchyDAO contractHierarchyDAO;

    public BgbContracts() throws BGException {
        String login = Setup.getSetup().get("custom.smartkom.ContragentsImport.billingLogin");
        String password = Setup.getSetup().get("custom.smartkom.ContragentsImport.billingPassword");
        String billingId = Setup.getSetup().get("custom.smartkom.ContragentsImport.billingId");

        this.user = new User(login, password);
        contractParameterDao = new ContractParamDAO(this.user, billingId);
        conDao = new CustomContractDAO(this.user, billingId);
        contractHierarchyDAO = new ContractHierarchyDAO(this.user, billingId);
    }
    
    IdTitle getContractIdTitleByTitle(String title) {
        return conDao.getContractIdTitleByTitle(title);
    }
    

    IdTitle getContractIdTitleById(int id) {
        return conDao.getContractIdTitleById(id);
    }

    public String getContractParam(int bgbContractId, int parameterId) throws BGException {
        return this.contractParameterDao.getTextParam(bgbContractId, parameterId);
    }

    public void updateContractTextParam(int contractId, int paramId, String value) throws BGException {
        this.contractParameterDao.updateTextParameter(contractId, paramId, value);
    }

    String getContractCustomerBacklink(int bgbContractId) throws BGException {
        return getContractParam(bgbContractId, CONTRAGENT_ID_BGB_PARAMETER_ID);
    }

    public void updateContractCustomerBacklink(int bgbContractId, String value) throws BGException {
        updateContractTextParam(bgbContractId, CONTRAGENT_ID_BGB_PARAMETER_ID, value);
    }

    public void updateContractListParam(int contractId, int paramId, int value) throws BGException {
        this.contractParameterDao.updateListParameter(contractId, paramId, value);
    }

    public List<IdTitle> getSubcontracts(int contractId) throws BGException {
        logger.info("SubIds: " + this.contractHierarchyDAO.getSubContracts(contractId).toString());
        List<IdTitle> subcontracts = this.contractHierarchyDAO.getSubContracts(contractId).stream()
                .map(x -> this.conDao.getContractIdTitleById(x))
                .filter(x -> x != null)
                .collect(Collectors.toList());

        return subcontracts;
    }
}
