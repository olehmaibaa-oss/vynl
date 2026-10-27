package vynl.pages;

import io.appium.java_client.AppiumBy;
import io.appium.java_client.ios.IOSDriver;
import org.openqa.selenium.By;
import org.openqa.selenium.support.ui.ExpectedConditions;
import vynl.config.Config;

import java.util.List;

/**
 * The mood vocabulary, pushed from the gear on the Collection screen. Each mood
 * is a Button identified as {@code moods.row} whose label is the mood name.
 */
public class MoodVocabularyPage extends BasePage {

    private static final String ROW = "moods.row";
    private static final String ADD_BUTTON = "moods.addButton";

    public MoodVocabularyPage(IOSDriver driver) {
        super(driver);
    }

    public boolean isDisplayed() {
        return isVisible(button(ADD_BUTTON), Config.elementTimeout());
    }

    /** Mood names in on-screen order. */
    public List<String> moodNames() {
        return labelsOf(ROW);
    }

    public boolean isListed(String mood) {
        return isVisible(row(mood), Config.elementTimeout());
    }

    /** Short budget — the expected answer is "it's gone". */
    public boolean isGone(String mood) {
        return isGone(row(mood), Config.absenceTimeout());
    }

    public MoodFormPage tapAdd() {
        tap(ADD_BUTTON);
        return new MoodFormPage(driver);
    }

    /** Tapping a row opens the mood for renaming, pre-filled. */
    public MoodFormPage openMood(String mood) {
        waitFor(ExpectedConditions.elementToBeClickable(row(mood))).click();
        return new MoodFormPage(driver);
    }

    public MoodVocabularyPage swipeDelete(String mood) {
        swipeToDelete(row(mood));
        return this;
    }

    /** Pops back to the collection through the navigation bar. */
    public CollectionPage goBack() {
        driver.navigate().back();
        return new CollectionPage(driver);
    }

    private static By row(String mood) {
        return AppiumBy.iOSNsPredicateString("name == '" + ROW + "' AND label == '" + mood + "'");
    }
}
