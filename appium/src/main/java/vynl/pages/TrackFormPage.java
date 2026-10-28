package vynl.pages;

import io.appium.java_client.AppiumBy;
import io.appium.java_client.ios.IOSDriver;
import org.openqa.selenium.By;
import vynl.config.Config;

/**
 * The add / edit track sheet. Required: position, title. Optional: bpm, key
 * (DR-6: picked on the Camelot wheel, a pushed screen).
 * Save stays disabled until both required fields are non-empty.
 *
 * <p>The bpm field strips non-digits as you type ({@code .onChange} filter in
 * {@code TrackFormView}), independent of the number-pad keyboard — so typing
 * letters through the driver is a real check, not one the keyboard makes moot.
 */
public class TrackFormPage extends BasePage {

    private static final String POSITION_FIELD = "trackForm.positionField";
    private static final String TITLE_FIELD = "trackForm.titleField";
    private static final String BPM_FIELD = "trackForm.bpmField";
    private static final String KEY_BUTTON = "trackForm.keyButton";
    private static final String SEGMENT = "camelot.segment";
    private static final String CLEAR_KEY = "camelot.clearButton";
    /** The key button's label when no key is set. */
    public static final String NO_KEY = "Key";
    private static final String SAVE_BUTTON = "trackForm.saveButton";
    private static final String CANCEL_BUTTON = "trackForm.cancelButton";
    /** E2-S6: one chip per mood, told apart by label; Selected when on. */
    private static final String MOOD_CHIP = "trackForm.moodChip";
    private static final String MOOD_GROUP = "trackForm.moodGroup";
    /** The form's own list, for scrolling to rows the List hasn't built yet. */
    private static final String FORM = "trackForm.form";

    public TrackFormPage(IOSDriver driver) {
        super(driver);
    }

    public TrackFormPage setPosition(String position) {
        type(POSITION_FIELD, position);
        return this;
    }

    public TrackFormPage setTitle(String title) {
        type(TITLE_FIELD, title);
        return this;
    }

    /** For edit mode, where the title field opens pre-filled. */
    public TrackFormPage replaceTitle(String title) {
        clearAndType(TITLE_FIELD, title);
        return this;
    }

    public TrackFormPage setBpm(String bpm) {
        type(BPM_FIELD, bpm);
        return this;
    }

    // --- key (DR-6) ---

    /** Opens the wheel, taps the segment for a Camelot code ("8A"); the wheel closes on a pick. */
    public TrackFormPage pickKey(String camelot) {
        openKeyPicker();
        driver.findElement(segment(camelot)).click();
        find(KEY_BUTTON);
        return this;
    }

    public TrackFormPage openKeyPicker() {
        scrollToAndTap(KEY_BUTTON);
        waitFor(org.openqa.selenium.support.ui.ExpectedConditions.presenceOfElementLocated(byId(SEGMENT)));
        return this;
    }

    /** On the open wheel: "Clear" removes the key and closes the wheel. */
    public TrackFormPage clearKey() {
        openKeyPicker();
        tap(CLEAR_KEY);
        find(KEY_BUTTON);
        return this;
    }

    /** Labels of the wheel's segments ("1A · Abm", …). The wheel must be open. */
    public java.util.List<String> keySegments() {
        return labelsOf(SEGMENT);
    }

    /** The segment carrying the Selected trait, or null. The wheel must be open. */
    public String selectedSegment() {
        return driver.findElements(byId(SEGMENT)).stream()
                .filter(e -> e.isSelected())
                .map(e -> e.getAttribute("label"))
                .findFirst().orElse(null);
    }

    /** Leaves the wheel without picking (system back button). */
    public TrackFormPage closeKeyPicker() {
        driver.findElement(AppiumBy.accessibilityId("BackButton")).click();
        find(KEY_BUTTON);
        return this;
    }

    /** The mood group headers in on-screen order, read by scrolling the form. */
    public java.util.List<String> moodGroups() {
        java.util.List<String> seen = new java.util.ArrayList<>();
        for (int i = 0; i < 12; i++) {
            for (org.openqa.selenium.WebElement e : driver.findElements(byId(MOOD_GROUP))) {
                String label = e.getAttribute("label");
                if (!seen.contains(label)) seen.add(label);
            }
            if (seen.contains("Dub")) break;
            scrollList(FORM, "down");
        }
        return seen;
    }

    private static By moodChip(String mood) {
        return AppiumBy.iOSNsPredicateString("name == '" + MOOD_CHIP + "' AND label == '" + mood + "'");
    }

    private static By segment(String camelot) {
        return AppiumBy.iOSNsPredicateString(
                "name == '" + SEGMENT + "' AND label BEGINSWITH '" + camelot + " ·'");
    }

    /**
     * Taps a mood row — selects it, or deselects it if selected. The Moods
     * section sits below the text fields, so most rows start under the keyboard.
     */
    public TrackFormPage toggleMood(String mood) {
        scrollTo(moodChip(mood), FORM).click();
        return this;
    }

    /** A selected mood row carries the Selected trait (XCUITest: selected=true). */
    public boolean isMoodSelected(String mood) {
        return scrollTo(moodChip(mood), FORM).isSelected();
    }

    public String bpm() {
        return valueOf(BPM_FIELD);
    }

    /** "8A · Am", or {@link #NO_KEY} when the track has none. */
    public String key() {
        return find(KEY_BUTTON).getAttribute("label");
    }

    /**
     * Taps Save without assuming it took effect, for asserting a blocked save.
     *
     * <p>Behaviour is asserted rather than the button's enabled state because
     * it is the stronger claim: the sheet stays open and nothing is written.
     * (The enabled state can be read too, via {@link #isButtonEnabled}: a plain
     * lookup by id hits iOS 26's toolbar wrapper element, which always says
     * enabled — that, not XCUITest, is what made it look untrustworthy.)
     */
    public TrackFormPage attemptSave() {
        find(SAVE_BUTTON).click();
        return this;
    }

    /** Whether the sheet is still up, after giving it the short budget to close. */
    public boolean isStillOpen() {
        return !isGone(byId(POSITION_FIELD), Config.absenceTimeout());
    }

    public ReleaseDetailPage save() {
        tap(SAVE_BUTTON);
        return new ReleaseDetailPage(driver);
    }

    public ReleaseDetailPage cancel() {
        tap(CANCEL_BUTTON);
        return new ReleaseDetailPage(driver);
    }
}
