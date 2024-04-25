package org.bgerp.plugin.custom.smartkom.imports;

import java.util.List;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

import org.bgerp.util.Log;

import org.bgerp.app.exception.BGException;
import org.bgerp.model.Pageable;
import org.bgerp.model.base.IdTitle;
import ru.bgcrm.model.user.User;
import ru.bgcrm.plugin.bgbilling.proto.dao.*;
import ru.bgcrm.plugin.bgbilling.proto.dao.ContractDAO.SearchOptions;
import ru.bgcrm.plugin.bgbilling.proto.model.Contract;
import ru.bgcrm.plugin.bgbilling.proto.dao.ContractHierarchyDAO;
import org.bgerp.app.cfg.Setup;

class BgbContracts {
    
    private static final Log logger = Log.getLog();
    private static final int CONTRAGENT_ID_BGB_PARAMETER_ID = Setup.getSetup().getInt("custom.smartkom.ContragentsImport.contragentId.billingParameterId");
    private static final Pattern SPECIAL_CHARS_PATTERN = Pattern.compile("([\\(\\)])");
    
    private User user;
    private ContractDAO conDao;
    private ContractParamDAO contractParameterDao;
	private ContractHierarchyDAO contractHierarchyDAO;
    
    public BgbContracts() throws BGException {
        String login = Setup.getSetup().get("custom.smartkom.ContragentsImport.billingLogin");
        String password = Setup.getSetup().get("custom.smartkom.ContragentsImport.billingPassword");
        String billingId = Setup.getSetup().get("custom.smartkom.ContragentsImport.billingId");
        
        this.user = new User(login, password);
        contractParameterDao = new ContractParamDAO(this.user, billingId);
//        conDao = new ContractDAO(this.user, billingId);
        conDao = ContractDAO.getInstance(this.user, billingId);
        contractHierarchyDAO = new ContractHierarchyDAO(this.user, billingId);
    }
    
    public Pageable<IdTitle> searchFor(String title) {
        
        Pageable<IdTitle> searchResult = new Pageable<>();
        String comment = "";

        try {
            SearchOptions searchOptions = new SearchOptions(false, false, false);
            this.conDao.searchContractByTitleComment(searchResult, 
                    escapeSpecialChars(title), 
                    comment, 
                    searchOptions);
            
        } catch (BGException e) {
            logger.error(e.getMessage(), e);
        }
        
        logger.info("Search result: '%s'", searchResult.getList().toString());
        return searchResult;
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

    public List<Contract> getSubcontracts(int contractId) throws BGException{
    	logger.info("SubIds: " + this.contractHierarchyDAO.getSubContracts(contractId).toString());
        List<Contract> subcontracts = this.contractHierarchyDAO.getSubContracts(contractId).stream()
        .map(x -> this.conDao.getContractById(x))
        .filter(x -> x != null)
        .collect(Collectors.toList());
        
        return subcontracts;
    }
    
    private String escapeSpecialChars(String str) {
        return SPECIAL_CHARS_PATTERN.matcher(str).replaceAll("\\\\$1");
    }
}
