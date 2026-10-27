package vynl.pages;

import io.appium.java_client.ios.IOSDriver;

/** The add / rename mood sheet. */
public class MoodFormPage extends BasePage {

    private static final String NAME_FIELD = "moodForm.nameField";
    private static final String SAVE_BUTTON = "moodForm.saveButton";
    private static final String CANCEL_BUTTON = "moodForm.cancelButton";
    private static final String DUPLICATE_ERROR = "moodForm.duplicateError";

    public MoodFormPage(IOSDriver driver) {
        super(driver);
    }

    public MoodFormPage enterName(String name) {
        if (!name.isEmpty()) {
            type(NAME_FIELD, name);
        }
        return this;
    }

    /** For renaming, where the field opens pre-filled. */
    public MoodFormPage replaceName(String name) {
        clearAndType(NAME_FIELD, name);
        return this;
    }

    public String name() {
        return valueOf(NAME_FIELD);
    }

    /** Reads the Button itself, not iOS 26's toolbar wrapper — see BasePage#isButtonEnabled. */
    public boolean isSaveEnabled() {
        return isButtonEnabled(SAVE_BUTTON);
    }

    public boolean isDuplicateErrorVisible() {
        return isVisible(DUPLICATE_ERROR);
    }

    public MoodVocabularyPage save() {
        tap(SAVE_BUTTON);
        return new MoodVocabularyPage(driver);
    }

    public MoodVocabularyPage cancel() {
        tap(CANCEL_BUTTON);
        return new MoodVocabularyPage(driver);
    }
}
