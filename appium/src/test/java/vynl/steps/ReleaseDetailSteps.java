package vynl.steps;

import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import vynl.driver.DriverManager;
import vynl.pages.CollectionPage;
import vynl.pages.ReleaseDetailPage;

import static org.junit.jupiter.api.Assertions.assertTrue;

public class ReleaseDetailSteps {

    private static final String DEFAULT_ARTIST = "Surgeon";
    private static final String DEFAULT_TITLE = "Internal Empire";
    private static final String DEFAULT_GENRE = "Techno";

    // Cucumber builds a fresh instance per scenario, so scenario state is safe here.
    private String artist;
    private ReleaseDetailPage detail;

    private CollectionPage collection() {
        return new CollectionPage(DriverManager.get());
    }

    private void createRelease(String artist, String title, String genre) {
        this.artist = artist;
        collection().tapAddFromEmptyState()
                .fillRequired(artist, title, genre)
                .save();
    }

    // "/" is the alternation operator in Cucumber Expressions, so it is escaped
    // here. Unescaped, " / " reads as an empty alternative and blows up glue
    // creation for the whole suite, not just this step.
    @Given("a release {string} \\/ {string} \\/ {string} exists")
    public void aReleaseExists(String artist, String title, String genre) {
        createRelease(artist, title, genre);
    }

    /** The add form has no label or year inputs, so a release created there has neither. */
    @Given("a release with no label and no year exists")
    public void aReleaseWithNoOptionalFieldsExists() {
        createRelease(DEFAULT_ARTIST, DEFAULT_TITLE, DEFAULT_GENRE);
    }

    @Given("a release exists")
    public void aReleaseExists() {
        createRelease(DEFAULT_ARTIST, DEFAULT_TITLE, DEFAULT_GENRE);
    }

    @Given("I am on a release detail screen")
    public void iAmOnAReleaseDetailScreen() {
        createRelease(DEFAULT_ARTIST, DEFAULT_TITLE, DEFAULT_GENRE);
        detail = collection().openRelease(artist);
    }

    @When("I open it from the collection")
    public void iOpenItFromTheCollection() {
        detail = collection().openRelease(artist);
    }

    @Then("I see {string}, {string} and {string} on the detail screen")
    public void iSeeTheValuesOnTheDetailScreen(String artist, String title, String genre) {
        assertTrue(detail.showsField("Artist", artist), "Artist not shown as " + artist);
        assertTrue(detail.showsField("Title", title), "Title not shown as " + title);
        assertTrue(detail.showsField("Genre", genre), "Genre not shown as " + genre);
    }

    @Then("the status is {string}")
    public void theStatusIs(String status) {
        assertTrue(detail.showsField("Status", status), "Status not shown as " + status);
    }

    @Then("label and year show {string}")
    public void labelAndYearShow(String placeholder) {
        assertTrue(detail.showsField("Label", placeholder), "Label not shown as " + placeholder);
        assertTrue(detail.showsField("Year", placeholder), "Year not shown as " + placeholder);
    }

    @Then("I see the add-track call to action")
    public void iSeeTheAddTrackCallToAction() {
        assertTrue(detail.isAddTrackCtaVisible(), "Add-track empty-state CTA not visible");
    }

    @Then("the edit control is available")
    public void theEditControlIsAvailable() {
        assertTrue(detail.isEditAvailable(), "Edit control not available");
    }

    @Then("the toolbar add-track control is available")
    public void theToolbarAddTrackControlIsAvailable() {
        assertTrue(detail.isToolbarAddTrackAvailable(), "Toolbar add-track control not available");
    }
}
