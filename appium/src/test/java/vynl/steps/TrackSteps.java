package vynl.steps;

import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import vynl.driver.DriverManager;
import vynl.pages.ReleaseDetailPage;
import vynl.pages.TrackFormPage;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class TrackSteps {

    // Cucumber builds a fresh instance per scenario, so scenario state is safe here.
    private TrackFormPage form;

    private ReleaseDetailPage detail() {
        return new ReleaseDetailPage(DriverManager.get());
    }

    // --- setup ---

    @Given("I am adding a track")
    public void iAmAddingATrack() {
        // The empty-state CTA, so both add-track entry points get exercised:
        // every other add in this file goes through the toolbar.
        form = Flows.openNewRelease().tapAddTrack();
    }

    @Given("a release has a track {string} \\/ {string}")
    public void aReleaseHasATrack(String position, String title) {
        Flows.addTrack(Flows.openNewRelease(), position, title);
    }

    @Given("a release has tracks {string} and {string}")
    public void aReleaseHasTracks(String first, String second) {
        ReleaseDetailPage detail = Flows.openNewRelease();
        Flows.addTrack(detail, first, Flows.titleFor(first));
        Flows.addTrack(detail, second, Flows.titleFor(second));
    }

    // --- actions ---

    @When("I add a track {string} \\/ {string}")
    public void iAddATrack(String position, String title) {
        Flows.addTrack(detail(), position, title);
    }

    @When("I add a track {string} \\/ {string} with bpm {string} and key {string}")
    public void iAddATrackWithEveryField(String position, String title, String bpm, String key) {
        detail().tapToolbarAddTrack()
                .setPosition(position)
                .setTitle(title)
                .setBpm(bpm)
                .pickKey(key)
                .save();
    }

    @When("I add tracks {string}, {string} and {string} in that order")
    public void iAddTracksInOrder(String first, String second, String third) {
        for (String position : List.of(first, second, third)) {
            Flows.addTrack(detail(), position, Flows.titleFor(position));
        }
    }

    @When("I fill in only the track {word} with {string}")
    public void iFillInOnlyTheTrackField(String field, String value) {
        switch (field) {
            case "position" -> form.setPosition(value);
            case "title" -> form.setTitle(value);
            default -> throw new IllegalArgumentException("Unknown required track field: " + field);
        }
    }

    @When("I add a track {string} \\/ {string} typing {string} into bpm")
    public void iAddATrackTypingIntoBpm(String position, String title, String bpmInput) {
        detail().tapToolbarAddTrack()
                .setPosition(position)
                .setTitle(title)
                .setBpm(bpmInput)
                .save();
    }

    @When("I rename the track {string} to {string}")
    public void iRenameTheTrack(String position, String newTitle) {
        detail().openTrack(position).replaceTitle(newTitle).save();
    }

    @When("I swipe-delete the track {string}")
    public void iSwipeDeleteTheTrack(String position) {
        detail().swipeDeleteTrack(position);
    }

    // --- assertions ---

    @Then("I see the track {string} \\/ {string} in the track list")
    public void iSeeTheTrack(String position, String title) {
        assertTrue(detail().isTrackListed(position, title),
                "Track '" + position + ", " + title + "' is not listed");
    }

    @Then("the track {string} \\/ {string} is no longer listed")
    public void theTrackIsNoLongerListed(String position, String title) {
        assertTrue(detail().isTrackGone(position, title),
                "Track '" + position + ", " + title + "' is still listed");
    }

    @Then("the track {string} is no longer listed")
    public void thePositionIsNoLongerListed(String position) {
        assertTrue(detail().isPositionGone(position), "Track at " + position + " is still listed");
    }

    @Then("the track {string} is still listed")
    public void thePositionIsStillListed(String position) {
        assertTrue(detail().isPositionListed(position), "Track at " + position + " is not listed");
    }

    /**
     * Reopens the track to read back what was stored: the track row shows only
     * position and title, so bpm and key are only observable in the form.
     */
    @Then("the track {string} keeps bpm {string} and key {string}")
    public void theTrackKeepsBpmAndKey(String position, String bpm, String key) {
        TrackFormPage reopened = detail().openTrack(position);
        assertEquals(bpm, reopened.bpm(), "bpm was not persisted");
        assertEquals(key, reopened.key(), "key was not persisted");
        reopened.cancel();
    }

    @Then("the track positions read {string}, {string}, {string}")
    public void theTrackPositionsRead(String first, String second, String third) {
        assertEquals(List.of(first, second, third), detail().trackPositions());
    }

    /**
     * Asserted by behaviour: tapping Save leaves the sheet open, and after
     * cancelling the release still has no tracks, so nothing was persisted.
     */
    @Then("saving the track is blocked")
    public void savingTheTrackIsBlocked() {
        assertTrue(form.attemptSave().isStillOpen(), "Save went through with a required field empty");
        ReleaseDetailPage detail = form.cancel();
        assertTrue(detail.isAddTrackCtaVisible(), "A track was created despite the blocked save");
    }

    @Then("the track {string} keeps bpm {string}")
    public void theTrackKeepsBpm(String position, String bpm) {
        TrackFormPage reopened = detail().openTrack(position);
        assertEquals(bpm, reopened.bpm(), "persisted bpm");
        reopened.cancel();
    }
}
