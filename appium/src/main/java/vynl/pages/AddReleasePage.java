package vynl.pages;

import io.appium.java_client.AppiumBy;
import io.appium.java_client.ios.IOSDriver;
import org.openqa.selenium.By;
import org.openqa.selenium.support.ui.ExpectedConditions;
import vynl.config.Config;

import java.util.List;

/**
 * The add-release form (also the edit form). Required: artist, title and at least
 * one genre (DR-4: genre chips). Optional: label, year.
 * Save stays disabled until all three are there.
 */
public class AddReleasePage extends BasePage {

    private static final String ARTIST_FIELD = "addRelease.artistField";
    private static final String TITLE_FIELD = "addRelease.titleField";
    private static final String GENRE_INPUT = "addRelease.genreInput";
    private static final String GENRE_CHIP = "addRelease.genreChip";
    private static final String GENRE_SUGGESTION = "addRelease.genreSuggestion";
    private static final String GENRE_ADD_NEW = "addRelease.genreAddNewButton";
    private static final String GENRE_REMOVE = "addRelease.genreRemoveButton";
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
        addGenre(genre);
        return this;
    }

    // --- genres (DR-4) ---

    /** Types a genre and adds it with the keyboard's return; ends when its chip shows. */
    public AddReleasePage addGenre(String genre) {
        typeGenre(genre + "\n");
        waitFor(ExpectedConditions.presenceOfElementLocated(genreChip(genre)));
        return this;
    }

    /** Types into the genre field without adding, so suggestions show. */
    public AddReleasePage typeGenre(String text) {
        type(GENRE_INPUT, text);
        return this;
    }

    /** Adds what's typed through the "Add \"…\"" row (a genre the collection doesn't have yet). */
    public AddReleasePage tapAddNewGenre() {
        scrollToAndTap(GENRE_ADD_NEW);
        return this;
    }

    public boolean isSuggested(String genre) {
        return isVisible(AppiumBy.iOSNsPredicateString(
                "name == '" + GENRE_SUGGESTION + "' AND label == '" + genre + "'"), Config.elementTimeout());
    }

    public AddReleasePage chooseSuggestion(String genre) {
        driver.findElement(AppiumBy.iOSNsPredicateString(
                "name == '" + GENRE_SUGGESTION + "' AND label == '" + genre + "'")).click();
        return this;
    }

    public AddReleasePage removeGenre(String genre) {
        driver.findElement(AppiumBy.iOSNsPredicateString(
                "name == '" + GENRE_REMOVE + "' AND label == 'Remove " + genre + "'")).click();
        return this;
    }

    /** The chips in the form, in their order. */
    public List<String> genreChips() {
        return labelsOf(GENRE_CHIP);
    }

    /**
     * Case-insensitive: typing "dub techno" when "Dub Techno" exists gives a chip in
     * the collection's spelling. Callers that care about the spelling assert the
     * chips themselves; this only waits for the add to land.
     */
    private static By genreChip(String genre) {
        return AppiumBy.iOSNsPredicateString("name == '" + GENRE_CHIP + "' AND label ==[c] '" + genre + "'");
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

    /** Empties one of the text fields by its form label: "artist", "title". */
    public AddReleasePage clearField(String field) {
        findVisible(fieldId(field)).clear();
        return this;
    }

    /** Fills the three required fields except {@code skipped}, which stays empty. */
    public AddReleasePage fillRequiredExcept(String skipped, String artist, String title, String genre) {
        if (!"artist".equals(skipped)) type(ARTIST_FIELD, artist);
        if (!"title".equals(skipped)) type(TITLE_FIELD, title);
        if (!"genre".equals(skipped)) addGenre(genre);
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
            default: throw new IllegalArgumentException("Unknown field: " + field);
        }
    }
}
