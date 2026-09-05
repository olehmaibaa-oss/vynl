package vynl.pages;

import io.appium.java_client.AppiumBy;
import io.appium.java_client.ios.IOSDriver;
import org.openqa.selenium.By;
import vynl.Config;

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
        return isVisible(staticTextWithLabel(artist), Config.elementTimeout());
    }

    /** Short budget — for asserting a release is gone, e.g. after a delete. */
    public boolean isReleaseGone(String artist) {
        return isGone(staticTextWithLabel(artist), Config.absenceTimeout());
    }

    public void openRelease(String artist) {
        waitFor(org.openqa.selenium.support.ui.ExpectedConditions
                .elementToBeClickable(staticTextWithLabel(artist))).click();
    }

    private static By staticTextWithLabel(String label) {
        return AppiumBy.iOSNsPredicateString(
                "type == 'XCUIElementTypeStaticText' AND label == '" + label + "'");
    }
}
