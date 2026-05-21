// =====================================================================
// PortalSteps.groovy — universal step definitions for the
// Project Provisioning Portal BDD tests.
//
// Drop this in: Include/scripts/groovy/PortalSteps.groovy
// (or under any package; just make the folder path match `package`.)
//
// Designed for cucumber-jvm 7.x (Katalon Studio 10.x).
//
// HOW TO EXTEND WHEN A NEW STEP WORDING APPEARS
//   1. Run the feature. The Cucumber HTML report lists every undefined
//      step and prints a copy-pasteable @Then snippet.
//   2. Find the closest existing method below and ADD another annotation
//      to it (don't write a new method). Example:
//         @Then("the response field {string} should equal {string}")
//         @Then("the JSON field {string} matches {string}")   // new
//         void fieldEquals(String key, String expected) { ... }
//   3. For small wording variations ("should" / "is" / "JSON" / plurals),
//      prefer Cucumber-expression optional words:
//         (should )     ← matches "" or "should "
//         (JSON )       ← matches "" or "JSON "
//         item(s)       ← matches "item" or "items"
//         equal/equals  ← matches either word
//
// STATE NOTES
//   - All scenario state is INSTANCE state (not static) so it resets
//     cleanly per scenario via @Before.
//   - storedVars supports {var} interpolation inside paths and JSON
//     bodies, so you can do POST /api/projects/{project_id}/members.
//   - JSON paths support dotted + indexed access: "projects[0].name",
//     "member.user_email".
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
    @Given("the portal API is running at {string}")
    @Given("the Project Provisioning Portal is running at {string}")
    @Given("the Project Provisioning Portal API is running at {string}")
    void portalIsRunningAt(String url) {
        baseUrl = url
    }

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
    @Given("I navigate to the portal at {string}")
    void onLandingPage(String url) {
        openBrowser(url)
    }

    @Given("I am on the wizard view")
    @Given("I have navigated to the wizard view")
    void onWizardViewDefault() {
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

    // I navigate / I am at — works as Given OR When
    @Given("I navigate to {string}")
    @When("I navigate to {string}")
    @When("I navigate to {string} in the browser")
    void navigateBrowser(String url) {
        openBrowser(url)
    }

    // ═════ HTTP ACTIONS ════════════════════════════════════════════

    @Given("I send a GET request to {string}")
    @When("I send a GET request to {string}")
    void httpGet(String path) {
        sendGet(path)
    }

    @Given("I send a POST request to {string} with body:")
    @When("I send a POST request to {string} with body:")
    void httpPostWithBody(String path, String body) {
        sendPost(path, body)
    }

    @Given("I send a POST request to {string} with no body")
    @When("I send a POST request to {string} with no body")
    void httpPostNoBody(String path) {
        sendPost(path, "")
    }

    @Given("I send a DELETE request to {string}")
    @When("I send a DELETE request to {string}")
    void httpDelete(String path) {
        sendDelete(path)
    }

    // ═════ STORE / REMEMBER VALUES ═════════════════════════════════

    // Covers all of:
    //   I store the response JSON field "X" as "Y"
    //   I remember the response field "X" as "Y"
    @Given("I store the response (JSON )field {string} as {string}")
    @When("I store the response (JSON )field {string} as {string}")
    @Then("I store the response (JSON )field {string} as {string}")
    @Given("I remember the response (JSON )field {string} as {string}")
    @When("I remember the response (JSON )field {string} as {string}")
    void storeJsonField(String fieldPath, String name) {
        Object v = jsonPath(fieldPath)
        storedVars[name] = v == null ? "" : v.toString()
    }

    @When("I store the response body as {string}")
    void storeBody(String name) {
        storedResponses[name] = lastBody
    }

    @When("the page JavaScript has finished executing")
    void waitForJs() {
        Thread.sleep(500)
    }

    // ═════ UI ACTIONS ══════════════════════════════════════════════

    @Given("I click the element with data-testid {string}")
    @When("I click the element with data-testid {string}")
    void clickTestId(String testId) {
        byTestId(testId).click()
        Thread.sleep(300)
    }

    @Given("I type {string} into the element with data-testid {string}")
    @When("I type {string} into the element with data-testid {string}")
    void typeInto(String text, String testId) {
        WebElement el = byTestId(testId)
        el.clear()
        el.sendKeys(text)
    }

    // Covers "I select X from Y", "I have selected X from Y", "I select project X from Y"
    @Given("I select {string} from the element with data-testid {string}")
    @Given("I have selected {string} from the element with data-testid {string}")
    @When("I select {string} from the element with data-testid {string}")
    @Given("I select project {string} from the element with data-testid {string}")
    @When("I select project {string} from the element with data-testid {string}")
    void selectFromTestId(String value, String testId) {
        Select sel = new Select(byTestId(testId))
        try {
            sel.selectByValue(value)
        } catch (Exception ignored) {
            sel.selectByVisibleText(value)
        }
        Thread.sleep(200)
    }

    @When("I select the blank placeholder option from the element with data-testid {string}")
    void selectBlankPlaceholder(String testId) {
        Select sel = new Select(byTestId(testId))
        sel.selectByValue("")
        Thread.sleep(200)
    }

    // ═════ HTTP STATUS ═════════════════════════════════════════════

    // Matches "the response status should be 200" and "the HTTP response status is 200"
    @Then("the (HTTP )response status (should be|is) {int}")
    @Given("the (HTTP )response status (should be|is) {int}")
    void responseStatus(String _verb, int expected) {
        assertEquals("HTTP status mismatch. Body: ${lastBody.take(500)}".toString(),
                expected, lastStatus)
    }

    // ═════ CONTENT-TYPE ════════════════════════════════════════════

    @Then("the response Content-Type (header )?(should )?contain(s)? {string}")
    void contentTypeContains(String _h, String _s, String _suffix, String expected) {
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

    // Covers "the response body should contain X" and "the response body contains the string X"
    @Then("the response body (should contain|contains the string|contains) {string}")
    void bodyContains(String _verb, String fragment) {
        assertTrue("Body did not contain '${fragment}'. Head: ${lastBody.take(500)}".toString(),
                lastBody.contains(fragment))
    }

    @Then("the response body is a JSON object")
    void bodyIsObject() {
        assertTrue("Body is not a JSON object", jsonBody() instanceof Map)
    }

    // Covers "has the key" and "should have a top-level key"
    @Then("the response (JSON )?(body|object) (has|should have a top-level) key {string}")
    void bodyHasKey(String _j, String _bo, String _verb, String key) {
        def parsed = jsonBody()
        assertTrue("Body missing key '${key}'".toString(),
                parsed instanceof Map && ((Map) parsed).containsKey(key))
    }

    @Then("the response body should equal {string}")
    void bodyEqualsStored(String name) {
        assertEquals("Stored body mismatch", storedResponses[name], lastBody)
    }

    // ═════ JSON FIELD — TYPE / SHAPE ═══════════════════════════════

    // "the response JSON field X is an array" / "the value of X should be a JSON array" / "the response field X should be a list"
    @Then("the response (JSON )?field {string} is an array")
    @Then("the value of {string} should be a JSON array")
    void fieldIsArray(String key) {
        assertTrue("'${key}' is not a list".toString(), jsonPath(key) instanceof List)
    }

    // exact length
    @Then("the response (JSON )?field {string} (is an array with exactly|should be a list of length) {int} item(s)?")
    @Then("the response (JSON )?field {string} (is an array with exactly|should be a list of length) {int}")
    void fieldArrayLength(String _j, String key, String _verb, int len) {
        def v = jsonPath(key)
        assertTrue("'${key}' is not a list".toString(), v instanceof List)
        assertEquals("'${key}' length mismatch (was ${v.size()}, expected ${len})".toString(),
                len, v.size())
    }

    // at-least length
    @Then("the response (JSON )?field {string} is an array with at least {int} item(s)?")
    void fieldArrayAtLeast(String _j, String key, int len) {
        def v = jsonPath(key)
        assertTrue("'${key}' is not a list".toString(), v instanceof List)
        assertTrue("'${key}' length ${v.size()} < ${len}".toString(), v.size() >= len)
    }

    // empty array
    @Then("the response (JSON )?field {string} (is|should be) an empty array")
    void fieldEmptyArray(String _j, String key, String _verb) {
        def v = jsonPath(key)
        assertTrue("'${key}' is not a list".toString(), v instanceof List)
        assertEquals("'${key}' is not empty (size=${v.size()})".toString(), 0, v.size())
    }

    @Then("the response (JSON )?field {string} (is|should be) a non-empty string")
    void fieldNonEmptyString(String _j, String key, String _verb) {
        def v = jsonPath(key)
        assertNotNull("Field '${key}' is null".toString(), v)
        assertFalse("Field '${key}' is empty".toString(), v.toString().isEmpty())
    }

    // ═════ JSON FIELD — VALUE ═════════════════════════════════════

    // covers: "the response JSON field X should equal Y", "the response field X should equal Y"
    @Then("the response (JSON )?field {string} should equal {string}")
    void fieldEquals(String _j, String key, String expected) {
        def v = jsonPath(key)
        String actual = v == null ? "null" : v.toString()
        assertEquals("Field '${key}' mismatch".toString(),
                substituteVars(expected), actual)
    }

    @Then("the response (JSON )?field {string} should equal the stored value {string}")
    void fieldEqualsStored(String _j, String key, String storedName) {
        def v = jsonPath(key)
        String actual = v == null ? "null" : v.toString()
        assertEquals("Field '${key}' mismatch vs stored '${storedName}'".toString(),
                storedVars[storedName] ?: "", actual)
    }

    // covers: "the response JSON field X contains Y", "the response field X should contain Y"
    @Then("the response (JSON )?field {string} (contains|should contain) {string}")
    void fieldContains(String _j, String key, String _verb, String expected) {
        def v = jsonPath(key)
        if (v instanceof List) {
            assertTrue("List '${key}' = ${v} does not contain '${expected}'".toString(),
                    v.contains(expected))
        } else {
            assertTrue("Field '${key}' = '${v}' does not contain '${expected}'".toString(),
                    v.toString().contains(expected))
        }
    }

    @Then("the response (JSON )?field {string} should NOT contain {string}")
    void fieldNotContains(String _j, String key, String unexpected) {
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

    @Then("the {string} array (contains|should contain) {string}")
    void arrayContains(String key, String _verb, String expected) {
        def v = jsonPath(key)
        assertTrue("'${key}' is not a list".toString(), v instanceof List)
        assertTrue("Array '${key}' = ${v} does not contain '${expected}'".toString(),
                v.contains(expected))
    }

    @Then("the {string} array should NOT contain {string}")
    void arrayNotContains(String key, String unexpected) {
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
    void arrayNotContainsObjectWhere(String key, String objKey, String unexpected) {
        def v = jsonPath(key)
        assertTrue("'${key}' is not a list".toString(), v instanceof List)
        String wantNot = substituteVars(unexpected)
        assertFalse("Array '${key}' unexpectedly has object with ${objKey}='${wantNot}'".toString(),
                v.any { (it instanceof Map) && (((Map) it).get(objKey)?.toString() == wantNot) })
    }

    // ═════ REGEX / PATTERN MATCH ═══════════════════════════════════

    // covers UUID v4 + generic pattern variations
    @Then("the response (JSON )?field {string} matches the (UUID v4 )?pattern {string}")
    @Then("the response field {string} should match the (UUID v4 )?pattern {string}")
    void fieldMatchesPattern(String _j, String key, String _u, String pattern) {
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

    @Then("{string} should equal {string}")
    void storedEqual(String n1, String n2) {
        String v1 = storedVars[n1] ?: ""
        String v2 = storedVars[n2] ?: ""
        assertEquals("Stored '${n1}' != '${n2}'".toString(), v1, v2)
    }

    // ═════ UI: ELEMENT EXISTENCE ═══════════════════════════════════

    // covers all "the page contains a/an X element with data-testid Y" variants
    // and "the element with data-testid Y should exist"
    @Then("the page contains (an|a) (select |input |button )?element with data-testid {string}")
    @Then("the page contains a (select |input )?button with data-testid {string}")
    @Then("the element with data-testid {string} should exist")
    void elementExists(String _article, String _tag, String testId) {
        assertFalse("Element '${testId}' not found".toString(), allByTestId(testId).isEmpty())
    }

    // Simpler form without the tag noise
    @Then("the page contains an element with data-testid {string}")
    void elementExistsSimple(String testId) {
        assertFalse("Element '${testId}' not found".toString(), allByTestId(testId).isEmpty())
    }

    // ═════ UI: VISIBILITY ══════════════════════════════════════════

    @Then("the element with data-testid {string} (is|should be) visible")
    void elementVisible(String testId, String _verb) {
        assertTrue("Element '${testId}' not displayed".toString(), byTestId(testId).isDisplayed())
    }

    @Then("the element with data-testid {string} should not be visible")
    @Then("the element with data-testid {string} is not visible")
    void elementNotVisible(String testId) {
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
    @Then("the element with id {string} should NOT have CSS class {string}")
    void elementNotHasClass(String id, String cls) {
        String classes = driver().findElement(By.id(id)).getAttribute("class") ?: ""
        assertFalse("Element id='${id}' unexpectedly has class '${cls}'".toString(),
                classes.split(/\s+/).contains(cls))
    }

    // ═════ UI: TAG / TYPE ══════════════════════════════════════════

    @Then("the element with data-testid {string} should be a/an {string} element")
    void elementIsTag(String testId, String tag) {
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
    void elementDisabled(String testId) {
        WebElement el = byTestId(testId)
        String dis = el.getAttribute("disabled")
        boolean isDisabled = (dis != null && !dis.equalsIgnoreCase("false")) || !el.isEnabled()
        assertTrue("Element '${testId}' is not disabled".toString(), isDisabled)
    }

    @Then("the element with data-testid {string} is not disabled")
    @Then("the element with data-testid {string} is enabled")
    void elementEnabled(String testId) {
        WebElement el = byTestId(testId)
        assertTrue("Element '${testId}' is disabled".toString(),
                el.isEnabled() && el.getAttribute("disabled") == null)
    }

    // ═════ UI: TEXT ═══════════════════════════════════════════════

    @Then("the element with data-testid {string} should have text {string}")
    void elementExactText(String testId, String text) {
        assertEquals(text, byTestId(testId).getText().trim())
    }

    @Then("the element with data-testid {string} (should contain the text|text should contain|text contains) {string}")
    void elementTextContains(String testId, String _verb, String text) {
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
    @Then("the element with data-testid {string} has an option with value {string}")
    void selectHasOptionWithValue(String testId, String value) {
        List<WebElement> opts = driver().findElements(
                By.cssSelector("[data-testid='${testId}'] option"))
        assertTrue("Select '${testId}' missing option value='${value}'. Have: ${opts.collect { it.getAttribute('value') }}".toString(),
                opts.any { it.getAttribute("value") == value })
    }

    @Then("the select element with data-testid {string} should NOT have an option with value {string}")
    @Then("the element with data-testid {string} should NOT have an option with value {string}")
    void selectNotHasOptionWithValue(String testId, String value) {
        List<WebElement> opts = driver().findElements(
                By.cssSelector("[data-testid='${testId}'] option"))
        assertFalse("Select '${testId}' unexpectedly has option value='${value}'".toString(),
                opts.any { it.getAttribute("value") == value })
    }

    @Then("the (select )?element with data-testid {string} contains an option with text {string}")
    void selectHasOptionWithText(String _s, String testId, String text) {
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
