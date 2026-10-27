package vynl.steps;

import io.cucumber.java.en.When;
import vynl.driver.DriverManager;
import vynl.pages.AddReleasePage;
import vynl.pages.ReleaseDetailPage;

/**
 * Edit reuses the add-release form. Assertions live in ReleaseDetailSteps
 * ("I see ... on the detail screen", "the status is") and AddReleaseSteps
 * ("Save is disabled"); this class only drives the edit flow.
 */
public class EditReleaseSteps {

    private AddReleasePage edit() {
        return new ReleaseDetailPage(DriverManager.get()).tapEdit();
    }

    @When("I change the title to {string}")
    public void iChangeTheTitle(String title) {
        edit().replaceTitle(title).saveEdit();
    }

    @When("I change the title to {string} and cancel")
    public void iChangeTheTitleAndCancel(String title) {
        edit().replaceTitle(title).cancelEdit();
    }

    @When("I start editing and clear {word}")
    public void iStartEditingAndClear(String field) {
        edit().clearField(field);
    }

    @When("I change the status to {string}")
    public void iChangeTheStatus(String status) {
        edit().selectStatus(status).saveEdit();
    }
}
