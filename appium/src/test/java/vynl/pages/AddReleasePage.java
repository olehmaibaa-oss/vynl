package vynl.pages;

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

    public boolean isSaveEnabled() {
        return isEnabled(SAVE_BUTTON);
    }

    public CollectionPage save() {
        tap(SAVE_BUTTON);
        return new CollectionPage(driver);
    }

    public CollectionPage cancel() {
        tap(CANCEL_BUTTON);
        return new CollectionPage(driver);
    }
}
