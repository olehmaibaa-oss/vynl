package vynl.pages;

import io.appium.java_client.AppiumBy;
import io.appium.java_client.ios.IOSDriver;
import vynl.config.Config;

/**
 * The add / rename mood sheet. Adding needs a group (E2-S5): five
 * {@code moodForm.groupOption} chips, the chosen one Selected. Renaming has no
 * group picker; a mood keeps its group.
 */
public class MoodFormPage extends BasePage {

    private static final String NAME_FIELD = "moodForm.nameField";
    private static final String SAVE_BUTTON = "moodForm.saveButton";
    private static final String CANCEL_BUTTON = "moodForm.cancelButton";
    private static final String DUPLICATE_ERROR = "moodForm.duplicateError";
    private static final String GROUP_PICKER = "moodForm.groupPicker";
    private static final String GROUP_OPTION = "moodForm.groupOption";

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

    public MoodFormPage chooseGroup(String group) {
        driver.findElement(AppiumBy.iOSNsPredicateString(
                "name == '" + GROUP_OPTION + "' AND label == '" + group + "'")).click();
        return this;
    }

    /** The group chip carrying the Selected trait, or null. */
    public String selectedGroup() {
        find(GROUP_OPTION);
        return driver.findElements(byId(GROUP_OPTION)).stream()
                .filter(e -> e.isSelected())
                .map(e -> e.getAttribute("label"))
                .findFirst().orElse(null);
    }

    public boolean hasNoGroupPicker() {
        return isGone(byId(GROUP_PICKER), Config.absenceTimeout());
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
