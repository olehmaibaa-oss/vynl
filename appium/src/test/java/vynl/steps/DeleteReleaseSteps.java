package vynl.steps;

import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import vynl.driver.DriverManager;
import vynl.pages.CollectionPage;
import vynl.pages.ReleaseDetailPage;

import static org.junit.jupiter.api.Assertions.assertTrue;

public class DeleteReleaseSteps {

    private ReleaseDetailPage detail() {
        return new ReleaseDetailPage(DriverManager.get());
    }

    private CollectionPage collection() {
        return new CollectionPage(DriverManager.get());
    }

    @When("I tap delete release")
    public void iTapDeleteRelease() {
        detail().tapDelete();
    }

    @When("I delete the release and confirm")
    public void iDeleteTheReleaseAndConfirm() {
        detail().tapDelete().confirmDelete();
    }

    @When("I tap delete release and cancel")
    public void iTapDeleteReleaseAndCancel() {
        detail().tapDelete().cancelDelete();
    }

    @Then("I see the delete confirmation")
    public void iSeeTheDeleteConfirmation() {
        assertTrue(detail().isDeleteConfirmationVisible(), "Delete confirmation not shown");
    }

    /** Both halves matter: the empty state alone would also pass on a fresh launch. */
    @Then("the collection is empty")
    public void theCollectionIsEmpty() {
        assertTrue(collection().isReleaseGone(Flows.ARTIST), "Deleted release is still listed");
        assertTrue(collection().isEmptyStateVisible(), "Collection empty state not shown");
    }

    @Then("the release is still open with its details")
    public void theReleaseIsStillOpen() {
        ReleaseDetailPage detail = detail();
        assertTrue(detail.isDeleteConfirmationGone(), "Confirmation did not close on cancel");
        assertTrue(detail.showsField("Artist", Flows.ARTIST), "Release details no longer shown");
    }

    @Then("the collection still lists the release")
    public void theCollectionStillListsTheRelease() {
        assertTrue(detail().goBack().isReleaseVisible(Flows.ARTIST),
                "Release missing from the collection after a cancelled delete");
    }
}
