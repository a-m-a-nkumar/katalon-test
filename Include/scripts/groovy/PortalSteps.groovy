// =====================================================================
// PortalSteps.groovy — step definitions for the Project Provisioning
// Portal BDD tests.  Drop into Include/scripts/groovy/PortalSteps.groovy
//
// Designed for cucumber-jvm 7.x (Katalon Studio 10.x).
//
// CUCUMBER EXPRESSION RULES (relevant to extending this file):
//   {string}        — quoted string parameter
//   {int}           — integer parameter
//   (word )         — that word (with its trailing space) is OPTIONAL
//                     ⚠ no `?` after — CE is not regex
//   word1/word2     — alternation between two single words
//                     ⚠ no `|` — CE uses `/`, not `|`
//   For multi-word variations ("should be" vs "is"), use TWO separate
//   @Then annotations on the same method.
//
// IMPORTANT: Cucumber doesn't care whether the annotation is @Given,
// @When, or @Then — only the TEXT matters for matching.  If you put
// @Then("X") and @Given("X") on the same method, that's a DUPLICATE
// step definition error.  Every annotation text below is unique.
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

    // ─── Scenario-scoped state (instance, not static) ─────────────

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

    /** Resolve a dotted + indexed JSON path against the last response body.
     *  Supports: "id", "member.user_email", "projects[0].project_name". */
    private Object jsonPath(String path) {
        Object current = jsonBody()
        if (path == null || path.isEmpty()) return current
        for (String segment : path.split(/\./)) {
            def m = (segment =~ /^([^\[]+)((?:\[\d+\])*)$/)
            if (!m.matches()) fail("Bad JSON path segment '${segment}' in '${path}'")
            String key = m.group(1)
            String indexers = m.group(2) ?: ""
            if (!(current instanceof Map)) {
                fail("Path '${path}' expected a map at '${key}' but got ${current?.getClass()?.simpleName}")
            }
            current = ((Map) current).get(key)
            def idxM = (indexers =~ /\[(\d+)\]/)
            while (idxM.find()) {
                int idx = Integer.parseInt(idxM.group(1))
                if (!(current instanceof List)) {
                    fail("Path '${path}' expected a list at [${idx}] but got ${current?.getClass()?.simpleName}")
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

    // ═════ BACKGROUND / SETUP ═════════════════════════════════════

    @Given("the portal is running at {string}")
    void portalIsRunningAt(String url) { baseUrl = url }

    @Given("the portal API is running at {string}")
    void portalApiIsRunningAt(String url) { baseUrl = url }

    @Given("the Project Provisioning Portal is running at {string}")
    void provisioningPortalIsRunningAt(String url) { baseUrl = url }

    @Given("the Project Provisioning Portal API is running at {string}")
    void provisioningPortalApiIsRunningAt(String url) { baseUrl = url }

    @Given("all projects have been reset via {string}")
    void resetProjectsByDescription(String _description) {
        sendPost("/api/_reset", "")
    }

    @Given("I have sent a POST request to {string} to clear all state")
    void resetStateViaPath(String path) {
        sendPost(path, "")
    }

    @Given("I am on the landing page")
    void onLandingPageDefault() {
        openBrowser(baseUrl + "/")
    }

    @Given("I am on the landing page at {string}")
    void onLandingPageAt(String url) {
        openBrowser(url)
    }

    @Given("I navigate to the portal at {string}")
    void navigateToPortalAt(String url) {
        openBrowser(url)
    }

    @Given("I am on the wizard view")
    void onWizardViewDefault() {
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

    // Note: a single @When matches the step anywhere (Given/When/Then/And).
    // The keyword in the .feature does not affect matching.
    @When("I navigate to {string}")
    void navigateBrowser(String url) {
        openBrowser(url)
    }

    @When("I navigate to {string} in the browser")
    void navigateBrowserVerbose(String url) {
        openBrowser(url)
    }

    // ═════ HTTP ACTIONS ════════════════════════════════════════════

    @When("I send a GET request to {string}")
    void httpGet(String path) { sendGet(path) }

    @When("I send a POST request to {string} with body:")
    void httpPostWithBody(String path, String body) { sendPost(path, body) }

    @When("I send a POST request to {string} with no body")
    void httpPostNoBody(String path) { sendPost(path, "") }

    @When("I send a DELETE request to {string}")
    void httpDelete(String path) { sendDelete(path) }

    // ═════ STORE / REMEMBER VALUES ═════════════════════════════════

    @When("I store the response JSON field {string} as {string}")
    void storeJsonField(String fieldPath, String name) {
        Object v = jsonPath(fieldPath)
        storedVars[name] = v == null ? "" : v.toString()
    }

    @When("I store the response field {string} as {string}")
    void storeField(String fieldPath, String name) {
        Object v = jsonPath(fieldPath)
        storedVars[name] = v == null ? "" : v.toString()
    }

    @When("I remember the response JSON field {string} as {string}")
    void rememberJsonField(String fieldPath, String name) {
        Object v = jsonPath(fieldPath)
        storedVars[name] = v == null ? "" : v.toString()
    }

    @When("I remember the response field {string} as {string}")
    void rememberField(String fieldPath, String name) {
        Object v = jsonPath(fieldPath)
        storedVars[name] = v == null ? "" : v.toString()
    }

    @When("I store the response body as {string}")
    void storeBody(String name) { storedResponses[name] = lastBody }

    @When("the page JavaScript has finished executing")
    void waitForJs() { Thread.sleep(500) }

    // ═════ UI ACTIONS ══════════════════════════════════════════════

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
    void selectFromTestId(String value, String testId) {
        selectOption(testId, value)
    }

    @When("I have selected {string} from the element with data-testid {string}")
    void haveSelectedFromTestId(String value, String testId) {
        selectOption(testId, value)
    }

    @When("I select project {string} from the element with data-testid {string}")
    void selectProjectFromTestId(String value, String testId) {
        selectOption(testId, value)
    }

    @When("I select the blank placeholder option from the element with data-testid {string}")
    void selectBlankPlaceholder(String testId) {
        Select sel = new Select(byTestId(testId))
        sel.selectByValue("")
        Thread.sleep(200)
    }

    private void selectOption(String testId, String value) {
        Select sel = new Select(byTestId(testId))
        try { sel.selectByValue(value) }
        catch (Exception ignored) { sel.selectByVisibleText(value) }
        Thread.sleep(200)
    }

    // ═════ HTTP STATUS ════════════════════════════════════════════
    // "the response status should be 200"
    // "the HTTP response status is 200"

    @Then("the response status should be {int}")
    void responseStatusShouldBe(int expected) {
        assertStatus(expected)
    }

    @Then("the HTTP response status is {int}")
    void httpResponseStatusIs(int expected) {
        assertStatus(expected)
    }

    @Then("the response status is {int}")
    void responseStatusIs(int expected) {
        assertStatus(expected)
    }

    @Then("the HTTP response status should be {int}")
    void httpResponseStatusShouldBe(int expected) {
        assertStatus(expected)
    }

    private void assertStatus(int expected) {
        assertEquals("HTTP status mismatch. Body: ${lastBody.take(500)}".toString(),
                expected, lastStatus)
    }

    // ═════ CONTENT-TYPE ════════════════════════════════════════════

    @Then("the response Content-Type header contains {string}")
    void contentTypeHeaderContains(String expected) { assertContentTypeContains(expected) }

    @Then("the response Content-Type should contain {string}")
    void contentTypeShouldContain(String expected) { assertContentTypeContains(expected) }

    @Then("the response Content-Type contains {string}")
    void contentTypeContains(String expected) { assertContentTypeContains(expected) }

    private void assertContentTypeContains(String expected) {
        String ct = ""
        for (entry in lastHeaders.entrySet()) {
            if (entry.key != null && entry.key.equalsIgnoreCase("Content-Type")) {
                ct = entry.value.get(0); break
            }
        }
        assertTrue("Content-Type was '${ct}', expected to contain '${expected}'".toString(),
                ct.contains(expected))
    }

    // ═════ BODY-LEVEL ASSERTIONS ═══════════════════════════════════

    @Then("the response body should contain {string}")
    void bodyShouldContain(String fragment) { assertBodyContains(fragment) }

    @Then("the response body contains the string {string}")
    void bodyContainsString(String fragment) { assertBodyContains(fragment) }

    @Then("the response body contains {string}")
    void bodyContains(String fragment) { assertBodyContains(fragment) }

    private void assertBodyContains(String fragment) {
        assertTrue("Body did not contain '${fragment}'. Head: ${lastBody.take(500)}".toString(),
                lastBody.contains(fragment))
    }

    @Then("the response body is a JSON object")
    void bodyIsObject() {
        assertTrue("Body is not a JSON object", jsonBody() instanceof Map)
    }

    @Then("the response JSON object has the key {string}")
    void jsonObjectHasKey(String key) { assertBodyHasKey(key) }

    @Then("the response body should have a top-level key {string}")
    void bodyShouldHaveTopLevelKey(String key) { assertBodyHasKey(key) }

    @Then("the response body has the key {string}")
    void bodyHasKey(String key) { assertBodyHasKey(key) }

    private void assertBodyHasKey(String key) {
        def parsed = jsonBody()
        assertTrue("Body missing key '${key}'".toString(),
                parsed instanceof Map && ((Map) parsed).containsKey(key))
    }

    @Then("the response body should equal {string}")
    void bodyEqualsStored(String name) {
        assertEquals("Stored body mismatch", storedResponses[name], lastBody)
    }

    // ═════ JSON FIELD — TYPE / SHAPE ═══════════════════════════════

    @Then("the response JSON field {string} is an array")
    void jsonFieldIsArray(String key) { assertFieldIsArray(key) }

    @Then("the response field {string} is an array")
    void fieldIsArray(String key) { assertFieldIsArray(key) }

    @Then("the value of {string} should be a JSON array")
    void valueShouldBeJsonArray(String key) { assertFieldIsArray(key) }

    private void assertFieldIsArray(String key) {
        assertTrue("'${key}' is not a list".toString(), jsonPath(key) instanceof List)
    }

    // exact length
    @Then("the response JSON field {string} is an array with exactly {int} items")
    void jsonFieldArrayLengthItems(String key, int len) { assertFieldArrayLength(key, len) }

    @Then("the response JSON field {string} is an array with exactly {int} item")
    void jsonFieldArrayLengthItem(String key, int len) { assertFieldArrayLength(key, len) }

    @Then("the response field {string} should be a list of length {int}")
    void fieldShouldBeListOfLength(String key, int len) { assertFieldArrayLength(key, len) }

    private void assertFieldArrayLength(String key, int len) {
        def v = jsonPath(key)
        assertTrue("'${key}' is not a list".toString(), v instanceof List)
        assertEquals("'${key}' length mismatch (was ${v.size()}, expected ${len})".toString(),
                len, v.size())
    }

    // at-least length
    @Then("the response JSON field {string} is an array with at least {int} items")
    void jsonFieldArrayAtLeastItems(String key, int len) { assertFieldArrayAtLeast(key, len) }

    @Then("the response JSON field {string} is an array with at least {int} item")
    void jsonFieldArrayAtLeastItem(String key, int len) { assertFieldArrayAtLeast(key, len) }

    private void assertFieldArrayAtLeast(String key, int len) {
        def v = jsonPath(key)
        assertTrue("'${key}' is not a list".toString(), v instanceof List)
        assertTrue("'${key}' length ${v.size()} < ${len}".toString(), v.size() >= len)
    }

    @Then("the response JSON field {string} is an empty array")
    void jsonFieldIsEmptyArray(String key) { assertFieldEmptyArray(key) }

    @Then("the response field {string} should be an empty array")
    void fieldShouldBeEmptyArray(String key) { assertFieldEmptyArray(key) }

    private void assertFieldEmptyArray(String key) {
        def v = jsonPath(key)
        assertTrue("'${key}' is not a list".toString(), v instanceof List)
        assertEquals("'${key}' is not empty (size=${v.size()})".toString(), 0, v.size())
    }

    @Then("the response JSON field {string} is a non-empty string")
    void jsonFieldNonEmptyString(String key) { assertFieldNonEmptyString(key) }

    @Then("the response field {string} should be a non-empty string")
    void fieldShouldBeNonEmptyString(String key) { assertFieldNonEmptyString(key) }

    private void assertFieldNonEmptyString(String key) {
        def v = jsonPath(key)
        assertNotNull("Field '${key}' is null".toString(), v)
        assertFalse("Field '${key}' is empty".toString(), v.toString().isEmpty())
    }

    // ═════ JSON FIELD — VALUE ═════════════════════════════════════

    @Then("the response JSON field {string} should equal {string}")
    void jsonFieldShouldEqual(String key, String expected) { assertFieldEquals(key, expected) }

    @Then("the response field {string} should equal {string}")
    void fieldShouldEqual(String key, String expected) { assertFieldEquals(key, expected) }

    private void assertFieldEquals(String key, String expected) {
        def v = jsonPath(key)
        String actual = v == null ? "null" : v.toString()
        assertEquals("Field '${key}' mismatch".toString(),
                substituteVars(expected), actual)
    }

    @Then("the response JSON field {string} should equal the stored value {string}")
    void jsonFieldShouldEqualStored(String key, String storedName) { assertFieldEqualsStored(key, storedName) }

    @Then("the response field {string} should equal the stored value {string}")
    void fieldShouldEqualStored(String key, String storedName) { assertFieldEqualsStored(key, storedName) }

    private void assertFieldEqualsStored(String key, String storedName) {
        def v = jsonPath(key)
        String actual = v == null ? "null" : v.toString()
        assertEquals("Field '${key}' mismatch vs stored '${storedName}'".toString(),
                storedVars[storedName] ?: "", actual)
    }

    @Then("the response JSON field {string} contains {string}")
    void jsonFieldContains(String key, String expected) { assertFieldContains(key, expected) }

    @Then("the response field {string} should contain {string}")
    void fieldShouldContain(String key, String expected) { assertFieldContains(key, expected) }

    private void assertFieldContains(String key, String expected) {
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
    void jsonFieldShouldNotContain(String key, String unexpected) { assertFieldNotContains(key, unexpected) }

    @Then("the response field {string} should NOT contain {string}")
    void fieldShouldNotContain(String key, String unexpected) { assertFieldNotContains(key, unexpected) }

    private void assertFieldNotContains(String key, String unexpected) {
        def v = jsonPath(key)
        if (v instanceof List) {
            assertFalse("List '${key}' unexpectedly contains '${unexpected}'".toString(),
                    v.contains(unexpected))
        } else {
            assertFalse("Field '${key}' = '${v}' unexpectedly contains '${unexpected}'".toString(),
                    v.toString().contains(unexpected))
        }
    }

    // ═════ BARE-ARRAY ASSERTIONS:  the "X" array contains "Y" ═════

    @Then("the {string} array contains {string}")
    void arrayContains(String key, String expected) { assertArrayContains(key, expected) }

    @Then("the {string} array should contain {string}")
    void arrayShouldContain(String key, String expected) { assertArrayContains(key, expected) }

    private void assertArrayContains(String key, String expected) {
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

    // ═════ REGEX / PATTERN MATCH ═══════════════════════════════════

    @Then("the response JSON field {string} matches the UUID v4 pattern {string}")
    void jsonFieldMatchesUuidV4(String key, String pattern) { assertFieldMatches(key, pattern) }

    @Then("the response JSON field {string} matches the pattern {string}")
    void jsonFieldMatchesPattern(String key, String pattern) { assertFieldMatches(key, pattern) }

    @Then("the response field {string} should match the UUID v4 pattern {string}")
    void fieldShouldMatchUuidV4(String key, String pattern) { assertFieldMatches(key, pattern) }

    @Then("the response field {string} should match the pattern {string}")
    void fieldShouldMatchPattern(String key, String pattern) { assertFieldMatches(key, pattern) }

    private void assertFieldMatches(String key, String pattern) {
        String v = jsonPath(key)?.toString() ?: ""
        assertTrue("Field '${key}' = '${v}' does not match pattern '${pattern}'".toString(),
                v.matches(pattern))
    }

    // ═════ STORED-VAR COMPARISON ═══════════════════════════════════

    @Then("{string} should not equal {string}")
    void storedNotEqual(String n1, String n2) {
        String v1 = storedVars[n1] ?: ""
        String v2 = storedVars[n2] ?: ""
        assertNotEquals("Stored '${n1}' equals '${n2}' — both '${v1}'".toString(), v1, v2)
    }

    // ═════ UI: ELEMENT EXISTENCE ═══════════════════════════════════

    @Then("the page contains an element with data-testid {string}")
    void pageContainsElement(String testId) { assertExists(testId) }

    @Then("the page contains a select element with data-testid {string}")
    void pageContainsSelect(String testId) { assertExists(testId) }

    @Then("the page contains an input element with data-testid {string}")
    void pageContainsInput(String testId) { assertExists(testId) }

    @Then("the page contains a button with data-testid {string}")
    void pageContainsButton(String testId) { assertExists(testId) }

    @Then("the element with data-testid {string} should exist")
    void elementShouldExist(String testId) { assertExists(testId) }

    private void assertExists(String testId) {
        assertFalse("Element '${testId}' not found".toString(), allByTestId(testId).isEmpty())
    }

    // ═════ UI: VISIBILITY ══════════════════════════════════════════

    @Then("the element with data-testid {string} is visible")
    void elementVisible(String testId) { assertVisible(testId) }

    @Then("the element with data-testid {string} should be visible")
    void elementShouldBeVisible(String testId) { assertVisible(testId) }

    private void assertVisible(String testId) {
        assertTrue("Element '${testId}' not displayed".toString(), byTestId(testId).isDisplayed())
    }

    @Then("the element with data-testid {string} should not be visible")
    void elementShouldNotBeVisible(String testId) { assertNotVisible(testId) }

    @Then("the element with data-testid {string} is not visible")
    void elementNotVisible(String testId) { assertNotVisible(testId) }

    private void assertNotVisible(String testId) {
        List<WebElement> els = allByTestId(testId)
        if (els.isEmpty()) return  // not present == not visible
        assertFalse("Element '${testId}' is visible but should not be".toString(),
                els[0].isDisplayed())
    }

    // ═════ UI: CSS CLASS ═══════════════════════════════════════════

    @Then("the element with id {string} has CSS class {string}")
    void elementHasClass(String id, String cls) {
        String classes = driver().findElement(By.id(id)).getAttribute("class") ?: ""
        assertTrue("Element id='${id}' classes='${classes}', missing '${cls}'".toString(),
                classes.split(/\s+/).contains(cls))
    }

    @Then("the element with id {string} does not have CSS class {string}")
    void elementDoesNotHaveClass(String id, String cls) { assertNotHasClass(id, cls) }

    @Then("the element with id {string} should NOT have CSS class {string}")
    void elementShouldNotHaveClass(String id, String cls) { assertNotHasClass(id, cls) }

    private void assertNotHasClass(String id, String cls) {
        String classes = driver().findElement(By.id(id)).getAttribute("class") ?: ""
        assertFalse("Element id='${id}' unexpectedly has class '${cls}'".toString(),
                classes.split(/\s+/).contains(cls))
    }

    // ═════ UI: TAG / TYPE ══════════════════════════════════════════

    @Then("the element with data-testid {string} should be a {string} element")
    void elementIsTagA(String testId, String tag) { assertIsTag(testId, tag) }

    @Then("the element with data-testid {string} should be an {string} element")
    void elementIsTagAn(String testId, String tag) { assertIsTag(testId, tag) }

    private void assertIsTag(String testId, String tag) {
        assertEquals(tag.toLowerCase(), byTestId(testId).getTagName().toLowerCase())
    }

    // ═════ UI: ATTRIBUTES ══════════════════════════════════════════

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
    void elementDisabled(String testId) { assertDisabled(testId) }

    @Then("the element with data-testid {string} should be disabled")
    void elementShouldBeDisabled(String testId) { assertDisabled(testId) }

    private void assertDisabled(String testId) {
        WebElement el = byTestId(testId)
        String dis = el.getAttribute("disabled")
        boolean isDisabled = (dis != null && !dis.equalsIgnoreCase("false")) || !el.isEnabled()
        assertTrue("Element '${testId}' is not disabled".toString(), isDisabled)
    }

    @Then("the element with data-testid {string} is not disabled")
    void elementNotDisabled(String testId) { assertEnabled(testId) }

    @Then("the element with data-testid {string} is enabled")
    void elementEnabled(String testId) { assertEnabled(testId) }

    private void assertEnabled(String testId) {
        WebElement el = byTestId(testId)
        assertTrue("Element '${testId}' is disabled".toString(),
                el.isEnabled() && el.getAttribute("disabled") == null)
    }

    // ═════ UI: TEXT ════════════════════════════════════════════════

    @Then("the element with data-testid {string} should have text {string}")
    void elementExactText(String testId, String text) {
        assertEquals(text, byTestId(testId).getText().trim())
    }

    @Then("the element with data-testid {string} should contain the text {string}")
    void elementShouldContainText(String testId, String text) { assertTextContains(testId, text) }

    @Then("the element with data-testid {string} text should contain {string}")
    void elementTextShouldContain(String testId, String text) { assertTextContains(testId, text) }

    @Then("the element with data-testid {string} text contains {string}")
    void elementTextContains(String testId, String text) { assertTextContains(testId, text) }

    private void assertTextContains(String testId, String text) {
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

    // ═════ UI: STYLE ═══════════════════════════════════════════════

    @Then("the element with data-testid {string} should have inline style {string}")
    void elementHasInlineStyle(String testId, String style) {
        String actual = (byTestId(testId).getAttribute("style") ?: "").replaceAll("\\s+", "")
        String expected = style.replaceAll("\\s+", "")
        assertTrue("Style was '${actual}', expected to contain '${expected}'".toString(),
                actual.contains(expected))
    }

    // ═════ UI: SELECT OPTIONS ══════════════════════════════════════

    @Then("the select element with data-testid {string} has an option with value {string}")
    void selectHasOptionWithValue(String testId, String value) { assertOptionByValueExists(testId, value) }

    @Then("the element with data-testid {string} has an option with value {string}")
    void elementHasOptionWithValue(String testId, String value) { assertOptionByValueExists(testId, value) }

    private void assertOptionByValueExists(String testId, String value) {
        List<WebElement> opts = driver().findElements(
                By.cssSelector("[data-testid='${testId}'] option"))
        assertTrue("Select '${testId}' missing option value='${value}'. Have: ${opts.collect { it.getAttribute('value') }}".toString(),
                opts.any { it.getAttribute("value") == value })
    }

    @Then("the select element with data-testid {string} should NOT have an option with value {string}")
    void selectShouldNotHaveOptionWithValue(String testId, String value) { assertOptionByValueAbsent(testId, value) }

    @Then("the element with data-testid {string} should NOT have an option with value {string}")
    void elementShouldNotHaveOptionWithValue(String testId, String value) { assertOptionByValueAbsent(testId, value) }

    private void assertOptionByValueAbsent(String testId, String value) {
        List<WebElement> opts = driver().findElements(
                By.cssSelector("[data-testid='${testId}'] option"))
        assertFalse("Select '${testId}' unexpectedly has option value='${value}'".toString(),
                opts.any { it.getAttribute("value") == value })
    }

    @Then("the select element with data-testid {string} contains an option with text {string}")
    void selectContainsOptionWithText(String testId, String text) { assertOptionByTextExists(testId, text) }

    @Then("the element with data-testid {string} contains an option with text {string}")
    void elementContainsOptionWithText(String testId, String text) { assertOptionByTextExists(testId, text) }

    private void assertOptionByTextExists(String testId, String text) {
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

    // ═════ UI: NESTED ELEMENT CONTAINMENT ══════════════════════════

    @Then("the element with data-testid {string} contains an element with data-testid {string}")
    void parentContainsChildByTestId(String parentId, String childId) {
        WebElement parent = byTestId(parentId)
        List<WebElement> kids = parent.findElements(
                By.cssSelector("[data-testid='${childId}']"))
        assertFalse("Element '${parentId}' has no child with data-testid='${childId}'".toString(),
                kids.isEmpty())
    }

    // ═════ HTTP MACHINERY ══════════════════════════════════════════

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
