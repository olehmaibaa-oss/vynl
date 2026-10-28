package vynl.steps;

import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import vynl.driver.DriverManager;
import vynl.pages.ReleaseDetailPage;
import vynl.pages.TrackFormPage;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;

/** DR-6 (SCRUM-35): the key is picked on the Camelot wheel. */
public class CamelotSteps {

    // Cucumber builds a fresh instance per scenario.
    private TrackFormPage form;

    private ReleaseDetailPage detail() {
        return new ReleaseDetailPage(DriverManager.get());
    }

    @When("I add a track {string} \\/ {string} with key {string}")
    @Given("the release has a track {string} \\/ {string} with key {string}")
    public void iAddATrackWithKey(String position, String title, String camelot) {
        detail().tapToolbarAddTrack()
                .setPosition(position)
                .setTitle(title)
                .pickKey(camelot)
                .save();
    }

    @When("I open the track {string} and its key picker")
    public void iOpenTheTrackAndItsKeyPicker(String position) {
        form = detail().openTrack(position).openKeyPicker();
    }

    @When("I clear the key of track {string} and save")
    public void iClearTheKeyAndSave(String position) {
        detail().openTrack(position).clearKey().save();
    }

    @When("I rename track {string} to {string}, open and close the key picker, and save")
    public void iRenameOpenAndCloseThePickerAndSave(String position, String title) {
        detail().openTrack(position)
                .replaceTitle(title)
                .openKeyPicker()
                .closeKeyPicker()
                .save();
    }

    @When("I start adding a track and open the key picker")
    public void iStartAddingATrackAndOpenTheKeyPicker() {
        form = detail().tapToolbarAddTrack().openKeyPicker();
    }

    /** Read back from the reopened form: the key button's label is the key. */
    @Then("the track {string} has key {string}")
    public void theTrackHasKey(String position, String expected) {
        TrackFormPage reopened = detail().openTrack(position);
        assertEquals(expected, reopened.key());
        reopened.cancel();
    }

    @Then("the track {string} has no key")
    public void theTrackHasNoKey(String position) {
        theTrackHasKey(position, TrackFormPage.NO_KEY);
    }

    @Then("the selected key is {string}")
    public void theSelectedKeyIs(String expected) {
        assertEquals(expected, form.selectedSegment());
    }

    @Then("the wheel offers 24 keys from {string} to {string}")
    public void theWheelOffers24Keys(String first, String last) {
        List<String> segments = form.keySegments();
        assertEquals(24, segments.size(), "segments: " + segments);
        assertEquals(24, segments.stream().distinct().count(), "duplicate segments: " + segments);
        assertEquals(first, segments.get(0));
        assertEquals(last, segments.get(23));
    }
}
