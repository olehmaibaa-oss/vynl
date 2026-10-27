package vynl.steps;

import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import vynl.driver.DriverManager;
import vynl.pages.CollectionPage;
import vynl.pages.CratesPage;
import vynl.pages.ReleaseDetailPage;
import vynl.pages.TabBar;

import static org.junit.jupiter.api.Assertions.assertTrue;

public class NavigationSteps {

    private TabBar tabBar() {
        return new TabBar(DriverManager.get());
    }

    @Given("I have opened a release from the collection")
    public void iHaveOpenedARelease() {
        Flows.openNewRelease();
    }

    @When("I switch to the Crates tab")
    public void iSwitchToTheCratesTab() {
        tabBar().openCrates();
    }

    @When("I switch to the Crates tab and back to Collection")
    public void iSwitchToCratesAndBack() {
        assertTrue(tabBar().openCrates().isPlaceholderVisible(),
                "Never actually reached the Crates tab — the round trip would prove nothing");
        tabBar().openCollection();
    }

    @Then("the {word} tab is selected")
    public void theTabIsSelected(String tab) {
        assertTrue(tabBar().isSelected(tab), tab + " tab is not selected");
    }

    /** The empty state is what a fresh launch shows; its CTA is the screen's anchor. */
    @Then("I see the collection screen")
    public void iSeeTheCollectionScreen() {
        assertTrue(new CollectionPage(DriverManager.get()).isEmptyStateVisible(),
                "Collection screen not shown");
    }

    @Then("I see the Crates placeholder")
    public void iSeeTheCratesPlaceholder() {
        assertTrue(new CratesPage(DriverManager.get()).isPlaceholderVisible(),
                "Crates placeholder not shown");
    }

    /**
     * The scenario's point: fails if the tabs share one NavigationStack, because
     * the release would have been popped. Scoped to the detail container.
     */
    @Then("I am still on that release's detail screen")
    public void iAmStillOnTheDetailScreen() {
        ReleaseDetailPage detail = new ReleaseDetailPage(DriverManager.get());
        assertTrue(detail.showsField("Artist", Flows.ARTIST),
                "Release detail was lost when switching tabs");
    }
}
