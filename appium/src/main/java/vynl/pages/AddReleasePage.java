package vynl.pages;

import io.appium.java_client.AppiumBy;
import io.appium.java_client.ios.IOSDriver;

/**
 * The add-release form. Required: artist, title, genre. Optional: label, year.
 * Save stays disabled until the three required fields are non-empty.
 */
public class AddReleasePage extends BasePage {

    private static final String ARTIST_FIELD = "addRelease.artistField";
    private static final String TITLE_FIELD = "addRelease.titleField";
    private static final String GENRE_FIELD = "addRelease.genreField";
    private static final String LABEL_FIELD = "addRelease.labelField";
    private static final String YEAR_FIELD = "addRelease.yearField";
    private static final String SAVE_BUTTON = "addRelease.saveButton";
    private static final String CANCEL_BUTTON = "addRelease.cancelButton";
    private static final String STATUS_PICKER = "addRelease.statusPicker";

    public AddReleasePage(IOSDriver driver) {
        super(driver);
    }

    public AddReleasePage fillRequired(String artist, String title, String genre) {
        type(ARTIST_FIELD, artist);
        type(TITLE_FIELD, title);
        type(GENRE_FIELD, genre);
        return this;
    }

    public AddReleasePage setLabel(String label) {
        type(LABEL_FIELD, label);
        return this;
    }

    public AddReleasePage setYear(String year) {
        type(YEAR_FIELD, year);
        return this;
    }

    public AddReleasePage replaceTitle(String title) {
        clearAndType(TITLE_FIELD, title);
        return this;
    }

    /** Empties one of the text fields by its form label: "artist", "title", "genre". */
    public AddReleasePage clearField(String field) {
        findVisible(fieldId(field)).clear();
        return this;
    }

    /** Fills the three required fields except {@code skipped}, which stays empty. */
    public AddReleasePage fillRequiredExcept(String skipped, String artist, String title, String genre) {
        if (!"artist".equals(skipped)) type(ARTIST_FIELD, artist);
        if (!"title".equals(skipped)) type(TITLE_FIELD, title);
        if (!"genre".equals(skipped)) type(GENRE_FIELD, genre);
        return this;
    }

    /** Edit mode only: picks a segment of the Owned / Sold control by its label. */
    public AddReleasePage selectStatus(String status) {
        driver.findElement(AppiumBy.iOSClassChain(
                "**/XCUIElementTypeSegmentedControl[`name == '" + STATUS_PICKER + "'`]"
                        + "/XCUIElementTypeButton[`label == '" + status + "'`]")).click();
        return this;
    }

    /**
     * iOS 26 wraps toolbar buttons in an Other element with the same identifier that
     * always reports enabled, so the check targets the Button itself.
     */
    public boolean isSaveEnabled() {
        return isButtonEnabled(SAVE_BUTTON);
    }

    public boolean isStillOpen() {
        return isVisible(SAVE_BUTTON);
    }

    public CollectionPage save() {
        tap(SAVE_BUTTON);
        return new CollectionPage(driver);
    }

    /** Save from edit mode, which returns to the release detail screen. */
    public ReleaseDetailPage saveEdit() {
        tap(SAVE_BUTTON);
        return new ReleaseDetailPage(driver);
    }

    public CollectionPage cancel() {
        tap(CANCEL_BUTTON);
        return new CollectionPage(driver);
    }

    public ReleaseDetailPage cancelEdit() {
        tap(CANCEL_BUTTON);
        return new ReleaseDetailPage(driver);
    }

    private static String fieldId(String field) {
        switch (field) {
            case "artist": return ARTIST_FIELD;
            case "title": return TITLE_FIELD;
            case "genre": return GENRE_FIELD;
            default: throw new IllegalArgumentException("Unknown field: " + field);
        }
    }
}
