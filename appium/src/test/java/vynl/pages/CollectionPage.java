package vynl.pages;

import io.appium.java_client.AppiumBy;
import io.appium.java_client.ios.IOSDriver;
import org.openqa.selenium.By;
import org.openqa.selenium.NoSuchElementException;

/** The collection screen — list of releases, empty state, add entry points. */
public class CollectionPage extends BasePage {

    private static final String LIST = "collection.list";
    private static final String RELEASE_ROW = "collection.releaseRow";
    private static final String ADD_RELEASE_BUTTON = "collection.addReleaseButton";
    private static final String TOOLBAR_ADD_BUTTON = "collection.toolbarAddButton";

    public CollectionPage(IOSDriver driver) {
        super(driver);
    }

    public AddReleasePage tapAddFromEmptyState() {
        tap(ADD_RELEASE_BUTTON);
        return new AddReleasePage(driver);
    }

    public AddReleasePage tapToolbarAdd() {
        tap(TOOLBAR_ADD_BUTTON);
        return new AddReleasePage(driver);
    }

    /**
     * Row text resolves as StaticText in XCUITest, so we match the label rather
     * than the row container, whose element type is ambiguous.
     */
    public boolean isReleaseVisible(String artist) {
        try {
            return driver.findElement(staticTextWithLabel(artist)).isDisplayed();
        } catch (NoSuchElementException e) {
            return false;
        }
    }

    public void openRelease(String artist) {
        driver.findElement(staticTextWithLabel(artist)).click();
    }

    private static By staticTextWithLabel(String label) {
        return AppiumBy.iOSNsPredicateString(
                "type == 'XCUIElementTypeStaticText' AND label == '" + label + "'");
    }
}
