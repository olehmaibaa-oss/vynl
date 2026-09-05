package vynl.pages;

import io.appium.java_client.AppiumBy;
import io.appium.java_client.ios.IOSDriver;
import org.openqa.selenium.By;
import org.openqa.selenium.TimeoutException;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;
import vynl.config.Config;

import java.time.Duration;

/**
 * Shared plumbing for page objects: holds the driver and wraps the few
 * interactions every screen needs.
 *
 * <p>Every lookup here waits explicitly. There is deliberately no implicit
 * wait configured on the driver: mixing the two makes timings unpredictable,
 * because the implicit wait applies inside each polling attempt of the
 * explicit one.
 */
public abstract class BasePage {

    protected final IOSDriver driver;
    private final WebDriverWait wait;

    protected BasePage(IOSDriver driver) {
        this.driver = driver;
        this.wait = new WebDriverWait(driver, Config.elementTimeout());
    }

    /** Waits for the element to exist in the hierarchy. */
    protected WebElement find(String accessibilityId) {
        return waitFor(ExpectedConditions.presenceOfElementLocated(byId(accessibilityId)));
    }

    /** Waits for the element to be rendered and non-zero sized. */
    protected WebElement findVisible(String accessibilityId) {
        return waitFor(ExpectedConditions.visibilityOfElementLocated(byId(accessibilityId)));
    }

    /** Waits for the element to be visible and enabled, then taps it. */
    protected void tap(String accessibilityId) {
        waitFor(ExpectedConditions.elementToBeClickable(byId(accessibilityId))).click();
    }

    protected void type(String accessibilityId, String text) {
        findVisible(accessibilityId).sendKeys(text);
    }

    protected boolean isEnabled(String accessibilityId) {
        return find(accessibilityId).isEnabled();
    }

    protected boolean isVisible(String accessibilityId) {
        return isVisible(byId(accessibilityId), Config.elementTimeout());
    }

    /**
     * Visibility check with an explicit budget. Pass {@link Config#absenceTimeout()}
     * when the expected answer is "no" — a negative check paid at the full
     * element timeout makes a suite crawl.
     */
    protected boolean isVisible(By locator, Duration timeout) {
        try {
            new WebDriverWait(driver, timeout)
                    .until(ExpectedConditions.visibilityOfElementLocated(locator));
            return true;
        } catch (TimeoutException e) {
            return false;
        }
    }

    /** Waits for the element to disappear (or never appear). */
    protected boolean isGone(By locator, Duration timeout) {
        try {
            return new WebDriverWait(driver, timeout)
                    .until(ExpectedConditions.invisibilityOfElementLocated(locator));
        } catch (TimeoutException e) {
            return false;
        }
    }

    protected <T> T waitFor(java.util.function.Function<org.openqa.selenium.WebDriver, T> condition) {
        return wait.until(condition);
    }

    protected static By byId(String accessibilityId) {
        return AppiumBy.accessibilityId(accessibilityId);
    }
}
