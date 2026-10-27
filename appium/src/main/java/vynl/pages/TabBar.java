package vynl.pages;

import io.appium.java_client.AppiumBy;
import io.appium.java_client.ios.IOSDriver;
import org.openqa.selenium.By;
import org.openqa.selenium.support.ui.ExpectedConditions;

/**
 * The app's tab bar. A component rather than a screen: it is present on top of
 * whichever tab is showing.
 *
 * <p>Tab items carry no identifiers of ours, and their {@code name} changes with
 * selection state (the label on one render, the SF Symbol name on another), so
 * they are located by label, scoped to the tab bar. Scoping matters: the
 * navigation title "Collection" is also a StaticText with that label.
 */
public class TabBar extends BasePage {

    public TabBar(IOSDriver driver) {
        super(driver);
    }

    public CollectionPage openCollection() {
        tapTab("Collection");
        return new CollectionPage(driver);
    }

    public CratesPage openCrates() {
        tapTab("Crates");
        return new CratesPage(driver);
    }

    /** A selected tab item reports value "1" and the Selected trait. */
    public boolean isSelected(String tab) {
        return "1".equals(waitFor(ExpectedConditions.presenceOfElementLocated(tabItem(tab)))
                .getAttribute("value"));
    }

    private void tapTab(String tab) {
        waitFor(ExpectedConditions.elementToBeClickable(tabItem(tab))).click();
    }

    private static By tabItem(String label) {
        return AppiumBy.iOSClassChain(
                "**/XCUIElementTypeTabBar/**/XCUIElementTypeButton[`label == \"" + label + "\"`]");
    }
}
