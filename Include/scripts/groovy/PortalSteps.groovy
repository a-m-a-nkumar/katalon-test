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

    static String baseUrl = "http://localhost:8000"
    static int lastStatus
    static Map<String, List<String>> lastHeaders = [:]
    static String lastBody = ""
    static Map<String, String> storedResponses = [:]
    static Map<String, String> storedVars = [:]
    static boolean browserOpen = false

    @Before
    void resetScenarioState() {
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

    private static WebDriver driver() {
        return DriverFactory.getWebDriver()
    }

    private static void openBrowser(String url) {
        if (browserOpen) {
            try { WebUI.closeBrowser() } catch (Exception ignored) {}
            browserOpen = false
        }
        WebUI.openBrowser(url)
        browserOpen = true
        WebUI.waitForPageLoad(10)
    }

    private static WebElement byTestId(String testId) {
        return driver().findElement(By.cssSelector("[data-testid='${testId}']"))
    }

    private static Object jsonBody() {
        return new JsonSlurper().parseText(lastBody)
    }

    // ─── Setup / Background ─────────────────────────────────────────

    @Given("the Project Provisioning Portal is running at {string}")
    void portalIsRunning(String url) {
        baseUrl = url
    }

    @Given("the Project Provisioning Portal API is running at {string}")
    void portalApiIsRunning(String url) {
        baseUrl = url
    }

    @Given("I have sent a POST request to {string} to clear all state")
    void resetAppState(String path) {
        sendPost(path, "")
    }

    @Given("I am on the landing page at {string}")
    void onLandingPage(String url) {
        openBrowser(url)
    }

    @Given("I have navigated to the wizard view")
    void navigateToWizard() {
        openBrowser(baseUrl + "/")
        driver().findElement(By.cssSelector("[data-testid='card-create']")).click()
        Thread.sleep(300)
    }

    @Given("I am on the wizard view at {string}")
    void onWizardView(String url) {
        openBrowser(url)
        driver().findElement(By.cssSelector("[data-testid='card-create']")).click()
        Thread.sleep(300)
    }

    // ─── Actions ───────────────────────────────────────────────────

    @When("I send a GET request to {string}")
    void sendGetStep(String path) {
        sendGet(path)
    }

    @When("I send a POST request to {string} with body:")
    void sendPostWithBody(String path, String body) {
        sendPost(path, body)
    }

    @When("I send a DELETE request to {string}")
    void sendDeleteStep(String path) {
        sendDelete(path)
    }

    @When("I remember the response field {string} as {string}")
    void rememberField(String fieldPath, String name) {
        def v = jsonBody()[fieldPath]
        storedVars[name] = v == null ? "" : v.toString()
    }

    @When("I navigate to {string} in the browser")
    void navigateBrowser(String url) {
        openBrowser(url)
    }

    @When("I click the element with data-testid {string}")
    void clickTestId(String testId) {
        driver().findElement(By.cssSelector("[data-testid='${testId}']")).click()
        Thread.sleep(300)
    }

    @When("I store the response body as {string}")
    void storeBody(String name) {
        storedResponses[name] = lastBody
    }

    @When("the page JavaScript has finished executing")
    void waitForJs() {
        Thread.sleep(500)
    }

    // ─── HTTP assertions ───────────────────────────────────────────

    @Then("the response status should be {int}")
    void statusShouldBe(int expected) {
        assertEquals("HTTP status mismatch. Body was: ${lastBody}".toString(), expected, lastStatus)
    }

    @Then("the response Content-Type should contain {string}")
    void contentTypeContains(String expected) {
        String ct = ""
        for (entry in lastHeaders.entrySet()) {
            if (entry.key != null && entry.key.equalsIgnoreCase("Content-Type")) {
                ct = entry.value.get(0)
                break
            }
        }
        assertTrue("Content-Type was '${ct}', expected to contain '${expected}'".toString(), ct.contains(expected))
    }

    @Then("the response body should contain {string}")
    void bodyContains(String fragment) {
        assertTrue("Body did not contain '${fragment}'. Body head: ${lastBody.take(500)}".toString(), lastBody.contains(fragment))
    }

    @Then("the response body should have a top-level key {string}")
    void bodyHasKey(String key) {
        def parsed = jsonBody()
        assertTrue("Body missing key '${key}'".toString(), parsed instanceof Map && parsed.containsKey(key))
    }

    @Then("the value of {string} should be a JSON array")
    void valueIsArray(String key) {
        assertTrue("'${key}' is not a list".toString(), jsonBody()[key] instanceof List)
    }

    @Then("the response field {string} should be a list of length {int}")
    void fieldListLength(String key, int len) {
        def v = jsonBody()[key]
        assertTrue("Field '${key}' is not a list".toString(), v instanceof List)
        assertEquals("Field '${key}' length mismatch".toString(), len, v.size())
    }

    @Then("the response field {string} should contain {string}")
    void fieldContains(String key, String expected) {
        def v = jsonBody()[key]
        if (v instanceof List) {
            assertTrue("List '${key}' = ${v} does not contain '${expected}'".toString(), v.contains(expected))
        } else {
            assertTrue("String '${key}' = '${v}' does not contain '${expected}'".toString(), v.toString().contains(expected))
        }
    }

    @Then("the response field {string} should NOT contain {string}")
    void fieldNotContains(String key, String unexpected) {
        def v = jsonBody()[key]
        if (v instanceof List) {
            assertFalse("List '${key}' unexpectedly contains '${unexpected}'".toString(), v.contains(unexpected))
        } else {
            assertFalse("String '${key}' = '${v}' unexpectedly contains '${unexpected}'".toString(), v.toString().contains(unexpected))
        }
    }

    @Then("the response field {string} should equal {string}")
    void fieldEquals(String key, String expected) {
        assertEquals("Field '${key}' mismatch".toString(), expected, jsonBody()[key].toString())
    }

    @Then("the response field {string} should be a non-empty string")
    void fieldNonEmpty(String key) {
        def v = jsonBody()[key]
        assertNotNull("Field '${key}' is null".toString(), v)
        assertFalse("Field '${key}' is empty".toString(), v.toString().isEmpty())
    }

    @Then("the response field {string} should be an empty array")
    void fieldEmptyArray(String key) {
        def v = jsonBody()[key]
        assertTrue("Field '${key}' is not a list".toString(), v instanceof List)
        assertEquals("Field '${key}' is not empty".toString(), 0, v.size())
    }

    @Then("the response field {string} should match the UUID v4 pattern {string}")
    void fieldMatchesPattern(String key, String pattern) {
        String v = jsonBody()[key].toString()
        assertTrue("Field '${key}' = '${v}' does not match pattern".toString(), v.matches(pattern))
    }

    @Then("the response body should equal {string}")
    void bodyEqualsStored(String name) {
        assertEquals("Stored response body mismatch".toString(), storedResponses[name], lastBody)
    }

    // ─── UI assertions ─────────────────────────────────────────────

    @Then("the element with data-testid {string} should contain the text {string}")
    void elementContainsText(String testId, String text) {
        String actual = byTestId(testId).getText()
        assertTrue("Element '${testId}' text was '${actual}', expected to contain '${text}'".toString(), actual.contains(text))
    }

    @Then("the element with data-testid {string} should exist")
    void elementExists(String testId) {
        assertFalse("Element '${testId}' not found".toString(), driver().findElements(By.cssSelector("[data-testid='${testId}']")).isEmpty())
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

    @Then("the element with data-testid {string} should have inline style {string}")
    void elementHasInlineStyle(String testId, String style) {
        String actual = (byTestId(testId).getAttribute("style") ?: "").replaceAll("\\s+", "")
        String expected = style.replaceAll("\\s+", "")
        assertTrue("Style was '${actual}', expected to contain '${expected}'".toString(), actual.contains(expected))
    }

    @Then("the element with data-testid {string} should be visible")
    void elementIsVisible(String testId) {
        assertTrue("Element '${testId}' not displayed".toString(), byTestId(testId).isDisplayed())
    }

    @Then("the element with id {string} should have CSS class {string}")
    void elementHasClass(String id, String cls) {
        String classes = driver().findElement(By.id(id)).getAttribute("class") ?: ""
        assertTrue("Element id='${id}' has classes '${classes}', missing '${cls}'".toString(), classes.split(/\s+/).contains(cls))
    }

    @Then("the element with id {string} should NOT have CSS class {string}")
    void elementNotHasClass(String id, String cls) {
        String classes = driver().findElement(By.id(id)).getAttribute("class") ?: ""
        assertFalse("Element id='${id}' unexpectedly has class '${cls}'".toString(), classes.split(/\s+/).contains(cls))
    }

    @Then("the element with data-testid {string} should contain an option with text {string}")
    void selectContainsOption(String testId, String text) {
        List<WebElement> options = driver().findElements(By.cssSelector("[data-testid='${testId}'] option"))
        assertTrue("Select '${testId}' does not contain option '${text}'".toString(), options.any { it.getText().trim() == text })
    }

    @Then("the first option of the element with data-testid {string} should have value {string}")
    void firstOptionValue(String testId, String value) {
        List<WebElement> options = driver().findElements(By.cssSelector("[data-testid='${testId}'] option"))
        assertFalse("Select '${testId}' has no options".toString(), options.isEmpty())
        assertEquals(value, options[0].getAttribute("value"))
    }

    @Then("the first option of the element with data-testid {string} should have text {string}")
    void firstOptionText(String testId, String text) {
        List<WebElement> options = driver().findElements(By.cssSelector("[data-testid='${testId}'] option"))
        assertFalse("Select '${testId}' has no options".toString(), options.isEmpty())
        assertEquals(text, options[0].getText().trim())
    }

    @Then("the element with data-testid {string} should contain exactly {int} options")
    void selectOptionCount(String testId, int count) {
        List<WebElement> options = driver().findElements(By.cssSelector("[data-testid='${testId}'] option"))
        assertEquals(count, options.size())
    }

    // ─── HTTP helpers ──────────────────────────────────────────────

    private static String substituteVars(String path) {
        String result = path
        for (entry in storedVars.entrySet()) {
            result = result.replace("{${entry.key}}".toString(), entry.value)
        }
        return result
    }

    private static void sendGet(String path) {
        String resolved = substituteVars(path)
        URL url = resolved.startsWith("http") ? new URL(resolved) : new URL(baseUrl + resolved)
        HttpURLConnection conn = (HttpURLConnection) url.openConnection()
        conn.setRequestMethod("GET")
        conn.setConnectTimeout(5000)
        conn.setReadTimeout(5000)
        readResponse(conn)
    }

    private static void sendPost(String path, String body) {
        String resolved = substituteVars(path)
        URL url = resolved.startsWith("http") ? new URL(resolved) : new URL(baseUrl + resolved)
        HttpURLConnection conn = (HttpURLConnection) url.openConnection()
        conn.setRequestMethod("POST")
        conn.setDoOutput(true)
        conn.setRequestProperty("Content-Type", "application/json")
        conn.setConnectTimeout(5000)
        conn.setReadTimeout(5000)
        conn.getOutputStream().withWriter("UTF-8") { it.write(body ?: "") }
        readResponse(conn)
    }

    private static void sendDelete(String path) {
        String resolved = substituteVars(path)
        URL url = resolved.startsWith("http") ? new URL(resolved) : new URL(baseUrl + resolved)
        HttpURLConnection conn = (HttpURLConnection) url.openConnection()
        conn.setRequestMethod("DELETE")
        conn.setConnectTimeout(5000)
        conn.setReadTimeout(5000)
        readResponse(conn)
    }

    private static void readResponse(HttpURLConnection conn) {
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
