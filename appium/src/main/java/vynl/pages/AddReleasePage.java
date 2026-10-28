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
    private static final String FORM = "addRelease.form";

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

    // --- cover (DR-5) ---

    private static final String COVER_SLOT = "addRelease.coverSlot";
    private static final String LIBRARY_BUTTON = "addRelease.libraryButton";
    private static final String CAMERA_BUTTON = "addRelease.cameraButton";
    private static final String REMOVE_COVER_BUTTON = "addRelease.removeCoverButton";
    /** A photo cell in the system photo picker (runs out of process, no ids of ours). */
    private static final By PICKER_PHOTO = AppiumBy.iOSNsPredicateString(
            "name == 'PXGGridLayout-Info' AND label BEGINSWITH 'Photo'");

    /** "placeholder" or "image": the slot's accessibility value. */
    public String coverKind() {
        return find(COVER_SLOT).getAttribute("value");
    }

    /** The slot's label, "Artist, Title": what the generated sleeve is built from. */
    public String coverName() {
        return find(COVER_SLOT).getAttribute("label");
    }

    /**
     * Opens the system photo picker and takes the newest photo; waits until the
     * slot shows it. The library must hold a photo (CoverSteps adds the fixture).
     */
    public AddReleasePage pickNewestLibraryPhoto() {
        tap(LIBRARY_BUTTON);
        // The picker is another process shown in ours: its cells report
        // visible=false and an element click goes nowhere. A tap at the cell's
        // centre does land.
        org.openqa.selenium.Rectangle cell =
                waitFor(ExpectedConditions.presenceOfElementLocated(PICKER_PHOTO)).getRect();
        driver.executeScript("mobile: tap", java.util.Map.of(
                "x", cell.getX() + cell.getWidth() / 2,
                "y", cell.getY() + cell.getHeight() / 2));
        new org.openqa.selenium.support.ui.WebDriverWait(driver, java.time.Duration.ofSeconds(15))
                .until(d -> "image".equals(coverKind()));
        return this;
    }

    public AddReleasePage removeCover() {
        tap(REMOVE_COVER_BUTTON);
        return this;
    }

    public boolean isCameraOffered() {
        return !isGone(byId(CAMERA_BUTTON), Config.absenceTimeout());
    }

    /**
     * The optional fields sit below the Cover section since DR-5, so on a short
     * screen (or with the keyboard up) they need a scroll first.
     */
    public AddReleasePage setLabel(String label) {
        typeBelowFold(LABEL_FIELD, label);
        return this;
    }

    public AddReleasePage setYear(String year) {
        typeBelowFold(YEAR_FIELD, year);
        return this;
    }

    private void typeBelowFold(String fieldId, String text) {
        org.openqa.selenium.WebElement field = scrollTo(byId(fieldId), FORM);
        field.click();
        field.sendKeys(text);
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
