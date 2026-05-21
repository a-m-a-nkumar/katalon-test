// =====================================================================
// PortalSteps.groovy — universal Cucumber step definitions for Katalon
//
// ▸ Drop into Include/scripts/groovy/PortalSteps.groovy
// ▸ DO NOT keep a second copy anywhere in the project — Katalon loads
//   every .groovy file under Include/scripts/groovy/ and Cucumber will
//   report "Duplicate step definitions" if the same step text appears
//   in two places.
// ▸ Every @Given/@When/@Then annotation TEXT below is UNIQUE.
// ▸ Synonyms ("should be" vs "is") are not both provided on purpose —
//   the Gherkin must use the canonical phrasing listed here.
// ▸ State is scenario-scoped via instance fields + @Before reset.
// ▸ Cucumber-jvm 7.x (Katalon Studio 10.x). No regex — Cucumber
//   expressions only ({string}, {int}).
// =====================================================================

import io.cucumber.java.en.Given
import io.cucumber.java.en.When
import io.cucumber.java.en.Then
import io.cucumber.java.Before
import io.cucumber.java.After

import groovy.json.JsonSlurper

import java.net.HttpURLConnection
import java.net.URL

import org.openqa.selenium.By
import org.openqa.selenium.WebDriver
import org.openqa.selenium.WebElement

import com.kms.katalon.core.webui.driver.DriverFactory
import com.kms.katalon.core.webui.keyword.WebUiBuiltInKeywords as WebUI

import static org.junit.Assert.*

class PortalSteps {

    // ─── Scenario-scoped state ────────────────────────────────────

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

    // ─── Private helpers ──────────────────────────────────────────

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

    /** Dotted JSON path: "id" or "member.role" or "projects.0.name". */
    private Object jsonPath(String path) {
        if (path == null || path.isEmpty()) return jsonBody()
        Object current = jsonBody()
        for (String segment : path.split(/\./)) {
            if (current == null) return null
            if (current instanceof Map) {
                current = ((Map) current).get(segment)
            } else if (current instanceof List && segment.matches(/\d+/)) {
                current = ((List) current).get(Integer.parseInt(segment))
            } else {
                return null
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
    //
    // Generic phrasings — preferred for new projects.

    @Given("the application is running at {string}")
    void appRunningAt(String url) { baseUrl = url }

    @Given("the API is running at {string}")
    void apiRunningAt(String url) { baseUrl = url }

    // Project-specific aliases — kept so existing demo Gherkin still
    // matches. New projects should use the generic phrasings above.

    @Given("the Project Provisioning Portal is running at {string}")
    void portalRunningAt(String url) { baseUrl = url }

    @Given("the Project Provisioning Portal API is running at {string}")
    void portalApiRunningAt(String url) { baseUrl = url }

    @Given("I have sent a POST request to {string} to clear all state")
    void resetViaPath(String path) { sendPost(path, "") }

    @Given("I am on the landing page at {string}")
    void onLandingPageAt(String url) { openBrowser(url) }

    @Given("I have navigated to the wizard view")
    void onWizardView() {
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

    // ═════ HTTP ACTIONS ═══════════════════════════════════════════

    @When("I send a GET request to {string}")
    void httpGet(String path) { sendGet(path) }

    @When("I send a POST request to {string} with body:")
    void httpPostWithBody(String path, String body) { sendPost(path, body) }

    @When("I send a DELETE request to {string}")
    void httpDelete(String path) { sendDelete(path) }

    @When("I store the response body as {string}")
    void storeBody(String name) { storedResponses[name] = lastBody }

    @When("I remember the response field {string} as {string}")
    void rememberField(String fieldPath, String name) {
        def v = jsonPath(fieldPath)
        storedVars[name] = v == null ? "" : v.toString()
    }

    // ═════ UI ACTIONS ═════════════════════════════════════════════

    @When("I navigate to {string} in the browser")
    void navigateBrowser(String url) { openBrowser(url) }

    @When("I click the element with data-testid {string}")
    void clickTestId(String testId) {
        byTestId(testId).click()
        Thread.sleep(300)
    }

    @When("the page JavaScript has finished executing")
    void waitForJs() { Thread.sleep(500) }

    // ═════ HTTP ASSERTIONS ════════════════════════════════════════

    @Then("the response status should be {int}")
    void statusShouldBe(int expected) {
        assertEquals("HTTP status mismatch. Body: ${lastBody.take(500)}".toString(),
                expected, lastStatus)
    }

    @Then("the response Content-Type should contain {string}")
    void contentTypeShouldContain(String expected) {
        String ct = ""
        for (entry in lastHeaders.entrySet()) {
            if (entry.key != null && entry.key.equalsIgnoreCase("Content-Type")) {
                ct = entry.value.get(0); break
            }
        }
        assertTrue("Content-Type was '${ct}', expected to contain '${expected}'".toString(),
                ct.contains(expected))
    }

    @Then("the response body should contain {string}")
    void bodyShouldContain(String fragment) {
        assertTrue("Body did not contain '${fragment}'. Head: ${lastBody.take(500)}".toString(),
                lastBody.contains(fragment))
    }

    @Then("the response body should have a top-level key {string}")
    void bodyShouldHaveTopLevelKey(String key) {
        def parsed = jsonBody()
        assertTrue("Body missing key '${key}'".toString(),
                parsed instanceof Map && ((Map) parsed).containsKey(key))
    }

    @Then("the value of {string} should be a JSON array")
    void valueShouldBeJsonArray(String key) {
        assertTrue("'${key}' is not a list".toString(), jsonPath(key) instanceof List)
    }

    @Then("the response field {string} should be a list of length {int}")
    void fieldShouldBeListOfLength(String key, int len) {
        def v = jsonPath(key)
        assertTrue("'${key}' is not a list".toString(), v instanceof List)
        assertEquals("'${key}' length mismatch (was ${v.size()}, expected ${len})".toString(),
                len, v.size())
    }

    @Then("the response field {string} should contain {string}")
    void fieldShouldContain(String key, String expected) {
        def v = jsonPath(key)
        if (v instanceof List) {
            assertTrue("List '${key}' = ${v} does not contain '${expected}'".toString(),
                    v.contains(expected))
        } else {
            assertTrue("Field '${key}' = '${v}' does not contain '${expected}'".toString(),
                    v.toString().contains(expected))
        }
    }

    @Then("the response field {string} should NOT contain {string}")
    void fieldShouldNotContain(String key, String unexpected) {
        def v = jsonPath(key)
        if (v instanceof List) {
            assertFalse("List '${key}' unexpectedly contains '${unexpected}'".toString(),
                    v.contains(unexpected))
        } else {
            assertFalse("Field '${key}' = '${v}' unexpectedly contains '${unexpected}'".toString(),
                    v.toString().contains(unexpected))
        }
    }

    @Then("the response field {string} should equal {string}")
    void fieldShouldEqual(String key, String expected) {
        def v = jsonPath(key)
        String actual = v == null ? "null" : v.toString()
        assertEquals("Field '${key}' mismatch".toString(), substituteVars(expected), actual)
    }

    @Then("the response field {string} should be a non-empty string")
    void fieldShouldBeNonEmptyString(String key) {
        def v = jsonPath(key)
        assertNotNull("Field '${key}' is null".toString(), v)
        assertFalse("Field '${key}' is empty".toString(), v.toString().isEmpty())
    }

    @Then("the response field {string} should be an empty array")
    void fieldShouldBeEmptyArray(String key) {
        def v = jsonPath(key)
        assertTrue("'${key}' is not a list".toString(), v instanceof List)
        assertEquals("'${key}' is not empty (size=${v.size()})".toString(), 0, v.size())
    }

    @Then("the response field {string} should match the UUID v4 pattern {string}")
    void fieldShouldMatchUuidV4(String key, String pattern) {
        String v = jsonPath(key)?.toString() ?: ""
        assertTrue("Field '${key}' = '${v}' does not match pattern '${pattern}'".toString(),
                v.matches(pattern))
    }

    @Then("the response body should equal {string}")
    void bodyShouldEqualStored(String name) {
        assertEquals("Stored body mismatch", storedResponses[name], lastBody)
    }

    // ═════ UI ASSERTIONS ══════════════════════════════════════════

    @Then("the element with data-testid {string} should exist")
    void elementShouldExist(String testId) {
        assertFalse("Element '${testId}' not found".toString(), allByTestId(testId).isEmpty())
    }

    @Then("the element with data-testid {string} should be a {string} element")
    void elementIsTagA(String testId, String tag) {
        assertEquals(tag.toLowerCase(), byTestId(testId).getTagName().toLowerCase())
    }

    @Then("the element with data-testid {string} should be an {string} element")
    void elementIsTagAn(String testId, String tag) {
        assertEquals(tag.toLowerCase(), byTestId(testId).getTagName().toLowerCase())
    }

    @Then("the element with data-testid {string} should have the {string} attribute")
    void elementHasAttribute(String testId, String attr) {
        String v = byTestId(testId).getAttribute(attr)
        assertNotNull("Element '${testId}' has no '${attr}' attribute".toString(), v)
    }

    @Then("the element with data-testid {string} should have placeholder {string}")
    void elementHasPlaceholder(String testId, String placeholder) {
        assertEquals(placeholder, byTestId(testId).getAttribute("placeholder"))
    }

    @Then("the element with data-testid {string} should have text {string}")
    void elementHasText(String testId, String text) {
        assertEquals(text, byTestId(testId).getText().trim())
    }

    @Then("the element with data-testid {string} should contain the text {string}")
    void elementContainsText(String testId, String text) {
        String actual = byTestId(testId).getText()
        assertTrue("Element '${testId}' text was '${actual}', expected to contain '${text}'".toString(),
                actual.contains(text))
    }

    @Then("the element with data-testid {string} should have inline style {string}")
    void elementHasInlineStyle(String testId, String style) {
        String actual = (byTestId(testId).getAttribute("style") ?: "").replaceAll("\\s+", "")
        String expected = style.replaceAll("\\s+", "")
        assertTrue("Style was '${actual}', expected to contain '${expected}'".toString(),
                actual.contains(expected))
    }

    @Then("the element with data-testid {string} should be visible")
    void elementShouldBeVisible(String testId) {
        assertTrue("Element '${testId}' not displayed".toString(), byTestId(testId).isDisplayed())
    }

    @Then("the element with id {string} should have CSS class {string}")
    void idHasClass(String id, String cls) {
        String classes = driver().findElement(By.id(id)).getAttribute("class") ?: ""
        assertTrue("Element id='${id}' classes='${classes}', missing '${cls}'".toString(),
                classes.split(/\s+/).contains(cls))
    }

    @Then("the element with id {string} should NOT have CSS class {string}")
    void idShouldNotHaveClass(String id, String cls) {
        String classes = driver().findElement(By.id(id)).getAttribute("class") ?: ""
        assertFalse("Element id='${id}' unexpectedly has class '${cls}'".toString(),
                classes.split(/\s+/).contains(cls))
    }

    @Then("the element with data-testid {string} should contain an option with text {string}")
    void selectContainsOptionWithText(String testId, String text) {
        List<WebElement> opts = driver().findElements(
                By.cssSelector("[data-testid='${testId}'] option"))
        assertTrue("Select '${testId}' missing option text='${text}'".toString(),
                opts.any { it.getText().trim() == text })
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
