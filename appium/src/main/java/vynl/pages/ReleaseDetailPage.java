package vynl.pages;

import io.appium.java_client.AppiumBy;
import io.appium.java_client.ios.IOSDriver;
import org.openqa.selenium.By;
import org.openqa.selenium.support.ui.ExpectedConditions;
import vynl.config.Config;

import java.util.List;

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
    private static final String CONFIRM_DELETE_BUTTON = "releaseDetail.confirmDeleteButton";
    private static final String CANCEL_DELETE_BUTTON = "releaseDetail.cancelDeleteButton";
    private static final String TRACK_ROW = "releaseDetail.trackRow";
    private static final String TRACK_MOODS = "releaseDetail.trackMoods";
    private static final String GENRE_CHIP = "releaseDetail.genreChip";

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

    /** DR-4: the genre chips, in display order (A–Z). Waits for the first chip. */
    public List<String> genres() {
        waitFor(ExpectedConditions.visibilityOfNestedElementsLocatedBy(byId(VIEW), byId(GENRE_CHIP)));
        return driver.findElement(byId(VIEW)).findElements(byId(GENRE_CHIP)).stream()
                .map(e -> e.getAttribute("label"))
                .toList();
    }

    public boolean showsGenre(String genre) {
        return isVisibleWithin(byId(VIEW), AppiumBy.iOSNsPredicateString(
                "name == '" + GENRE_CHIP + "' AND label == '" + genre + "'"), Config.elementTimeout());
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
    //
    // A track row is a Button identified as releaseDetail.trackRow whose label
    // joins position and title: "A1, Magneze". Rows are matched on that label —
    // exactly for position + title, by prefix when only the position matters.
    // Positions are unique within a release in every scenario that uses this.

    /** The empty-state call to action, shown when the release has no tracks. */
    public boolean isAddTrackCtaVisible() {
        return isVisible(ADD_TRACK_BUTTON);
    }

    public boolean isTrackListed(String position, String title) {
        return isVisible(trackRow(position, title), Config.elementTimeout());
    }

    /** Short budget — the expected answer is "it's gone". */
    public boolean isTrackGone(String position, String title) {
        return isGone(trackRow(position, title), Config.absenceTimeout());
    }

    public boolean isPositionListed(String position) {
        return isVisible(trackRowAt(position), Config.elementTimeout());
    }

    /** Short budget — the expected answer is "it's gone". */
    public boolean isPositionGone(String position) {
        return isGone(trackRowAt(position), Config.absenceTimeout());
    }

    /** Positions of every listed track, in on-screen order. */
    public List<String> trackPositions() {
        return labelsOf(TRACK_ROW).stream()
                .map(label -> label.split(", ", 2)[0])
                .toList();
    }

    /**
     * A track's moods as the row exposes them: the row's accessibility value,
     * e.g. "deep, hypnotic". The label stays "A1, Magneze" on purpose, so moods
     * never break a match on the track's identity. Empty when it has none.
     */
    public String moodsOf(String position) {
        String value = waitFor(ExpectedConditions.presenceOfElementLocated(trackRowAt(position)))
                .getAttribute("value");
        return value == null ? "" : value;
    }

    /** No mood value on the row and no mood line rendered. Short budget for the second half. */
    public boolean showsNoMoods(String position) {
        return moodsOf(position).isEmpty() && isGone(byId(TRACK_MOODS), Config.absenceTimeout());
    }

    /** Tapping a row opens that track in the form, pre-filled. */
    public TrackFormPage openTrack(String position) {
        waitFor(ExpectedConditions.elementToBeClickable(trackRowAt(position))).click();
        return new TrackFormPage(driver);
    }

    /** Swipe the row left and tap its revealed delete action. */
    public void swipeDeleteTrack(String position) {
        swipeToDelete(trackRowAt(position));
    }

    private static By trackRow(String position, String title) {
        return AppiumBy.iOSNsPredicateString(
                "name == '" + TRACK_ROW + "' AND label == '" + position + ", " + title + "'");
    }

    private static By trackRowAt(String position) {
        return AppiumBy.iOSNsPredicateString(
                "name == '" + TRACK_ROW + "' AND label BEGINSWITH '" + position + ", '");
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
    public ReleaseDetailPage tapDelete() {
        tap(DELETE_BUTTON);
        return this;
    }

    // --- delete confirmation (.alert, deliberately not .confirmationDialog, so
    //     its buttons carry our identifiers) ---

    public boolean isDeleteConfirmationVisible() {
        return isVisible(CONFIRM_DELETE_BUTTON);
    }

    /** Short budget — the expected answer is "it's gone". */
    public boolean isDeleteConfirmationGone() {
        return isGone(byId(CONFIRM_DELETE_BUTTON), Config.absenceTimeout());
    }

    /** Confirms; the app deletes the release and pops back to the collection. */
    public CollectionPage confirmDelete() {
        tap(CONFIRM_DELETE_BUTTON);
        return new CollectionPage(driver);
    }

    public ReleaseDetailPage cancelDelete() {
        tap(CANCEL_DELETE_BUTTON);
        return this;
    }

    /** Pops back to the collection through the navigation bar. */
    public CollectionPage goBack() {
        driver.navigate().back();
        return new CollectionPage(driver);
    }

    /** Empty-state add-track CTA. */
    public TrackFormPage tapAddTrack() {
        tap(ADD_TRACK_BUTTON);
        return new TrackFormPage(driver);
    }

    /** Toolbar add-track control, available whether or not tracks exist. */
    public TrackFormPage tapToolbarAddTrack() {
        tap(TOOLBAR_ADD_TRACK_BUTTON);
        return new TrackFormPage(driver);
    }
}
