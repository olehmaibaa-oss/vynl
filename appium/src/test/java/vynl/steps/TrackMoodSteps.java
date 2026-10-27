package vynl.steps;

import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import vynl.driver.DriverManager;
import vynl.pages.ReleaseDetailPage;
import vynl.pages.TrackFormPage;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Every "tagged with" assertion reads the release's track list after the form
 * has closed — the form's own state is only asserted where the AC is about the
 * form (re-opening shows the current moods).
 */
public class TrackMoodSteps {

    private TrackFormPage form;

    private ReleaseDetailPage detail() {
        return new ReleaseDetailPage(DriverManager.get());
    }

    private static void addTaggedTrack(ReleaseDetailPage detail, String position, String... moods) {
        TrackFormPage form = detail.tapToolbarAddTrack()
                .setPosition(position)
                .setTitle(Flows.titleFor(position));
        for (String mood : moods) {
            form.toggleMood(mood);
        }
        form.save();
    }

    // --- setup ---

    @Given("a release has a track {string} tagged {string}")
    public void aReleaseHasATrackTagged(String position, String mood) {
        addTaggedTrack(Flows.openNewRelease(), position, mood);
    }

    @Given("a release has a track {string} tagged {string} and {string}")
    public void aReleaseHasATrackTaggedWithTwo(String position, String first, String second) {
        addTaggedTrack(Flows.openNewRelease(), position, first, second);
    }

    // --- actions ---

    @When("I add a track {string} \\/ {string} with moods {string} and {string}")
    public void iAddATrackWithMoods(String position, String title, String first, String second) {
        detail().tapToolbarAddTrack()
                .setPosition(position)
                .setTitle(title)
                .toggleMood(first)
                .toggleMood(second)
                .save();
    }

    @When("I open the track {string}")
    public void iOpenTheTrack(String position) {
        form = detail().openTrack(position);
    }

    @When("I toggle the mood {string} on track {string} and save")
    public void iToggleTheMoodAndSave(String mood, String position) {
        detail().openTrack(position).toggleMood(mood).save();
    }

    @When("I toggle the mood {string} on track {string} and cancel")
    public void iToggleTheMoodAndCancel(String mood, String position) {
        detail().openTrack(position).toggleMood(mood).cancel();
    }

    /** Crosses screens: detail → collection → vocabulary → rename → back to the release. */
    @When("I rename the mood {string} to {string} and return to the release")
    public void iRenameTheMoodAndReturn(String from, String to) {
        detail().goBack()
                .openMoods()
                .openMood(from)
                .replaceName(to)
                .save()
                .goBack()
                .openRelease(Flows.ARTIST);
    }

    // --- assertions ---

    @Then("the track {string} shows moods {string}")
    public void theTrackShowsMoods(String position, String expected) {
        assertEquals(expected, detail().moodsOf(position));
    }

    @Then("the track {string} shows no moods")
    public void theTrackShowsNoMoods(String position) {
        assertTrue(detail().showsNoMoods(position), "Track " + position + " shows a mood line");
    }

    @Then("the mood {string} is selected")
    public void theMoodIsSelected(String mood) {
        assertTrue(form.isMoodSelected(mood), mood + " is not selected");
    }

    @Then("the mood {string} is not selected")
    public void theMoodIsNotSelected(String mood) {
        assertFalse(form.isMoodSelected(mood), mood + " is selected");
    }
}
