package vynl.pages;

import io.appium.java_client.ios.IOSDriver;
import vynl.config.Config;

/**
 * The add / edit track sheet. Required: position, title. Optional: bpm, key.
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
    private static final String KEY_FIELD = "trackForm.keyField";
    private static final String SAVE_BUTTON = "trackForm.saveButton";
    private static final String CANCEL_BUTTON = "trackForm.cancelButton";

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

    public TrackFormPage setKey(String key) {
        type(KEY_FIELD, key);
        return this;
    }

    public String bpm() {
        return valueOf(BPM_FIELD);
    }

    public String key() {
        return valueOf(KEY_FIELD);
    }

    /**
     * Taps Save without assuming it took effect, for asserting a blocked save.
     *
     * <p>Deliberately no {@code isSaveEnabled()}: on iOS 26 a disabled SwiftUI
     * toolbar button inside a sheet still reports {@code enabled=true} to
     * XCUITest, while being visibly greyed out and ignoring taps. The only
     * reliable signal is behaviour — the sheet stays open.
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
