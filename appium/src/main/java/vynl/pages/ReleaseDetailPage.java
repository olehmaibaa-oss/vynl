package vynl.pages;

import io.appium.java_client.ios.IOSDriver;
import vynl.config.Config;

/**
 * The release detail screen: the release's values, its track list, and the
 * entry points to editing, deleting and adding tracks.
 *
 * <p><b>How values are asserted.</b> Individual value labels carry no
 * accessibility identifiers, so they are matched by their StaticText label.
 * A SwiftUI {@code LabeledContent} does not expose the bare value: the field
 * "Artist" holding "Surgeon" surfaces as a single element labelled
 * {@code "Artist, Surgeon"}. Assertions therefore go through
 * {@link #showsField(String, String)} rather than searching for the raw value.
 *
 * <p><b>Why the container scope.</b> {@code ReleaseDetailView} sets the
 * navigation title to the release title, so that string exists twice on
 * screen: once as the navigation bar's StaticText, once inside the body. All
 * lookups here are nested inside {@code releaseDetail.view}, which contains the
 * body only. No index-based locators.
 */
public class ReleaseDetailPage extends BasePage {

    private static final String VIEW = "releaseDetail.view";
    private static final String ADD_TRACK_BUTTON = "releaseDetail.addTrackButton";
    private static final String TOOLBAR_ADD_TRACK_BUTTON = "releaseDetail.toolbarAddTrackButton";
    private static final String EDIT_BUTTON = "releaseDetail.editButton";
    private static final String DELETE_BUTTON = "releaseDetail.deleteButton";

    /** What an empty optional field renders as. */
    public static final String EMPTY_PLACEHOLDER = "—";

    public ReleaseDetailPage(IOSDriver driver) {
        super(driver);
    }

    public boolean isDisplayed() {
        return isVisible(VIEW);
    }

    /**
     * Whether the given field shows the given value, e.g.
     * {@code showsField("Artist", "Surgeon")}.
     */
    public boolean showsField(String field, String value) {
        return isVisibleWithin(byId(VIEW), staticTextWithLabel(fieldLabel(field, value)),
                Config.elementTimeout());
    }

    /** Whether an optional field renders the empty placeholder. */
    public boolean showsEmptyField(String field) {
        return showsField(field, EMPTY_PLACEHOLDER);
    }

    /**
     * How a {@code LabeledContent} pair surfaces to XCUITest: the field name
     * and its value joined by a comma and a space.
     */
    private static String fieldLabel(String field, String value) {
        return field + ", " + value;
    }

    // --- tracks ---

    /** The empty-state call to action, shown when the release has no tracks. */
    public boolean isAddTrackCtaVisible() {
        return isVisible(ADD_TRACK_BUTTON);
    }

    // --- entry points ---

    public boolean isEditAvailable() {
        return isVisible(EDIT_BUTTON);
    }

    public boolean isToolbarAddTrackAvailable() {
        return isVisible(TOOLBAR_ADD_TRACK_BUTTON);
    }

    // --- navigation ---

    /** Opens the release in the edit form, which is the add-release form in edit mode. */
    public AddReleasePage tapEdit() {
        tap(EDIT_BUTTON);
        return new AddReleasePage(driver);
    }

    /** Opens the delete confirmation alert. */
    public void tapDelete() {
        tap(DELETE_BUTTON);
    }

    /** Empty-state add-track CTA. */
    public void tapAddTrack() {
        tap(ADD_TRACK_BUTTON);
    }

    /** Toolbar add-track control, available whether or not tracks exist. */
    public void tapToolbarAddTrack() {
        tap(TOOLBAR_ADD_TRACK_BUTTON);
    }
}
