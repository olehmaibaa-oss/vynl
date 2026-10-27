package vynl.steps;

import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import vynl.driver.DriverManager;
import vynl.pages.AddReleasePage;
import vynl.pages.CollectionPage;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class AddReleaseSteps {

    private CollectionPage collection() {
        return new CollectionPage(DriverManager.get());
    }

    @Given("the app is launched")
    public void theAppIsLaunched() {
        // драйвер піднімається в Hooks, апка вже запущена
    }

    @When("I add a release with artist {string}, title {string} and genre {string}")
    public void iAddRelease(String artist, String title, String genre) {
        collection()
                .tapAddFromEmptyState()
                .fillRequired(artist, title, genre)
                .save();
    }

    @When("I add a release from the toolbar with artist {string}, title {string} and genre {string}")
    public void iAddReleaseFromToolbar(String artist, String title, String genre) {
        collection()
                .tapToolbarAdd()
                .fillRequired(artist, title, genre)
                .save();
    }

    @When("I fill the new release form leaving {word} empty")
    public void iFillTheFormLeavingEmpty(String field) {
        collection()
                .tapAddFromEmptyState()
                .fillRequiredExcept(field, Flows.ARTIST, Flows.TITLE, Flows.GENRE);
    }

    @When("I fill the new release form and cancel")
    public void iFillTheFormAndCancel() {
        collection()
                .tapAddFromEmptyState()
                .fillRequired(Flows.ARTIST, Flows.TITLE, Flows.GENRE)
                .cancel();
    }

    /** Shared by add and edit: both use the same release form. */
    @Then("Save is disabled")
    public void saveIsDisabled() {
        AddReleasePage form = new AddReleasePage(DriverManager.get());
        assertFalse(form.isSaveEnabled(), "Save is enabled");
        assertTrue(form.isStillOpen(), "Form closed");
    }

    @Then("I see the release {string} in the collection")
    public void iSeeTheRelease(String artist) {
        assertTrue(collection().isReleaseVisible(artist),
                "Release '" + artist + "' is not visible in the collection");
    }
}
