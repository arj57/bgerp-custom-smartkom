package org.bgerp.plugin.custom.smartkom.imports;

import ru.bgcrm.dao.CustomerDAO;
import ru.bgcrm.dao.CustomerLinkDAO;
import ru.bgcrm.model.CommonObjectLink;
import ru.bgcrm.model.customer.Customer;
import ru.bgcrm.model.param.*;
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
	{

    private static final boolean REMOVE_FILE_AFTER_IMPORT = Setup.getSetup().getBoolean("custom.smartkom.ContragentsImport.removeFileAfterImport", false);
    private static final int CONTRAGENT_CONTACT_PERSON_ERP_PARAMETER_ID = Setup.getSetup().getInt("custom.smartkom.ContragentsImport.contragentContactPerson.erpParamemerId");
    private static final Path LOCK_FILE = Paths.get(System.getProperty("user.dir"), ".run", "importer.lock");
    private static final Path IMPORT_PATH = Paths.get(Setup.getSetup().get("custom.smartkom.contragentsImport.directory", "/var/bgerp"));
    private static final Log logger = Log.getLog();
    private static final java.util.regex.Pattern CONTRACT_TITLE_PATTERN = java.util.regex.Pattern
            .compile("Договор № ?([^ ]{1,50})");

    private final static Map<String, Integer> RELATIONSHIP_TO_ID = Map.of(
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
    
    private Connection con;
    private ParamValueDAO pvDao;
    private CustomerDAO custDao;
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
                    this.customerNode = nList.item(i).cloneNode(true); // for accelerating: https://habr.com/ru/articles/128175/
                    String inn = Utils.maskEmpty( XMLUtils.selectText(this.customerNode, "./@inn"), "");
                    logger.info("inn: '%s'", inn);
                    if (!InnChecker.isInnValid(inn)) {
                        String fullName = Utils.maskEmpty( XMLUtils.selectText(this.customerNode, "./@fullName"), "");
                        logger.warn("Некорректный ИНН: %s для контрагента %s. Пропускаем.", 
                                inn, fullName);
                        continue;
                    }
    
                    List<Integer> custIds = searchCustomersIdsByInn(inn);
                    if (custIds.size() == 0) { // Новый контрагент
                        logger.info("New inn: " + inn);
                        Customer customer = new Customer();
                        updateCustomerParameters(customer);
                    }
    
                    else if (custIds.size() == 1) { // обновляем для существующего
                        logger.info("Existent inn: " + inn);
                        Customer customer = this.custDao.getCustomerById(custIds.get(0));
                        logger.info("Customer id: " + customer.getId());
                        deleteCustomerParameters(customer);
                        updateCustomerParameters(customer);
                    }
    
                    else {
                        String fullName = Utils.maskEmpty( XMLUtils.selectText(this.customerNode, "./@fullName"), "");
                        logger.warn("Не уникальный ИНН: %s для контрагента %s. Такие же ИНН есть у контрагентов с Id %s. Пропускаем.",
                                inn, fullName, custIds.toString());
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
        String title = Utils.maskEmpty( XMLUtils.selectText(this.customerNode, "./@fullName"), "");
        customer.setTitle(title);
        customer.setParamGroupId(1);

//    customer Id еще равен 0
        new ru.bgcrm.dao.CustomerDAO(this.con).updateCustomer(customer);
//      Здесь уже реальный Id
        updateParamContactPersons(customer);

        updateParamText("./@id", 162, customer);
        updateParamText("./@fullName", 2, customer);
        updateParamText("./@diadoc", 57, customer);
        updateParamText("./@shortName", 1, customer);
        updateParamText("./@inn", 37, customer);
        updateParamText("./@kpp", 51, customer);
        updateParamText("./@holding", 55, customer);
        
        updateTechContact(customer);
        updateFinContact(customer);

        updateParamList("./@relationtype", 54, RELATIONSHIP_TO_ID, customer); // тип отношений
        updateParamList("./@importance", 56, IMPORTANCE_TO_ID, customer); // важность

        updateParamManagers(53, customer);
        updateParamEmail("@type='tech'", 11, customer);
        updateParamEmail("@type='doc'", 12, customer);
        updateParamPhones(6, customer);
        addBgbContractsLinks(customer);

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

    private void addBgbContractsLinks(Customer customer) throws XPathExpressionException, BGException, SQLException {
        
//      Удаляем устаревшие линки на договоры  для текущего контрагента
        customerLinkDAO.deleteLinksWithType(new CommonObjectLink("customer", customer.getId(), "contract:bgb", 0, ""));

//      Список договоров для текущего контрагента
        NodeList nList = XMLUtils.selectNodeList(this.customerNode, "./contracts/contract/@name");

        for (int i = 0; i < nList.getLength(); i++) {
            final String contractTitle = (String) nList.item(i).getTextContent().trim();

            if (!isTitleValid(contractTitle)) {
                logger.info("Contract title %s is invalid. Skipped.", contractTitle);
                continue;
            }

            logger.info("ConTitle from input: %s", contractTitle);
            IdTitle superContract = bgbcontracts.getContractIdTitleByTitle(contractTitle);
            
            if(superContract != null) {
                logger.info("Super IdTitle: %s", superContract == null ? "null" : superContract.toString());
                linkCustomerTo(superContract, customer);
//              updateBacklinkFrom(idt);
                for (IdTitle subcontract : bgbcontracts.getSubcontracts(superContract.getId())) {
                    if(subcontract != null) {
                        logger.info("Sub IdTitle: %s", subcontract == null ? "null" : subcontract.toString());
                        linkCustomerTo(subcontract, customer);
//                      updateBacklinkFrom(idt);
                    }
                }
            }
        }
    }

    private void linkCustomerTo(IdTitle contract, Customer customer) throws BGException {
        logger.info("Customer id %d linked to contractId = %d (%s)", 
                customer.getId(), contract.getId(), contract.getTitle());

        CommonObjectLink link = new CommonObjectLink("customer", customer.getId(), "contract:bgb",
                contract.getId(), contract.getTitle());

        // Привязываем к контрагенту договоры из биллинга
        customerLinkDAO.deleteLinksTo(link);
        customerLinkDAO.addLink(link);
    }

    private void updateParamText(String xPath, int paramId, Customer customer) throws XPathExpressionException, BGException, SQLException {
        updateParamText(this.customerNode, xPath, paramId, customer);
    }

    private void updateParamText(Node node, String xPath, int paramId, Customer customer) throws XPathExpressionException, BGException, SQLException {
        String val = Utils.maskEmpty( XMLUtils.selectText(node, xPath), "");
        if (! Utils.isEmptyString(val))
            this.pvDao.updateParamText(customer.getId(), paramId, val);
    }

    private void updateParamManagers(int paramId, Customer customer) throws DOMException, XPathExpressionException, BGException, SQLException {
        StringBuffer managers = new StringBuffer();

        NodeList nList1 = XMLUtils.selectNodeList(customerNode, "managers/manager[@type='main']/text()");

        if (nList1.getLength() > 0) {
            managers.append(nList1.item(0).getTextContent());
            managers.append(";");
        }

        pvDao.updateParamText(customer.getId(), paramId, managers.toString());
    }

    private void updateParamEmail(String emailAttr, int paramId, Customer customer)
            throws DOMException, XPathExpressionException, BGException, SQLException {
        
        final int insertModePosition = 0;
        NodeList nodes = XMLUtils.selectNodeList(this.customerNode, "contact/emails/email[" + emailAttr + "]/text()");

        for (int i = 0; i < nodes.getLength(); i++) {
            String str = nodes.item(i).getTextContent();
            pvDao.updateParamEmail(customer.getId(), paramId, insertModePosition, new ParameterEmailValue(str));
        }
    }

    private void updateParamPhones(int paramId, Customer customer) throws XPathExpressionException, BGException, SQLException {
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

//    private void updateBacklinkFrom(IdTitle bgbContract, Customer customer) throws BGException {
//        this.bgbcontracts.updateContractCustomerBacklink(bgbContract.getId(), String.valueOf(customer.getId()));
//    }

//    private void updateContractCounteragent(IdTitle bgbContract) throws XPathExpressionException, BGException {
//        String xpath = "./contracts/contract[@name='" + bgbContract.getTitle() + "']/@contragent2";
//        logger.info("xpath: " + xpath);
//
////        String strVal = Parser.unescapeEntities( getInputParam(xpath), true);
//        String strVal = getInputParam(xpath);
//        int val = CONTRAGENT_TO_ID.getOrDefault(strVal, -1);
//        logger.info("Contragent2: %s(%d)", strVal, val);
//
//        this.bgbcontracts.updateContractListParam(bgbContract.getId(), CONTRAGENT_ID_BGB_PARAMETER_ID, val);
//    }

    private void updateTechContact(Customer customer) throws XPathExpressionException, BGException, SQLException {
        final int TECH_CONTACT_PERSON_PARAM_ID = 7;
        final int TECH_CONTACT_EMAIL_PARAM_ID = 11;
        final int TECH_CONTACT_PHONE_PARAM_ID = 159;
        
        Node node = XMLUtils.selectNode(this.customerNode, "./contactPersons/person[role='Технические вопросы'][1]");
        updateParamText("./@name", TECH_CONTACT_PERSON_PARAM_ID, customer);
        updateEmailForContactPerson(node, TECH_CONTACT_EMAIL_PARAM_ID, customer);
        updatePhoneForContactPerson(node, TECH_CONTACT_PHONE_PARAM_ID, customer);
    }
    
    private void updateFinContact(Customer customer) throws XPathExpressionException, BGException, SQLException {
        final int FIN_CONTACT_PERSON_PARAM_ID = 161;
        final int FIN_CONTACT_EMAIL_PARAM_ID = 157;
        final int FIN_CONTACT_PHONE_PARAM_ID = 160;
        
        Node node = XMLUtils.selectNode(this.customerNode, "./contactPersons/person[role='Финансовые вопросы'][1]");
        updateParamText("./@name", FIN_CONTACT_PERSON_PARAM_ID, customer);
        updateEmailForContactPerson(node, FIN_CONTACT_EMAIL_PARAM_ID, customer);
        updatePhoneForContactPerson(node, FIN_CONTACT_PHONE_PARAM_ID, customer);
    }
    
    private void updatePhoneForContactPerson(Node personNode, int paramId, Customer customer) throws SQLException {
        ParameterPhoneValue phones = new ParameterPhoneValue();

        String strPhone = Utils.maskEmpty( XMLUtils.selectText(personNode, "./phones/phone[1]"), "");
        strPhone = normalizePhoneNumber(strPhone);
        ParameterPhoneValueItem item = new ParameterPhoneValueItem(strPhone, "");
        phones.addItem(item);
        pvDao.updateParamPhone(customer.getId(), paramId, phones);
    }

    private void updateEmailForContactPerson(Node personNode, int paramId, Customer customer) throws SQLException {
        String val = Utils.maskEmpty( XMLUtils.selectText(personNode, "./emails/email[1]"), "");
        pvDao.updateParamEmail(customer.getId(), paramId, 0, new ParameterEmailValue(val));
        
    }

    private void updateParamContactPersons(Customer customer)
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
        this.pvDao.updateParamBlob(customer.getId(), CONTRAGENT_CONTACT_PERSON_ERP_PARAMETER_ID,
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
    private boolean updateParamList(String xPath, int paramId, Map<String, Integer> val2id, Customer customer)
            throws XPathExpressionException, BGException, SQLException {
        boolean res = false;
        String strVal = Utils.maskEmpty( XMLUtils.selectText(this.customerNode, xPath), "");
        int val = val2id.getOrDefault(strVal, -1);
        logger.info("CustomerId: %d xPath: %s Value: %s Val.Id: %d", customer.getId(), xPath, strVal, val);

        if (strVal != "" && val > 0) {
            this.pvDao.updateParamList(customer.getId(), paramId, new HashSet<Integer>(Arrays.asList(val)));
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

