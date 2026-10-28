package vynl.steps;

import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import vynl.driver.DriverManager;
import vynl.pages.CollectionPage;
import vynl.pages.MoodFormPage;
import vynl.pages.MoodVocabularyPage;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class MoodSteps {

    // Cucumber builds a fresh instance per scenario, so scenario state is safe here.
    private MoodFormPage form;
    /** One read of the whole vocabulary per check: reading it scrolls the list. */
    private Map<String, List<String>> snapshot;

    private Map<String, List<String>> snapshot() {
        if (snapshot == null) snapshot = vocabulary().readAll();
        return snapshot;
    }

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

    @When("I add a mood {string} to {string}")
    public void iAddAMoodTo(String name, String group) {
        vocabulary().tapAdd().enterName(name).chooseGroup(group).save();
    }

    @When("I choose the group {string}")
    public void iChooseTheGroup(String group) {
        form.chooseGroup(group);
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

    /** Reads the actual order on screen, so it proves ordering, not just presence. */
    @Then("the groups read {string}")
    public void theGroupsRead(String commaSeparated) {
        assertEquals(split(commaSeparated), new ArrayList<>(snapshot().keySet()));
    }

    @Then("{string} lists {string}")
    public void groupLists(String group, String commaSeparated) {
        assertEquals(split(commaSeparated), snapshot().getOrDefault(group, List.of()));
    }

    @Then("the vocabulary has {int} moods")
    public void theVocabularyHas(int count) {
        List<String> moods = snapshot().values().stream().flatMap(List::stream).toList();
        assertEquals(count, moods.size(), "moods: " + moods);
    }

    /** Commas inside mood names don't occur; " / " does, and survives the split. */
    private static List<String> split(String commaSeparated) {
        return Arrays.stream(commaSeparated.split(",")).map(String::trim).toList();
    }

    @Then("{string} is in the vocabulary")
    public void isInTheVocabulary(String name) {
        assertTrue(vocabulary().isListed(name), "'" + name + "' is not in the vocabulary");
    }

    @Then("{string} is no longer in the vocabulary")
    public void isNoLongerInTheVocabulary(String name) {
        boolean listed = snapshot().values().stream().anyMatch(moods -> moods.contains(name));
        assertTrue(!listed, "'" + name + "' is still in the vocabulary");
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
