package vynl.steps;

import io.cucumber.datatable.DataTable;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import vynl.driver.DriverManager;
import vynl.pages.AddReleasePage;
import vynl.pages.CollectionPage;

import java.util.Arrays;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;

/** DR-8 (SCRUM-37): sort from the filter sheet. */
public class SortSteps {

    private CollectionPage collection() {
        return new CollectionPage(DriverManager.get());
    }

    /** Rows are added top to bottom, so the last row is the most recently added. */
    @Given("the collection holds, in this order:")
    public void theCollectionHoldsInOrder(DataTable table) {
        boolean first = true;
        for (Map<String, String> row : table.asMaps()) {
            CollectionPage page = collection();
            AddReleasePage form = (first ? page.tapAddFromEmptyState() : page.tapToolbarAdd())
                    .fillRequired(row.get("artist"), row.get("title"), Flows.GENRE);
            String year = row.get("year");
            if (year != null && !year.isBlank()) form.setYear(year);
            form.save();
            first = false;
        }
    }

    @When("I sort by {string}")
    public void iSortBy(String sort) {
        collection().openFilterSheet().pickSort(sort).applyFilter();
    }

    @When("I open the filter sheet")
    public void iOpenTheFilterSheet() {
        collection().openFilterSheet();
    }

    @When("I pick {string} and close the sheet without applying")
    public void iPickAndClose(String sort) {
        collection().pickSort(sort).dismissFilterSheet();
    }

    @When("I switch the collection to grid")
    public void iSwitchToGrid() {
        collection().switchToGrid();
    }

    @Then("the selected sort option is {string}")
    public void theSelectedSortOptionIs(String sort) {
        assertEquals(sort, collection().selectedSort());
    }

    @Then("the filter bar reads {string}")
    public void theFilterBarReads(String value) {
        assertEquals(value, collection().filterBarValue());
    }

    @Then("the record artists read {string}")
    public void theRecordArtistsRead(String artists) {
        assertEquals(split(artists), part(0));
    }

    @Then("the record titles read {string}")
    public void theRecordTitlesRead(String titles) {
        assertEquals(split(titles), part(1));
    }

    private static List<String> split(String csv) {
        return Arrays.stream(csv.split(",")).map(String::trim).toList();
    }

    /** Artist (0) or title (1) of each record; labels are "Artist, Title". */
    private List<String> part(int index) {
        return collection().recordOrder().stream()
                .map(label -> label.split(", ", 2)[index])
                .toList();
    }
}
