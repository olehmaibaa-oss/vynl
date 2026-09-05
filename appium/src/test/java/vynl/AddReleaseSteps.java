package vynl;

import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import vynl.pages.CollectionPage;

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

    @Then("I see the release {string} in the collection")
    public void iSeeTheRelease(String artist) {
        assertTrue(collection().isReleaseVisible(artist),
                "Release '" + artist + "' is not visible in the collection");
    }
}
