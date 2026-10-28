package vynl.steps;

import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import vynl.config.Config;
import vynl.driver.DriverManager;
import vynl.pages.AddReleasePage;
import vynl.pages.CollectionPage;
import vynl.pages.ReleaseDetailPage;

import java.io.File;
import java.io.IOException;
import java.net.URISyntaxException;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;

/** DR-5 (SCRUM-34): covers in the release form and on the release screen. */
public class CoverSteps {

    private CollectionPage collection() {
        return new CollectionPage(DriverManager.get());
    }

    private AddReleasePage form() {
        return new AddReleasePage(DriverManager.get());
    }

    private ReleaseDetailPage detail() {
        return new ReleaseDetailPage(DriverManager.get());
    }

    /**
     * Adds fixtures/cover.jpg to the booted simulator's photo library, so it is
     * the newest photo. Adding it again on every run is harmless: the picker
     * takes the newest, and they're all the same image.
     */
    @Given("a photo is in the library")
    public void aPhotoIsInTheLibrary() throws IOException, InterruptedException, URISyntaxException {
        File fixture = new File(getClass().getClassLoader().getResource("fixtures/cover.jpg").toURI());
        Process p = new ProcessBuilder("xcrun", "simctl", "addmedia", Config.udid(), fixture.getAbsolutePath())
                .redirectErrorStream(true).start();
        if (p.waitFor() != 0) {
            throw new IllegalStateException("simctl addmedia failed: " + new String(p.getInputStream().readAllBytes()));
        }
    }

    @Given("I am on the add-release form")
    public void iAmOnTheAddReleaseForm() {
        collection().tapAddFromEmptyState();
    }

    @When("I fill in artist {string} and title {string}")
    public void iFillInArtistAndTitle(String artist, String title) {
        form().fillRequiredExcept("genre", artist, title, null);
    }

    @When("I fill the release and pick the newest photo")
    public void iFillTheReleaseAndPick() {
        form().fillRequired(Flows.ARTIST, Flows.TITLE, Flows.GENRE).pickNewestLibraryPhoto();
    }

    @Given("a release with a cover exists")
    public void aReleaseWithACoverExists() {
        collection().tapAddFromEmptyState()
                .fillRequired(Flows.ARTIST, Flows.TITLE, Flows.GENRE)
                .pickNewestLibraryPhoto()
                .save()
                .openRelease(Flows.ARTIST);
        assertEquals("image", detail().coverKind(), "setup: the cover didn't stick");
    }

    @When("I edit it, remove the cover and save")
    public void iEditRemoveCoverAndSave() {
        detail().tapEdit().removeCover().saveEdit();
    }

    @Then("the cover slot shows a placeholder for {string}")
    public void theSlotShowsAPlaceholderFor(String name) {
        assertEquals("placeholder", form().coverKind());
        assertEquals(name, form().coverName());
    }

    @Then("the release shows a cover image")
    public void theReleaseShowsACoverImage() {
        assertEquals("image", detail().coverKind());
    }

    @Then("the release shows the placeholder")
    public void theReleaseShowsThePlaceholder() {
        assertEquals("placeholder", detail().coverKind());
    }

    @Then("the camera option is not offered")
    public void theCameraOptionIsNotOffered() {
        assertFalse(form().isCameraOffered(), "Camera is offered");
    }
}
