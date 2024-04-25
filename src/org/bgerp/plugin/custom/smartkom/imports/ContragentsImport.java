package org.bgerp.plugin.custom.smartkom.imports;

import ru.bgcrm.dao.CustomerDAO;
import ru.bgcrm.dao.CustomerLinkDAO;
import ru.bgcrm.model.CommonObjectLink;
import ru.bgcrm.model.customer.Customer;
import ru.bgcrm.model.param.*;
import ru.bgcrm.plugin.bgbilling.proto.model.Contract;
import ru.bgcrm.util.Utils;
import ru.bgcrm.util.sql.SQLUtils;
import ru.bgcrm.util.XMLUtils;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.channels.FileChannel;
import java.nio.channels.FileLock;
import java.nio.channels.OverlappingFileLockException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.*;
import java.util.regex.Matcher;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import javax.xml.xpath.*;

import org.bgerp.app.cfg.ConfigMap;
import org.bgerp.app.cfg.Setup;
import org.bgerp.app.exception.BGException;
import org.bgerp.dao.param.ParamValueDAO;
import org.bgerp.model.base.IdTitle;
import org.bgerp.plugin.kernel.Plugin;
import org.bgerp.util.Log;
import org.bgerp.app.exec.scheduler.Task;
import org.w3c.dom.*;

/**
 * Скрипт импортирует информацию из 1С о контрагентах из .xml-файлов, которые
 * должны находиться в общей папке <IMPORT_PATH>, например, быть загружены по FTP. 
 * За один запуск импортируется один, самый новый файл. 
 * После импорта из каталога <IMPORT_PATH> удаляются все файлы. 
 * 
 * Путь для каталога, куда загружать .xml-файлы для импорта, 
 * указывается в конфиге bgerp, параметр import.directory: 
 * Например: import.directory=/var/bgerp
 * Для каталога:
 * Владелец /var/bgerp: ftp
 * Группа:  bgerp
 * Права: rwxrwsr-x
 * 
 * Также скрипт добавляет в указанный параметр договора биллинга Id контрвгента из BGERP. 
 * В конфиге необходимо указать параметры:
 *  custom.smartkom.contragentsImport.billingLogin - логин для подключения к биллингу
 *  custom.smartkom.contragentsImport.billingPassword - пароль для подключения к биллингу
 *  custom.smartkom.contragentsImport.billingId - Id биллинга
 *  
 *  custom.smartkom.ContragentsImport.contragentId.billingParameterId - параметр: Id контрагента
 *  custom.smartkom.ContragentsImport.payeeId.billingParameterId -  параметр: Получатель платежей
 *  custom.smartkom.ContragentsImport.contragentContactPerson.erpParamemerId - параметр: Контактное лицо
 *  
 *  custom.smartkom.contragentsImport.directory - каталог, где скрипт ищет файлы с импортируемыми данными ( по умолчанию - /var/bgerp)
 *   владелец - ftp
 *   группа - bgerp
 *   права доступа - rwxrwxr-x
 * 
 * @author alex 2019-08-26
 */
public class ContragentsImport extends Task
//	implements org.bgerp.app.exec.Runnable 
	{

    private static final boolean ALLOW_UPDATE_BILLING_PARAMETERS = Setup.getSetup().getBoolean("custom.smartkom.ContragentsImport.allowUpdateBillingParameters", false);
    private static final boolean REMOVE_FILE_AFTER_IMPORT = Setup.getSetup().getBoolean("custom.smartkom.ContragentsImport.removeFileAfterImport", false);
    private static final int CONTRAGENT_ID_BGB_PARAMETER_ID = Setup.getSetup().getInt("custom.smartkom.ContragentsImport.contragentId.billingParameterId");
    private static final int PAYEE_ID_BGB_PARAMETER_ID = Setup.getSetup().getInt("custom.smartkom.ContragentsImport.payeeId.billingParameterId"); // Параметр договора: Получатель платежей
    private static final int CONTRAGENT_CONTACT_PERSON_ERP_PARAMETER_ID = Setup.getSetup().getInt("custom.smartkom.ContragentsImport.contragentContactPerson.erpParamemerId");
    private static final Path LOCK_FILE = Paths.get(System.getProperty("user.dir"), ".run", "importer.lock");
    private static final Path IMPORT_PATH = Paths.get(Setup.getSetup().get("custom.smartkom.contragentsImport.directory", "/var/bgerp"));
    private static final Log logger = Log.getLog();
    private static final java.util.regex.Pattern CONTRACT_TITLE_PATTERN = java.util.regex.Pattern
            .compile("Договор № ?([^ ]{1,50})");

    private final static Map<String, Integer> relationship2id = Map.of(
            "Оператор", 1, 
            "Покупатель", 2, 
            "Покупатель/Поставщик", 3, 
            "Поставщик", 4, 
            "Собственник (ТСЖ, УК, т.п.)", 6, 
            "Сотрудник", 7, 
            "Свои", 5);
    
    private final static Map<String, Integer> IMPORTANCE_TO_ID = Map.of(
            " VIP", 1, 
            "A - класс", 2, 
            "B - класс", 3, 
            "C - класс", 4);
    
//  Элементы списка. Списочный параметр в биллинге
    private final static Map<String, Integer> CONTRAGENT_TO_ID = Map.of(
            "ООО \"Матрикснет\"", 21, 
            "ЗАО \"Смартком\"", 20);
    
//  Элементы списка. Списочный параметр в биллинге
    private final static Map<String, Integer> PAYEE_TO_ID = Map.of(
            "ООО \"Матрикснет\"", 13, 
            "ЗАО \"Смартком\"", 14);

    private Connection con;
    private ParamValueDAO pvDao;
    private CustomerDAO custDao;
    private Customer customer;
    private Node customerNode;
    private CustomerLinkDAO customerLinkDAO;
    private BgbContracts bgbcontracts; // = new BgbContracts();

    public ContragentsImport(ConfigMap config) {
        super(null);
    }
    
    @Override
    public String getTitle() {
        return Plugin.INSTANCE.getLocalizer().l("Smartkom Contragents import");
    }

    public void run() {

        logger.info("***** Trying to start import *****");
        try (final RandomAccessFile randomAccessFile = new RandomAccessFile(LOCK_FILE.toString(), "rw");
                final FileChannel fileChannel = randomAccessFile.getChannel();
                final FileLock fileLock = fileChannel.tryLock();) {

            checkSourcePathPermissions(IMPORT_PATH);
            if (fileLock != null) {
                logger.info("Import started \"" + getContragentsFileNames(IMPORT_PATH) + "\"");
                // Trying to process the newest .xml file only
                List<Path> paths = getContragentsFileNames(IMPORT_PATH);
                if (!paths.isEmpty()) {
                    Path path = paths.get(0);
                    logger.info("Trying from '%s'...", path.toString());
                    doImport(path.toString());
                }

                if(REMOVE_FILE_AFTER_IMPORT) {
                	clearDirectory(IMPORT_PATH);
                }
            }
        } 
        
        catch (OverlappingFileLockException e) {
            logger.warn("Import process is running now. Please try later.");
        }

        catch (IOException e) {
            logger.error(e.getMessage(), e);
        }

        catch (BGException e1) {
            logger.error(e1.getMessage(), e1);
        }

        finally {
            logger.info("***** Import finished *****");
            try {
                Files.deleteIfExists(LOCK_FILE);
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }
    
    private void checkSourcePathPermissions(Path importPath) throws BGException{
        if( !(Files.exists(importPath) && Files.isDirectory(importPath))) {
            throw new BGException("Not such directory: \"" + importPath + "\"");
        }
        
        if ( ! (Files.isReadable(importPath) && 
                Files.isWritable(importPath) && 
                Files.isExecutable(importPath))) {
            throw new BGException("Not full permissions for directory: \"" + importPath + "\"");
        }
        
    }

    private List<Path> getContragentsFileNames(Path importPath) throws IOException {
        List<Path> fileNames = null;

        try (Stream<Path> paths = Files.walk(importPath)) {
            fileNames = paths
                    .filter(Files::isRegularFile)
                    .filter(s -> s.toString().endsWith(".xml"))
                    .sorted(( f1, f2 ) -> compareLastModTime( f2, f1 ))  // reverse order
                    .collect(Collectors.toList());
        } 
        return fileNames;
    }

    private void doImport(String fileName) throws BGException {

        Document document = null;
        try {
            this.con = Setup.getSetup().getDBConnectionFromPool();

            document = XMLUtils.parseDocument(new FileInputStream(fileName));
            if(document != null) {
                this.pvDao = new ParamValueDAO(this.con);
                this.custDao = new CustomerDAO(this.con);
                this.customerLinkDAO = new CustomerLinkDAO(this.con);
                this.bgbcontracts = new BgbContracts();
    
                Node root = document.getDocumentElement();
                NodeList nList = XMLUtils.selectNodeList(root, "contragent");
    
                for (int i = 0; i < nList.getLength(); i++) {
                    this.customerNode = nList.item(i);
                    String inn = getInputParam("./@inn");
                    logger.info("inn: '%s'", inn);
                    if (!InnChecker.isInnValid(inn)) {
                        logger.warn("Некорректный ИНН: %s для контрагента %s. Пропускаем.", 
                                inn, getInputParam("./@fullName"));
                        continue;
                    }
    
                    List<Integer> custIds = searchCustomersIdsByInn(inn);
                    if (custIds.size() == 0) { // Новый контрагент
                        logger.info("New inn: " + inn);
                        this.customer = new Customer();
                        updateCustomerParameters(this.customer);
                    }
    
                    else if (custIds.size() == 1) { // обновляем для существующего
                        logger.info("Existent inn: " + inn);
                        this.customer = this.custDao.getCustomerById(custIds.get(0));
                        logger.info("Customer id: " + this.customer.getId());
                        deleteCustomerParameters(this.customer);
                        updateCustomerParameters(this.customer);
                    }
    
                    else {
                        logger.warn("Не уникальный ИНН: %s для контрагента %s. Такие же ИНН есть у контрагентов с Id %s. Пропускаем.",
                                inn, getInputParam("./@fullName"), custIds.toString());
                        continue;
                    }
                }
            } else {
//                logger.error("Cannot parse XML document");
                throw new BGException("Cannot parse XML document from '" + fileName + "'");
            }
        } catch (BGException | XPathExpressionException | SQLException | FileNotFoundException e) {
            throw new BGException(e);
        } finally {
            SQLUtils.closeConnection(this.con);
        }
    }

    private void deleteCustomerParameters(Customer customer) throws SQLException {
        pvDao.deleteParams("customer", customer.getId());
    }

    private void updateCustomerParameters(Customer customer)
            throws SQLException, XPathExpressionException, BGException {
        customer.setTitle(getInputParam("./@fullName"));
        customer.setParamGroupId(1);

//    customer Id еще равен 0
        new ru.bgcrm.dao.CustomerDAO(this.con).updateCustomer(customer);
//      Здесь уже реальный Id
        updateParamContactPersons(null, null);

        updateParamText("./@fullName", 2);
        updateParamText("./@diadoc", 57);
        updateParamText("./@shortName", 1);
        updateParamText("./@inn", 37);
        updateParamText("./@kpp", 51);
        updateParamText("./@holding", 55);

        updateParamList("./@relationtype", 54, relationship2id); // тип отношений
        updateParamList("./@importance", 56, IMPORTANCE_TO_ID); // важность

        updateParamManagers(53);
        updateParamEmail("@type='tech'", 11);
        updateParamEmail("@type='doc'", 12);
        updateParamPhones(6);
        addBgbContractsLinks();

        SQLUtils.commitConnection(this.con);

    }

    private List<Integer> searchCustomersIdsByInn(String inn) throws SQLException {
        final int innPid = 37;

        final String qSel = "SELECT id FROM param_text WHERE param_id = ? AND value = ?";

        List<Integer> res = new ArrayList<>();
        try (PreparedStatement ps = this.con.prepareStatement(qSel)) {
            ps.setInt(1, innPid);
            ps.setString(2, inn);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                res.add(rs.getInt("id"));
            }
        }
        return res;
    }

    private void addBgbContractsLinks() throws XPathExpressionException, BGException, SQLException {
        
        final String contractTitleAndCommentDelimiter = " \\[";
//      Удаляем устаревшие линки на договоры  для текущего контрагента
        customerLinkDAO
                .deleteLinksWithType(new CommonObjectLink("customer", this.customer.getId(), "contract:bgb", 0, ""));

//      Список договоров для текущего контрагента
        NodeList nList = XMLUtils.selectNodeList(this.customerNode, "./contracts/contract/@name");

        for (int i = 0; i < nList.getLength(); i++) {
            final String contractTitle = (String) nList.item(i).getTextContent().trim();

            if (!isTitleValid(contractTitle)) {
                logger.info("Contract title %s is invalid. Skipped.", contractTitle);
                continue;
            }

            logger.info("ConTitle from input: %s", contractTitle);
            List<IdTitle> customerSuperContracts = bgbcontracts.searchFor(contractTitle)
                    .getList().stream()
                    .filter(idt -> idt.getTitle().trim().split( contractTitleAndCommentDelimiter )[0].equals(contractTitle))
                    .collect(Collectors.toList());

            logger.info("customerSuperContracts: " + customerSuperContracts);
            
            if (customerSuperContracts.size() == 1) {
                String backlink = bgbcontracts.getContractCustomerBacklink(customerSuperContracts.get(0).getId());
                logger.info("Existent backlink: \"%s\"", backlink);
                
                if( backlink != null && (backlink.isEmpty() || Integer.valueOf(backlink) == this.customer.getId())) {
                    linkCustomerTo(customerSuperContracts.get(0));
                    if(ALLOW_UPDATE_BILLING_PARAMETERS) {
                        updateBacklinkFrom(customerSuperContracts.get(0));
                        updateContractCounteragent( customerSuperContracts.get(0));
                        updateContractPayeeParameter( customerSuperContracts.get(0));
                    }

                    List<Contract> subs = bgbcontracts.getSubcontracts(customerSuperContracts.get(0).getId());
                    logger.info("subs:" + subs.size() + " ::: " + subs.toString());
                    
                    for (Contract subcontract : bgbcontracts.getSubcontracts(customerSuperContracts.get(0).getId())) {
                        IdTitle idt = new IdTitle(subcontract.getId(), subcontract.getTitle());
                        linkCustomerTo(idt);
                        if(ALLOW_UPDATE_BILLING_PARAMETERS) {
                            updateBacklinkFrom(idt);
                            updateContractCounteragent(idt);
                        }
                    }
                }
                else {
                    logger.warn("Договор %s уже привязан к контрагенту с id %s. Пропускаем привязку.", 
                            contractTitle, backlink);
                }
            } else if (customerSuperContracts.size() > 1) {
                logger.warn("Найдено более одного договора с номером, похожим на '%s'", contractTitle);
            }
        }
    }

    private void linkCustomerTo(IdTitle customerContract) throws BGException {
        logger.info("Customer id %d linked to contractId = %d (%s)", 
                this.customer.getId(), customerContract.getId(), customerContract.getTitle());

        CommonObjectLink link = new CommonObjectLink("customer", this.customer.getId(), "contract:bgb",
                customerContract.getId(), customerContract.getTitle());

        // Привязываем к контрагенту договоры из биллинга
        customerLinkDAO.deleteLinksTo(link);
        customerLinkDAO.addLink(link);
    }

    private void updateParamText(String xPath, int paramId) throws XPathExpressionException, BGException, SQLException {
        String val = getInputParam(xPath);
        if (! Utils.isEmptyString(val))
            this.pvDao.updateParamText(this.customer.getId(), paramId, val);
    }

    private void updateParamManagers(int paramId) throws DOMException, XPathExpressionException, BGException, SQLException {
        StringBuffer managers = new StringBuffer();

        NodeList nList1 = XMLUtils.selectNodeList(customerNode, "managers/manager[@type='main']/text()");

        if (nList1.getLength() > 0) {
            managers.append(nList1.item(0).getTextContent());
            managers.append(";");
        }

        pvDao.updateParamText(customer.getId(), paramId, managers.toString());
    }

    private void updateParamEmail(String emailAttr, int paramId)
            throws DOMException, XPathExpressionException, BGException, SQLException {
        
        final int insertModePosition = 0;
        NodeList nodes = XMLUtils.selectNodeList(this.customerNode, "contact/emails/email[" + emailAttr + "]/text()");

        for (int i = 0; i < nodes.getLength(); i++) {
            String str = nodes.item(i).getTextContent();
            pvDao.updateParamEmail(customer.getId(), paramId, insertModePosition, new ParameterEmailValue(str));
        }
    }

    private void updateParamPhones(int paramId) throws XPathExpressionException, BGException, SQLException {
        ParameterPhoneValue phones = new ParameterPhoneValue();

        NodeList nodes = XMLUtils.selectNodeList(this.customerNode, "contact/phones/phone/text()");

        if (nodes.getLength() > 0) {
            for (int i = 0; i < nodes.getLength(); i++) {
                String strPhone = normalizePhoneNumber(nodes.item(i).getTextContent());
//              logger.info("Phone: " + strPhone);
                ParameterPhoneValueItem item = new ParameterPhoneValueItem(strPhone, "");
                phones.addItem(item);
            }
            pvDao.updateParamPhone(customer.getId(), paramId, phones);
        }
    }

    private void updateBacklinkFrom(IdTitle bgbContract) throws BGException {
        this.bgbcontracts.updateContractCustomerBacklink(bgbContract.getId(), String.valueOf(this.customer.getId()));
    }

    private void updateContractCounteragent(IdTitle bgbContract) throws XPathExpressionException, BGException {
        String xpath = "./contracts/contract[@name='" + bgbContract.getTitle() + "']/@contragent2";
        logger.info("xpath: " + xpath);

//        String strVal = Parser.unescapeEntities( getInputParam(xpath), true);
        String strVal = getInputParam(xpath);
        int val = CONTRAGENT_TO_ID.getOrDefault(strVal, -1);
        logger.info("Contragent2: %s(%d)", strVal, val);

        this.bgbcontracts.updateContractListParam(bgbContract.getId(), CONTRAGENT_ID_BGB_PARAMETER_ID, val);
    }

    private void updateContractPayeeParameter(IdTitle bgbContract) throws XPathExpressionException, BGException {
        final String contractTitleAndCommentDelimiter = " \\[";
        String xpath = "./contracts/contract[@name='" + bgbContract.getTitle().split( contractTitleAndCommentDelimiter )[0] + "']/@contragent2";
        logger.info("xpath: " + xpath);

//        String strVal = Parser.unescapeEntities( getInputParam(xpath), true);
        String strVal = getInputParam(xpath);
        int val = PAYEE_TO_ID.getOrDefault(strVal, -1);
        logger.info("Payee: %s(%d)", strVal, val);

        this.bgbcontracts.updateContractListParam(bgbContract.getId(), PAYEE_ID_BGB_PARAMETER_ID, val);
    }

    private void updateParamContactPersons(Element node, String dataXpath)
            throws XPathExpressionException, BGException, SQLException {
        /*
         * Имя: <name>, должность: <office>, роль: <role>, email: <email>,
         * тел.[раб|моб/дом]: <phone[@work]> Для каждого контактного лица - отдельная
         * строка
         */
        NodeList nList1 = XMLUtils.selectNodeList(this.customerNode, "./contactPersons/person");

        StringBuffer allPersonsData = new StringBuffer();
        for (int i = 0; i < nList1.getLength(); i++) {
//          контекст: person
            StringBuffer singlePersonData = new StringBuffer();
            Element personNode = (Element) nList1.item(i);
            String name = XMLUtils.selectText(personNode, "./@name");

            singlePersonData.append("Контактное лицо: ");
            singlePersonData.append(name.trim());
            singlePersonData.append(" (");
            singlePersonData.append("ДОЛЖ: ");
            singlePersonData.append(getPersonData(personNode, "./office"));
            singlePersonData.append(" РОЛИ: ");
            singlePersonData.append(getPersonData(personNode, "./role"));
            singlePersonData.append("ТЕЛ: ");
            singlePersonData.append(getPersonData(personNode, "./phones/phone"));
            singlePersonData.append("EMAIL: ");
            singlePersonData.append(getPersonData(personNode, "./emails/email"));
            singlePersonData.append(")");

            allPersonsData.append(singlePersonData);
            allPersonsData.append("\n");
        }

        logger.info("Persons data: " + allPersonsData.toString());
        this.pvDao.updateParamBlob(this.customer.getId(), CONTRAGENT_CONTACT_PERSON_ERP_PARAMETER_ID,
                allPersonsData.toString());

    }

    private StringBuffer getPersonData(Element contextNode, String dataXpath) throws XPathExpressionException {
        NodeList nList1 = XMLUtils.selectNodeList(contextNode, dataXpath);
        StringBuffer sb = new StringBuffer();
        for (int i = 0; i < nList1.getLength(); i++) {
            sb.append(nList1.item(i).getTextContent().trim());
            if (sb.length() > 0)
                sb.append("; ");
        }
        if (sb.length() == 0)
            sb.append("не указано; ");
        return sb;
    }

    private String normalizePhoneNumber(String phNumber) {
        logger.info("Ph number before normalized: " + phNumber);
        phNumber = phNumber.replaceAll("[^0-9]", "");

        if (phNumber.length() == 6) {
            phNumber = "73812" + phNumber;
        } else if (phNumber.length() == 10) {
            phNumber = "7" + phNumber;
        } else if (phNumber.length() == 11 && phNumber.startsWith("8")) {
            phNumber = phNumber.replaceFirst("8", "7");
        }

        return phNumber;
    }

    private String getInputParam(String xPath) throws XPathExpressionException {
        return Utils.maskEmpty( XMLUtils.selectText(this.customerNode, xPath), "");
    }

    /**
     * Сохраняет параметр типа List, если у него валидное значение
     * 
     * @param xPath   - xPath-выражение для выборки значений с заданным атрибутом
     * @param paramId - какой параметр сохранять
     * @param val2id  - трансляция строкового значения атрибута в Id
     * @throws XPathExpressionException
     * @throws BGException
     * @throws SQLException 
     */
    private boolean updateParamList(String xPath, int paramId, Map<String, Integer> val2id)
            throws XPathExpressionException, BGException, SQLException {
        boolean res = false;
        String strVal = getInputParam(xPath);
        int val = val2id.getOrDefault(strVal, -1);
        logger.info("CustomerId: %d xPath: %s Value: %s Val.Id: %d", this.customer.getId(), xPath, strVal, val);

        if (strVal != "" && val > 0) {
            this.pvDao.updateParamList(this.customer.getId(), paramId, new HashSet<Integer>(Arrays.asList(val)));
            res = true;
        }
        return res;
    }

    String normalizeContractTitle(String title) {
        Matcher m = CONTRACT_TITLE_PATTERN.matcher(title);
        if (m.find()) {
            return m.group(1);
        } else
            return title;
    }

    private boolean isTitleValid(String title) {
        return !title.contains("№");
    }

    private int compareLastModTime(Path f1, Path f2) {
        try {
            return Files.getLastModifiedTime(f1).compareTo(Files.getLastModifiedTime(f2));
        } catch (IOException e) {
            return 0;
        }
    }

    private void clearDirectory(Path path) throws IOException {
        try (Stream<Path> paths = Files.walk( path )) {
            paths
            .filter(x -> x.compareTo(path) != 0)
            .map(Path::toFile)
            .forEach(File::delete);
        } 
        logger.info("Directory '%s' is cleaned.", path.toString());
    }

}

