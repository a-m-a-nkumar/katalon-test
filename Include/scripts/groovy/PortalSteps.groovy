// =====================================================================
// PortalSteps.groovy — universal Cucumber step definitions for Katalon
//
// Drop into:  Include/scripts/groovy/PortalSteps.groovy
//
// ⚠ DO NOT keep a SECOND .groovy file with @Given/@When/@Then
//   annotations in Include/scripts/groovy/. Katalon loads every
//   .groovy file there; if a previous Katalon-AI-generated step file
//   is still present, Cucumber reports "Duplicate step definitions"
//   because the same step text appears in two classes. Delete any
//   other step files before placing this one.
//
// Cucumber-jvm 7.x (Katalon Studio 10.x). Cucumber expressions only —
// no regex, no synonyms that overlap. Each annotation text below is
// UNIQUE so the file cannot itself produce a duplicate-step error.
//
// Phrasings supported (selected highlights):
//   Setup ─ "the portal is running at {string}", "the portal API is
//           running at {string}", "all projects have been reset via
//           {string}", "I navigate to the portal at {string}",
//           "I am on the wizard view", and the long-form aliases
//   HTTP ─ GET, POST-with-body, POST-with-no-body, DELETE; the URL
//          and body both substitute {storedName} placeholders
//   JSON ─ status, content-type (3 phrasings), top-level key, array
//          length (exact/at-least), array contains/NOT contains,
//          object-in-array contains, dotted/indexed field paths
//          ("member.role", "projects[0].project_name"), UUID v4
//          regex match, stored-value comparison
//   UI  ─ existence by data-testid (4 element-type phrasings),
//         visibility (is/should-be/not), disabled (is/should-be/not),
//         text contains/equals/matches pattern, CSS class on id,
//         select option by value or text, placeholder-only check,
//         click/type/select/select-blank actions
// =====================================================================

import io.cucumber.java.en.Given
import io.cucumber.java.en.When
import io.cucumber.java.en.Then
import io.cucumber.java.Before
import io.cucumber.java.After

import groovy.json.JsonSlurper

import java.net.HttpURLConnection
import java.net.URL
import java.util.regex.Pattern

import org.openqa.selenium.By
import org.openqa.selenium.WebDriver
import org.openqa.selenium.WebElement
import org.openqa.selenium.support.ui.Select

import com.kms.katalon.core.webui.driver.DriverFactory
import com.kms.katalon.core.webui.keyword.WebUiBuiltInKeywords as WebUI

import static org.junit.Assert.*

class PortalSteps {

    // ─── Scenario-scoped state (instance fields, reset via @Before)

    String baseUrl = "http://localhost:8000"
    int lastStatus = 0
    Map<String, List<String>> lastHeaders = [:]
    String lastBody = ""
    Map<String, String> storedResponses = [:]
    Map<String, String> storedVars = [:]
    boolean browserOpen = false

    @Before
    void resetState() {
        lastStatus = 0
        lastBody = ""
        lastHeaders = [:]
        storedResponses = [:]
        storedVars = [:]
    }

    @After
    void closeBrowserIfOpen() {
        if (browserOpen) {
            try { WebUI.closeBrowser() } catch (Exception ignored) {}
            browserOpen = false
        }
    }

    // ─── Helpers ──────────────────────────────────────────────────

    private WebDriver driver() { DriverFactory.getWebDriver() }

    private void openBrowser(String url) {
        if (browserOpen) {
            try { WebUI.closeBrowser() } catch (Exception ignored) {}
            browserOpen = false
        }
        WebUI.openBrowser(url)
        browserOpen = true
        WebUI.waitForPageLoad(10)
    }

    private WebElement byTestId(String testId) {
        driver().findElement(By.cssSelector("[data-testid='${testId}']"))
    }

    private List<WebElement> allByTestId(String testId) {
        driver().findElements(By.cssSelector("[data-testid='${testId}']"))
    }

    private Object jsonBody() { new JsonSlurper().parseText(lastBody) }

    /** Dotted + indexed JSON path: "id" or "member.role" or "projects[0].project_name". */
    private Object jsonPath(String path) {
        Object current = jsonBody()
        if (path == null || path.isEmpty()) return current
        for (String segment : path.split(/\./)) {
            def m = (segment =~ /^([^\[]+)((?:\[\d+\])*)$/)
            if (!m.matches()) fail("Bad JSON path segment '${segment}' in '${path}'".toString())
            String key = m.group(1)
            String indexers = m.group(2) ?: ""
            if (current == null) return null
            if (!(current instanceof Map)) {
                fail("Path '${path}' expected map at '${key}' got ${current?.getClass()?.simpleName}".toString())
            }
            current = ((Map) current).get(key)
            def idxM = (indexers =~ /\[(\d+)\]/)
            while (idxM.find()) {
                int idx = Integer.parseInt(idxM.group(1))
                if (!(current instanceof List)) {
                    fail("Path '${path}' expected list at [${idx}] got ${current?.getClass()?.simpleName}".toString())
                }
                current = ((List) current).get(idx)
            }
        }
        return current
    }

    /** Replace {storedName} placeholders with values from storedVars. */
    private String substituteVars(String s) {
        if (s == null) return null
        String result = s
        for (entry in storedVars.entrySet()) {
            result = result.replace("{${entry.key}}".toString(), entry.value ?: "")
        }
        return result
    }

    // ═════ SETUP / BACKGROUND ═════════════════════════════════════

    @Given("the portal is running at {string}")
    void portalRunningAt(String url) { baseUrl = url }

    @Given("the portal API is running at {string}")
    void portalApiRunningAt(String url) { baseUrl = url }

    @Given("the application is running at {string}")
    void applicationRunningAt(String url) { baseUrl = url }

    @Given("the API is running at {string}")
    void apiRunningAt(String url) { baseUrl = url }

    @Given("the Project Provisioning Portal is running at {string}")
    void provisioningRunningAt(String url) { baseUrl = url }

    @Given("the Project Provisioning Portal API is running at {string}")
    void provisioningApiRunningAt(String url) { baseUrl = url }

    @Given("all projects have been reset via {string}")
    void resetByDescription(String _ignored) { sendPost("/api/_reset", "") }

    @Given("I have sent a POST request to {string} to clear all state")
    void resetByPath(String path) { sendPost(path, "") }

    @Given("I am on the landing page")
    void onLandingPage() { openBrowser(baseUrl + "/") }

    @Given("I am on the landing page at {string}")
    void onLandingPageAt(String url) { openBrowser(url) }

    @Given("I navigate to the portal at {string}")
    void navigateToPortalAt(String url) { openBrowser(url) }

    @Given("I am on the wizard view")
    void onWizardView() {
        openBrowser(baseUrl + "/")
        byTestId("card-create").click()
        Thread.sleep(300)
    }

    @Given("I have navigated to the wizard view")
    void haveNavigatedToWizard() {
        openBrowser(baseUrl + "/")
        byTestId("card-create").click()
        Thread.sleep(300)
    }

    @Given("I am on the wizard view at {string}")
    void onWizardViewAt(String url) {
        openBrowser(url)
        byTestId("card-create").click()
        Thread.sleep(300)
    }

    // ═════ NAVIGATION (When/And) ══════════════════════════════════

    @When("I navigate to {string}")
    void navigateTo(String url) { openBrowser(url) }

    @When("I navigate to {string} in the browser")
    void navigateToInBrowser(String url) { openBrowser(url) }

    // ═════ HTTP ACTIONS ═══════════════════════════════════════════

    @When("I send a GET request to {string}")
    void httpGet(String path) { sendGet(path) }

    @When("I send a POST request to {string} with body:")
    void httpPostWithBody(String path, String body) { sendPost(path, body) }

    @When("I send a POST request to {string} with no body")
    void httpPostNoBody(String path) { sendPost(path, "") }

    @When("I send a DELETE request to {string}")
    void httpDelete(String path) { sendDelete(path) }

    // ═════ STATE — store / remember ═══════════════════════════════

    @When("I store the response body as {string}")
    void storeBody(String name) { storedResponses[name] = lastBody }

    @When("I store the response JSON field {string} as {string}")
    void storeJsonField(String fieldPath, String name) {
        def v = jsonPath(fieldPath)
        storedVars[name] = v == null ? "" : v.toString()
    }

    @When("I store the response field {string} as {string}")
    void storeField(String fieldPath, String name) {
        def v = jsonPath(fieldPath)
        storedVars[name] = v == null ? "" : v.toString()
    }

    @When("I remember the response JSON field {string} as {string}")
    void rememberJsonField(String fieldPath, String name) {
        def v = jsonPath(fieldPath)
        storedVars[name] = v == null ? "" : v.toString()
    }

    @When("I remember the response field {string} as {string}")
    void rememberField(String fieldPath, String name) {
        def v = jsonPath(fieldPath)
        storedVars[name] = v == null ? "" : v.toString()
    }

    @When("the page JavaScript has finished executing")
    void waitForJs() { Thread.sleep(500) }

    // ═════ UI ACTIONS ═════════════════════════════════════════════

    @When("I click the element with data-testid {string}")
    void clickTestId(String testId) {
        byTestId(testId).click()
        Thread.sleep(300)
    }

    @When("I type {string} into the element with data-testid {string}")
    void typeInto(String text, String testId) {
        WebElement el = byTestId(testId)
        el.clear()
        el.sendKeys(text)
    }

    @When("I select {string} from the element with data-testid {string}")
    void selectFrom(String value, String testId) { doSelect(testId, value) }

    @When("I have selected {string} from the element with data-testid {string}")
    void haveSelectedFrom(String value, String testId) { doSelect(testId, value) }

    @When("I select project {string} from the element with data-testid {string}")
    void selectProjectFrom(String value, String testId) { doSelect(testId, value) }

    @When("I select the blank placeholder option from the element with data-testid {string}")
    void selectBlankPlaceholder(String testId) {
        Select sel = new Select(byTestId(testId))
        sel.selectByValue("")
        Thread.sleep(200)
    }

    private void doSelect(String testId, String value) {
        Select sel = new Select(byTestId(testId))
        try { sel.selectByValue(value) }
        catch (Exception ignored) { sel.selectByVisibleText(value) }
        Thread.sleep(200)
    }

    // ═════ HTTP STATUS ════════════════════════════════════════════

    @Then("the response status should be {int}")
    void responseStatusShouldBe(int expected) { checkStatus(expected) }

    @Then("the HTTP response status is {int}")
    void httpResponseStatusIs(int expected) { checkStatus(expected) }

    @Then("the response status is {int}")
    void responseStatusIs(int expected) { checkStatus(expected) }

    @Then("the HTTP response status should be {int}")
    void httpResponseStatusShouldBe(int expected) { checkStatus(expected) }

    private void checkStatus(int expected) {
        assertEquals("HTTP status mismatch. Body: ${lastBody.take(500)}".toString(),
                expected, lastStatus)
    }

    // ═════ CONTENT-TYPE ═══════════════════════════════════════════

    @Then("the response Content-Type header contains {string}")
    void contentTypeHeaderContains(String expected) { checkContentType(expected) }

    @Then("the response Content-Type should contain {string}")
    void contentTypeShouldContain(String expected) { checkContentType(expected) }

    @Then("the response Content-Type contains {string}")
    void contentTypeContains(String expected) { checkContentType(expected) }

    private void checkContentType(String expected) {
        String ct = ""
        for (entry in lastHeaders.entrySet()) {
            if (entry.key != null && entry.key.equalsIgnoreCase("Content-Type")) {
                ct = entry.value.get(0); break
            }
        }
        assertTrue("Content-Type was '${ct}', expected to contain '${expected}'".toString(),
                ct.contains(expected))
    }

    // ═════ BODY-LEVEL ══════════════════════════════════════════════

    @Then("the response body should contain {string}")
    void bodyShouldContain(String fragment) { checkBodyContains(fragment) }

    @Then("the response body contains the string {string}")
    void bodyContainsTheString(String fragment) { checkBodyContains(fragment) }

    @Then("the response body contains {string}")
    void bodyContains(String fragment) { checkBodyContains(fragment) }

    private void checkBodyContains(String fragment) {
        assertTrue("Body did not contain '${fragment}'. Head: ${lastBody.take(500)}".toString(),
                lastBody.contains(fragment))
    }

    @Then("the response body is a JSON object")
    void bodyIsJsonObject() {
        assertTrue("Body is not a JSON object", jsonBody() instanceof Map)
    }

    @Then("the response JSON object has the key {string}")
    void jsonObjectHasKey(String key) { checkBodyHasKey(key) }

    @Then("the response body should have a top-level key {string}")
    void bodyShouldHaveTopLevelKey(String key) { checkBodyHasKey(key) }

    @Then("the response body has the key {string}")
    void bodyHasKey(String key) { checkBodyHasKey(key) }

    private void checkBodyHasKey(String key) {
        def parsed = jsonBody()
        assertTrue("Body missing key '${key}'".toString(),
                parsed instanceof Map && ((Map) parsed).containsKey(key))
    }

    @Then("the response body should equal {string}")
    void bodyShouldEqualStored(String name) {
        assertEquals("Stored body mismatch", storedResponses[name], lastBody)
    }

    // ═════ JSON FIELD — TYPE / SHAPE ══════════════════════════════

    @Then("the response JSON field {string} is an array")
    void jsonFieldIsArray(String key) { checkIsArray(key) }

    @Then("the response field {string} is an array")
    void fieldIsArray(String key) { checkIsArray(key) }

    @Then("the value of {string} should be a JSON array")
    void valueShouldBeJsonArray(String key) { checkIsArray(key) }

    private void checkIsArray(String key) {
        assertTrue("'${key}' is not a list".toString(), jsonPath(key) instanceof List)
    }

    @Then("the response JSON field {string} is an array with exactly {int} items")
    void jsonFieldArrayExactlyItems(String key, int len) { checkArrayLength(key, len) }

    @Then("the response JSON field {string} is an array with exactly {int} item")
    void jsonFieldArrayExactlyItem(String key, int len) { checkArrayLength(key, len) }

    @Then("the response field {string} should be a list of length {int}")
    void fieldShouldBeListOfLength(String key, int len) { checkArrayLength(key, len) }

    private void checkArrayLength(String key, int len) {
        def v = jsonPath(key)
        assertTrue("'${key}' is not a list".toString(), v instanceof List)
        assertEquals("'${key}' length mismatch (was ${v.size()}, expected ${len})".toString(),
                len, v.size())
    }

    @Then("the response JSON field {string} is an array with at least {int} items")
    void jsonFieldArrayAtLeastItems(String key, int len) { checkArrayAtLeast(key, len) }

    @Then("the response JSON field {string} is an array with at least {int} item")
    void jsonFieldArrayAtLeastItem(String key, int len) { checkArrayAtLeast(key, len) }

    private void checkArrayAtLeast(String key, int len) {
        def v = jsonPath(key)
        assertTrue("'${key}' is not a list".toString(), v instanceof List)
        assertTrue("'${key}' length ${v.size()} < ${len}".toString(), v.size() >= len)
    }

    @Then("the response JSON field {string} is an empty array")
    void jsonFieldIsEmptyArray(String key) { checkEmptyArray(key) }

    @Then("the response field {string} should be an empty array")
    void fieldShouldBeEmptyArray(String key) { checkEmptyArray(key) }

    private void checkEmptyArray(String key) {
        def v = jsonPath(key)
        assertTrue("'${key}' is not a list".toString(), v instanceof List)
        assertEquals("'${key}' is not empty (size=${v.size()})".toString(), 0, v.size())
    }

    @Then("the response JSON field {string} is a non-empty string")
    void jsonFieldNonEmptyString(String key) { checkNonEmptyString(key) }

    @Then("the response field {string} should be a non-empty string")
    void fieldShouldBeNonEmptyString(String key) { checkNonEmptyString(key) }

    private void checkNonEmptyString(String key) {
        def v = jsonPath(key)
        assertNotNull("Field '${key}' is null".toString(), v)
        assertFalse("Field '${key}' is empty".toString(), v.toString().isEmpty())
    }

    // ═════ JSON FIELD — VALUE ═════════════════════════════════════

    @Then("the response JSON field {string} should equal {string}")
    void jsonFieldShouldEqual(String key, String expected) { checkEquals(key, expected) }

    @Then("the response field {string} should equal {string}")
    void fieldShouldEqual(String key, String expected) { checkEquals(key, expected) }

    private void checkEquals(String key, String expected) {
        def v = jsonPath(key)
        String actual = v == null ? "null" : v.toString()
        assertEquals("Field '${key}' mismatch".toString(),
                substituteVars(expected), actual)
    }

    @Then("the response JSON field {string} should equal the stored value {string}")
    void jsonFieldShouldEqualStored(String key, String storedName) { checkEqualsStored(key, storedName) }

    @Then("the response field {string} should equal the stored value {string}")
    void fieldShouldEqualStored(String key, String storedName) { checkEqualsStored(key, storedName) }

    private void checkEqualsStored(String key, String storedName) {
        def v = jsonPath(key)
        String actual = v == null ? "null" : v.toString()
        assertEquals("Field '${key}' mismatch vs stored '${storedName}'".toString(),
                storedVars[storedName] ?: "", actual)
    }

    @Then("the response JSON field {string} contains {string}")
    void jsonFieldContains(String key, String expected) { checkContains(key, expected) }

    @Then("the response field {string} should contain {string}")
    void fieldShouldContain(String key, String expected) { checkContains(key, expected) }

    private void checkContains(String key, String expected) {
        def v = jsonPath(key)
        if (v instanceof List) {
            assertTrue("List '${key}' = ${v} does not contain '${expected}'".toString(),
                    v.contains(expected))
        } else {
            assertTrue("Field '${key}' = '${v}' does not contain '${expected}'".toString(),
                    v.toString().contains(expected))
        }
    }

    @Then("the response JSON field {string} should NOT contain {string}")
    void jsonFieldShouldNotContain(String key, String unexpected) { checkNotContains(key, unexpected) }

    @Then("the response field {string} should NOT contain {string}")
    void fieldShouldNotContain(String key, String unexpected) { checkNotContains(key, unexpected) }

    private void checkNotContains(String key, String unexpected) {
        def v = jsonPath(key)
        if (v instanceof List) {
            assertFalse("List '${key}' unexpectedly contains '${unexpected}'".toString(),
                    v.contains(unexpected))
        } else {
            assertFalse("Field '${key}' = '${v}' unexpectedly contains '${unexpected}'".toString(),
                    v.toString().contains(unexpected))
        }
    }

    // ═════ BARE-ARRAY ASSERTIONS ══════════════════════════════════

    @Then("the {string} array contains {string}")
    void arrayContains(String key, String expected) { checkArrayContains(key, expected) }

    @Then("the {string} array should contain {string}")
    void arrayShouldContain(String key, String expected) { checkArrayContains(key, expected) }

    private void checkArrayContains(String key, String expected) {
        def v = jsonPath(key)
        assertTrue("'${key}' is not a list".toString(), v instanceof List)
        assertTrue("Array '${key}' = ${v} does not contain '${expected}'".toString(),
                v.contains(expected))
    }

    @Then("the {string} array should NOT contain {string}")
    void arrayShouldNotContain(String key, String unexpected) {
        def v = jsonPath(key)
        assertTrue("'${key}' is not a list".toString(), v instanceof List)
        assertFalse("Array '${key}' unexpectedly contains '${unexpected}'".toString(),
                v.contains(unexpected))
    }

    @Then("the {string} array contains an object where {string} equals {string}")
    void arrayContainsObjectWhere(String key, String objKey, String expected) {
        def v = jsonPath(key)
        assertTrue("'${key}' is not a list".toString(), v instanceof List)
        String want = substituteVars(expected)
        assertTrue("Array '${key}' has no object with ${objKey}='${want}'. Got: ${v}".toString(),
                v.any { (it instanceof Map) && (((Map) it).get(objKey)?.toString() == want) })
    }

    @Then("the {string} array should NOT contain an object where {string} equals {string}")
    void arrayShouldNotContainObjectWhere(String key, String objKey, String unexpected) {
        def v = jsonPath(key)
        assertTrue("'${key}' is not a list".toString(), v instanceof List)
        String wantNot = substituteVars(unexpected)
        assertFalse("Array '${key}' unexpectedly has object with ${objKey}='${wantNot}'".toString(),
                v.any { (it instanceof Map) && (((Map) it).get(objKey)?.toString() == wantNot) })
    }

    // ═════ REGEX / UUID MATCH ═════════════════════════════════════

    @Then("the response JSON field {string} matches the UUID v4 pattern {string}")
    void jsonFieldMatchesUuid(String key, String pattern) { checkMatches(key, pattern) }

    @Then("the response JSON field {string} matches the pattern {string}")
    void jsonFieldMatchesPattern(String key, String pattern) { checkMatches(key, pattern) }

    @Then("the response field {string} should match the UUID v4 pattern {string}")
    void fieldShouldMatchUuid(String key, String pattern) { checkMatches(key, pattern) }

    @Then("the response field {string} should match the pattern {string}")
    void fieldShouldMatchPattern(String key, String pattern) { checkMatches(key, pattern) }

    private void checkMatches(String key, String pattern) {
        String v = jsonPath(key)?.toString() ?: ""
        assertTrue("Field '${key}' = '${v}' does not match pattern '${pattern}'".toString(),
                v.matches(pattern))
    }

    // ═════ STORED-VAR COMPARISON ══════════════════════════════════

    @Then("{string} should not equal {string}")
    void storedNotEqual(String n1, String n2) {
        String v1 = storedVars[n1] ?: ""
        String v2 = storedVars[n2] ?: ""
        assertNotEquals("Stored '${n1}' equals '${n2}' — both '${v1}'".toString(), v1, v2)
    }

    // ═════ UI — EXISTENCE ════════════════════════════════════════

    @Then("the page contains an element with data-testid {string}")
    void pageContainsElement(String testId) { checkExists(testId) }

    @Then("the page contains a select element with data-testid {string}")
    void pageContainsSelect(String testId) { checkExists(testId) }

    @Then("the page contains an input element with data-testid {string}")
    void pageContainsInput(String testId) { checkExists(testId) }

    @Then("the page contains a button with data-testid {string}")
    void pageContainsButton(String testId) { checkExists(testId) }

    @Then("the element with data-testid {string} should exist")
    void elementShouldExist(String testId) { checkExists(testId) }

    private void checkExists(String testId) {
        assertFalse("Element '${testId}' not found".toString(), allByTestId(testId).isEmpty())
    }

    // ═════ UI — VISIBILITY ═══════════════════════════════════════

    @Then("the element with data-testid {string} is visible")
    void elementVisible(String testId) { checkVisible(testId) }

    @Then("the element with data-testid {string} should be visible")
    void elementShouldBeVisible(String testId) { checkVisible(testId) }

    private void checkVisible(String testId) {
        assertTrue("Element '${testId}' not displayed".toString(), byTestId(testId).isDisplayed())
    }

    @Then("the element with data-testid {string} should not be visible")
    void elementShouldNotBeVisible(String testId) { checkNotVisible(testId) }

    @Then("the element with data-testid {string} is not visible")
    void elementNotVisible(String testId) { checkNotVisible(testId) }

    private void checkNotVisible(String testId) {
        List<WebElement> els = allByTestId(testId)
        if (els.isEmpty()) return
        assertFalse("Element '${testId}' visible but should not be".toString(), els[0].isDisplayed())
    }

    // ═════ UI — CSS CLASS ON id ══════════════════════════════════

    @Then("the element with id {string} has CSS class {string}")
    void idHasClass(String id, String cls) {
        String classes = driver().findElement(By.id(id)).getAttribute("class") ?: ""
        assertTrue("Element id='${id}' classes='${classes}', missing '${cls}'".toString(),
                classes.split(/\s+/).contains(cls))
    }

    @Then("the element with id {string} should have CSS class {string}")
    void idShouldHaveClass(String id, String cls) {
        String classes = driver().findElement(By.id(id)).getAttribute("class") ?: ""
        assertTrue("Element id='${id}' classes='${classes}', missing '${cls}'".toString(),
                classes.split(/\s+/).contains(cls))
    }

    @Then("the element with id {string} does not have CSS class {string}")
    void idDoesNotHaveClass(String id, String cls) { checkIdNotHasClass(id, cls) }

    @Then("the element with id {string} should NOT have CSS class {string}")
    void idShouldNotHaveClass(String id, String cls) { checkIdNotHasClass(id, cls) }

    private void checkIdNotHasClass(String id, String cls) {
        String classes = driver().findElement(By.id(id)).getAttribute("class") ?: ""
        assertFalse("Element id='${id}' unexpectedly has class '${cls}'".toString(),
                classes.split(/\s+/).contains(cls))
    }

    // ═════ UI — TAG / TYPE ════════════════════════════════════════

    @Then("the element with data-testid {string} should be a {string} element")
    void elementIsTagA(String testId, String tag) { checkTag(testId, tag) }

    @Then("the element with data-testid {string} should be an {string} element")
    void elementIsTagAn(String testId, String tag) { checkTag(testId, tag) }

    private void checkTag(String testId, String tag) {
        assertEquals(tag.toLowerCase(), byTestId(testId).getTagName().toLowerCase())
    }

    // ═════ UI — ATTRIBUTES ════════════════════════════════════════

    @Then("the element with data-testid {string} should have the {string} attribute")
    void elementHasAttribute(String testId, String attr) {
        assertNotNull("Element '${testId}' has no '${attr}' attribute".toString(),
                byTestId(testId).getAttribute(attr))
    }

    @Then("the element with data-testid {string} should have placeholder {string}")
    void elementHasPlaceholder(String testId, String placeholder) {
        assertEquals(placeholder, byTestId(testId).getAttribute("placeholder"))
    }

    @Then("the element with data-testid {string} is disabled")
    void elementDisabled(String testId) { checkDisabled(testId) }

    @Then("the element with data-testid {string} should be disabled")
    void elementShouldBeDisabled(String testId) { checkDisabled(testId) }

    private void checkDisabled(String testId) {
        WebElement el = byTestId(testId)
        String dis = el.getAttribute("disabled")
        boolean isDisabled = (dis != null && !dis.equalsIgnoreCase("false")) || !el.isEnabled()
        assertTrue("Element '${testId}' is not disabled".toString(), isDisabled)
    }

    @Then("the element with data-testid {string} is not disabled")
    void elementNotDisabled(String testId) { checkEnabled(testId) }

    @Then("the element with data-testid {string} is enabled")
    void elementEnabled(String testId) { checkEnabled(testId) }

    private void checkEnabled(String testId) {
        WebElement el = byTestId(testId)
        assertTrue("Element '${testId}' is disabled".toString(),
                el.isEnabled() && el.getAttribute("disabled") == null)
    }

    // ═════ UI — TEXT ══════════════════════════════════════════════

    @Then("the element with data-testid {string} should have text {string}")
    void elementHasExactText(String testId, String text) {
        assertEquals(text, byTestId(testId).getText().trim())
    }

    @Then("the element with data-testid {string} should contain the text {string}")
    void elementShouldContainText(String testId, String text) { checkContainsText(testId, text) }

    @Then("the element with data-testid {string} text should contain {string}")
    void elementTextShouldContain(String testId, String text) { checkContainsText(testId, text) }

    @Then("the element with data-testid {string} text contains {string}")
    void elementTextContains(String testId, String text) { checkContainsText(testId, text) }

    private void checkContainsText(String testId, String text) {
        String actual = byTestId(testId).getText()
        assertTrue("Element '${testId}' text was '${actual}', expected to contain '${text}'".toString(),
                actual.contains(text))
    }

    @Then("the element with data-testid {string} text matches the pattern {string}")
    void elementTextMatches(String testId, String pattern) {
        String actual = byTestId(testId).getText()
        assertTrue("Element '${testId}' text was '${actual}', expected to match /${pattern}/".toString(),
                Pattern.compile(pattern).matcher(actual).find())
    }

    // ═════ UI — INLINE STYLE ══════════════════════════════════════

    @Then("the element with data-testid {string} should have inline style {string}")
    void elementHasInlineStyle(String testId, String style) {
        String actual = (byTestId(testId).getAttribute("style") ?: "").replaceAll("\\s+", "")
        String expected = style.replaceAll("\\s+", "")
        assertTrue("Style was '${actual}', expected to contain '${expected}'".toString(),
                actual.contains(expected))
    }

    // ═════ UI — SELECT OPTIONS ════════════════════════════════════

    @Then("the select element with data-testid {string} has an option with value {string}")
    void selectHasOptionByValue(String testId, String value) { checkOptionByValueExists(testId, value) }

    @Then("the element with data-testid {string} has an option with value {string}")
    void elementHasOptionByValue(String testId, String value) { checkOptionByValueExists(testId, value) }

    private void checkOptionByValueExists(String testId, String value) {
        List<WebElement> opts = driver().findElements(
                By.cssSelector("[data-testid='${testId}'] option"))
        assertTrue("Select '${testId}' missing option value='${value}'. Have: ${opts.collect { it.getAttribute('value') }}".toString(),
                opts.any { it.getAttribute("value") == value })
    }

    @Then("the select element with data-testid {string} should NOT have an option with value {string}")
    void selectShouldNotHaveOptionByValue(String testId, String value) { checkOptionByValueAbsent(testId, value) }

    @Then("the element with data-testid {string} should NOT have an option with value {string}")
    void elementShouldNotHaveOptionByValue(String testId, String value) { checkOptionByValueAbsent(testId, value) }

    private void checkOptionByValueAbsent(String testId, String value) {
        List<WebElement> opts = driver().findElements(
                By.cssSelector("[data-testid='${testId}'] option"))
        assertFalse("Select '${testId}' unexpectedly has option value='${value}'".toString(),
                opts.any { it.getAttribute("value") == value })
    }

    @Then("the select element with data-testid {string} contains an option with text {string}")
    void selectContainsOptionByText(String testId, String text) { checkOptionByTextExists(testId, text) }

    @Then("the element with data-testid {string} contains an option with text {string}")
    void elementContainsOptionByText(String testId, String text) { checkOptionByTextExists(testId, text) }

    @Then("the element with data-testid {string} should contain an option with text {string}")
    void elementShouldContainOptionByText(String testId, String text) { checkOptionByTextExists(testId, text) }

    private void checkOptionByTextExists(String testId, String text) {
        List<WebElement> opts = driver().findElements(
                By.cssSelector("[data-testid='${testId}'] option"))
        assertTrue("Select '${testId}' missing option text='${text}'".toString(),
                opts.any { it.getText().trim() == text })
    }

    @Then("the select element with data-testid {string} contains only the placeholder option {string}")
    void selectOnlyPlaceholder(String testId, String text) {
        List<WebElement> opts = driver().findElements(
                By.cssSelector("[data-testid='${testId}'] option"))
        assertEquals("Select '${testId}' should have 1 option".toString(), 1, opts.size())
        assertEquals(text, opts[0].getText().trim())
    }

    @Then("the first option of the element with data-testid {string} should have value {string}")
    void firstOptionValue(String testId, String value) {
        List<WebElement> opts = driver().findElements(
                By.cssSelector("[data-testid='${testId}'] option"))
        assertFalse("Select '${testId}' has no options".toString(), opts.isEmpty())
        assertEquals(value, opts[0].getAttribute("value"))
    }

    @Then("the first option of the element with data-testid {string} should have text {string}")
    void firstOptionText(String testId, String text) {
        List<WebElement> opts = driver().findElements(
                By.cssSelector("[data-testid='${testId}'] option"))
        assertFalse("Select '${testId}' has no options".toString(), opts.isEmpty())
        assertEquals(text, opts[0].getText().trim())
    }

    @Then("the element with data-testid {string} should contain exactly {int} options")
    void selectOptionCount(String testId, int count) {
        List<WebElement> opts = driver().findElements(
                By.cssSelector("[data-testid='${testId}'] option"))
        assertEquals(count, opts.size())
    }

    // ═════ UI — NESTED ELEMENT ════════════════════════════════════

    @Then("the element with data-testid {string} contains an element with data-testid {string}")
    void parentContainsChild(String parentId, String childId) {
        WebElement parent = byTestId(parentId)
        List<WebElement> kids = parent.findElements(
                By.cssSelector("[data-testid='${childId}']"))
        assertFalse("Element '${parentId}' has no child with data-testid='${childId}'".toString(),
                kids.isEmpty())
    }

    // ═════ HTTP MACHINERY (private) ═══════════════════════════════

    private void sendGet(String path) {
        String resolved = substituteVars(path)
        URL url = resolved.startsWith("http") ? new URL(resolved) : new URL(baseUrl + resolved)
        HttpURLConnection conn = (HttpURLConnection) url.openConnection()
        conn.setRequestMethod("GET")
        conn.setConnectTimeout(5000); conn.setReadTimeout(5000)
        readResponse(conn)
    }

    private void sendPost(String path, String body) {
        String resolved = substituteVars(path)
        URL url = resolved.startsWith("http") ? new URL(resolved) : new URL(baseUrl + resolved)
        HttpURLConnection conn = (HttpURLConnection) url.openConnection()
        conn.setRequestMethod("POST")
        conn.setDoOutput(true)
        conn.setRequestProperty("Content-Type", "application/json")
        conn.setConnectTimeout(5000); conn.setReadTimeout(5000)
        String resolvedBody = substituteVars(body ?: "")
        conn.getOutputStream().withWriter("UTF-8") { it.write(resolvedBody) }
        readResponse(conn)
    }

    private void sendDelete(String path) {
        String resolved = substituteVars(path)
        URL url = resolved.startsWith("http") ? new URL(resolved) : new URL(baseUrl + resolved)
        HttpURLConnection conn = (HttpURLConnection) url.openConnection()
        conn.setRequestMethod("DELETE")
        conn.setConnectTimeout(5000); conn.setReadTimeout(5000)
        readResponse(conn)
    }

    private void readResponse(HttpURLConnection conn) {
        lastStatus = conn.getResponseCode()
        lastHeaders = conn.getHeaderFields()
        try {
            lastBody = conn.getInputStream()?.getText("UTF-8") ?: ""
        } catch (Exception ignored) {
            lastBody = conn.getErrorStream()?.getText("UTF-8") ?: ""
        }
        conn.disconnect()
    }
}
