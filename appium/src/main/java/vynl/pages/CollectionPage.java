package vynl.pages;

import io.appium.java_client.ios.IOSDriver;
import org.openqa.selenium.support.ui.ExpectedConditions;
import vynl.config.Config;

/** The collection screen — list of releases, empty state, add entry points. */
public class CollectionPage extends BasePage {

    private static final String LIST = "collection.list";
    private static final String RELEASE_ROW = "collection.releaseRow";
    private static final String ADD_RELEASE_BUTTON = "collection.addReleaseButton";
    private static final String TOOLBAR_ADD_BUTTON = "collection.toolbarAddButton";
    private static final String MOODS_BUTTON = "collection.moodsButton";

    public CollectionPage(IOSDriver driver) {
        super(driver);
    }

    public AddReleasePage tapAddFromEmptyState() {
        tap(ADD_RELEASE_BUTTON);
        return new AddReleasePage(driver);
    }

    /** The gear in the Collection toolbar pushes the mood vocabulary. */
    public MoodVocabularyPage openMoods() {
        tap(MOODS_BUTTON);
        return new MoodVocabularyPage(driver);
    }

    /**
     * DR-3: the header's actions sit together on the right. "Right" = the button's
     * left edge is past the middle of the screen; reads the Button, not its iOS 26
     * toolbar wrapper (same frame, but the Button is the one users hit).
     */
    public boolean areHeaderActionsOnTheRight() {
        int screenWidth = driver.manage().window().getSize().getWidth();
        for (String id : new String[]{MOODS_BUTTON, TOOLBAR_ADD_BUTTON}) {
            int x = waitFor(ExpectedConditions.presenceOfElementLocated(button(id))).getRect().getX();
            if (x < screenWidth / 2) return false;
        }
        return true;
    }

    public AddReleasePage tapToolbarAdd() {
        tap(TOOLBAR_ADD_BUTTON);
        return new AddReleasePage(driver);
    }

    /**
     * The empty state has no identifier of its own, but its add CTA
     * ({@code collection.addReleaseButton}) only exists inside it.
     */
    public boolean isEmptyStateVisible() {
        return isVisible(ADD_RELEASE_BUTTON);
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

    public ReleaseDetailPage openRelease(String artist) {
        waitFor(ExpectedConditions.elementToBeClickable(staticTextWithLabel(artist))).click();
        return new ReleaseDetailPage(driver);
    }
}
