package vynl.pages;

import io.appium.java_client.AppiumBy;
import io.appium.java_client.ios.IOSDriver;
import org.openqa.selenium.WebElement;

/**
 * Shared plumbing for page objects: holds the driver and wraps the few
 * interactions every screen needs. Element lookup still relies on the implicit
 * wait configured in Hooks — that gets replaced by explicit waits in the next
 * roadmap step, and this is the single place it will change.
 */
public abstract class BasePage {

    protected final IOSDriver driver;

    protected BasePage(IOSDriver driver) {
        this.driver = driver;
    }

    protected WebElement find(String accessibilityId) {
        return driver.findElement(AppiumBy.accessibilityId(accessibilityId));
    }

    protected void tap(String accessibilityId) {
        find(accessibilityId).click();
    }

    protected void type(String accessibilityId, String text) {
        find(accessibilityId).sendKeys(text);
    }

    protected boolean isEnabled(String accessibilityId) {
        return find(accessibilityId).isEnabled();
    }
}
