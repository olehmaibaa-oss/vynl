package vynl.steps;

import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import vynl.driver.DriverManager;
import vynl.pages.AddReleasePage;
import vynl.pages.CollectionPage;
import vynl.pages.ReleaseDetailPage;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** DR-4 (SCRUM-33): genre chips in the release form and on the detail screen. */
public class GenreSteps {

    private CollectionPage collection() {
        return new CollectionPage(DriverManager.get());
    }

    private AddReleasePage form() {
        return new AddReleasePage(DriverManager.get());
    }

    private ReleaseDetailPage detail() {
        return new ReleaseDetailPage(DriverManager.get());
    }

    @Given("I am on the add-release form with artist and title filled")
    public void iAmOnTheFormWithArtistAndTitle() {
        collection().tapAddFromEmptyState()
                .fillRequiredExcept("genre", Flows.ARTIST, Flows.TITLE, null);
    }

    @When("I add the genres {string} and {string}")
    public void iAddTheGenres(String first, String second) {
        form().addGenre(first).addGenre(second);
    }

    @When("I save the release and open it")
    public void iSaveAndOpen() {
        form().save().openRelease(Flows.ARTIST);
    }

    /** The release from the Given exists, so the form opens from the toolbar "+". */
    @When("I start adding a release and type the genre {string}")
    public void iStartAddingAndType(String text) {
        collection().tapToolbarAdd().typeGenre(text);
    }

    @When("I start adding a release and add the genre {string}")
    public void iStartAddingAndAdd(String genre) {
        collection().tapToolbarAdd().addGenre(genre);
    }

    @When("I remove the genre {string}")
    public void iRemoveTheGenre(String genre) {
        form().removeGenre(genre);
    }

    @When("I edit the release and add the genre {string}")
    public void iEditAndAdd(String genre) {
        detail().tapEdit().addGenre(genre).saveEdit();
    }

    @When("I edit the release and remove the genre {string}")
    public void iEditAndRemove(String genre) {
        detail().tapEdit().removeGenre(genre);
    }

    @Then("{string} is suggested")
    public void isSuggested(String genre) {
        assertTrue(form().isSuggested(genre), genre + " is not suggested");
    }

    @Then("the form's genres read {string}")
    public void theFormsGenresRead(String expected) {
        assertEquals(expected, String.join(", ", form().genreChips()));
    }

    @Then("the release shows the genres {string}")
    public void theReleaseShowsTheGenres(String expected) {
        assertEquals(expected, String.join(", ", detail().genres()));
    }
}
