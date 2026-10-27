package vynl.steps;

import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import vynl.driver.DriverManager;
import vynl.pages.CollectionPage;
import vynl.pages.MoodFormPage;
import vynl.pages.MoodVocabularyPage;

import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class MoodSteps {

    // Cucumber builds a fresh instance per scenario, so scenario state is safe here.
    private MoodFormPage form;

    private MoodVocabularyPage vocabulary() {
        return new MoodVocabularyPage(DriverManager.get());
    }

    // --- setup / navigation ---

    @Given("I am on the mood vocabulary")
    @When("I open the mood vocabulary")
    public void iOpenTheMoodVocabulary() {
        assertTrue(new CollectionPage(DriverManager.get()).openMoods().isDisplayed(),
                "Mood vocabulary did not open");
    }

    @Given("I am adding a mood")
    public void iAmAddingAMood() {
        iOpenTheMoodVocabulary();
        form = vocabulary().tapAdd();
    }

    // --- actions ---

    @When("I add a mood {string}")
    public void iAddAMood(String name) {
        vocabulary().tapAdd().enterName(name).save();
    }

    @When("I enter the mood name {string}")
    public void iEnterTheMoodName(String name) {
        form.enterName(name);
    }

    @When("the mood name is {word}")
    public void theMoodNameIs(String kind) {
        switch (kind) {
            case "empty" -> form.enterName("");
            case "whitespace-only" -> form.enterName("   ");
            default -> throw new IllegalArgumentException("Unknown name kind: " + kind);
        }
    }

    @When("I rename the mood {string} to {string}")
    public void iRenameTheMood(String from, String to) {
        vocabulary().openMood(from).replaceName(to).save();
    }

    @When("I start renaming the mood {string} to {string}")
    public void iStartRenamingTheMood(String from, String to) {
        form = vocabulary().openMood(from).replaceName(to);
    }

    @When("I swipe-delete the mood {string}")
    public void iSwipeDeleteTheMood(String name) {
        vocabulary().swipeDelete(name);
    }

    // --- assertions ---

    /** Reads the actual row order, so it proves sorting, not just presence. */
    @Then("the moods read {string}")
    public void theMoodsRead(String commaSeparated) {
        List<String> expected = Arrays.stream(commaSeparated.split(","))
                .map(String::trim)
                .toList();
        assertEquals(expected, vocabulary().moodNames());
    }

    @Then("the first mood is {string}")
    public void theFirstMoodIs(String name) {
        assertEquals(name, vocabulary().moodNames().get(0));
    }

    @Then("{string} is in the vocabulary")
    public void isInTheVocabulary(String name) {
        assertTrue(vocabulary().isListed(name), "'" + name + "' is not in the vocabulary");
    }

    @Then("{string} is no longer in the vocabulary")
    public void isNoLongerInTheVocabulary(String name) {
        assertTrue(vocabulary().isGone(name), "'" + name + "' is still in the vocabulary");
    }

    @Then("the mood save action is disabled")
    public void theMoodSaveActionIsDisabled() {
        assertFalse(form.isSaveEnabled(), "Save is enabled");
    }

    @Then("I see that the mood already exists")
    public void iSeeThatTheMoodAlreadyExists() {
        assertTrue(form.isDuplicateErrorVisible(), "Duplicate-name message not shown");
    }
}
