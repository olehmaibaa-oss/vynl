package vynl.steps;

import io.cucumber.datatable.DataTable;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import vynl.config.Config;
import vynl.driver.DriverManager;
import vynl.pages.CollectionPage;
import vynl.pages.ReleaseDetailPage;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/** DR-7 (SCRUM-36): grid and stack modes of the collection. */
public class CollectionModeSteps {

    private CollectionPage collection() {
        return new CollectionPage(DriverManager.get());
    }

    private ReleaseDetailPage detail() {
        return new ReleaseDetailPage(DriverManager.get());
    }

    @Given("the collection holds:")
    public void theCollectionHolds(DataTable table) {
        boolean first = true;
        for (Map<String, String> row : table.asMaps()) {
            CollectionPage page = collection();
            (first ? page.tapAddFromEmptyState() : page.tapToolbarAdd())
                    .fillRequired(row.get("artist"), row.get("title"), Flows.GENRE)
                    .save();
            first = false;
        }
    }

    @Given("{string} has tracks {string} and {string}")
    public void hasTracks(String artist, String first, String second) {
        ReleaseDetailPage detail = collection().openRelease(artist);
        Flows.addTrack(detail, first, Flows.titleFor(first));
        Flows.addTrack(detail, second, Flows.titleFor(second));
        detail.goBack();
    }

    @When("I switch the collection to stack")
    public void iSwitchToStack() {
        collection().switchToStack();
    }

    @When("I open {string} from the collection")
    public void iOpenFromTheCollection(String artist) {
        collection().openRelease(artist);
    }

    @When("I swipe the stack {word}")
    public void iSwipeTheStack(String direction) {
        collection().swipeStack(direction);
    }

    @When("I tap {string} in the stack")
    public void iTapInTheStack(String artist) {
        collection().tapStackRecord(artist);
    }

    @When("I tap {string} in the grid")
    public void iTapInTheGrid(String artist) {
        collection().openSheet(artist);
    }

    @When("I open the current record's sheet")
    public void iOpenTheCurrentRecordsSheet() {
        collection().openCurrentSheet();
    }

    @When("I close the record sheet")
    public void iCloseTheRecordSheet() {
        collection().closeRecordSheet();
    }

    @When("I swipe the record sheet down")
    public void iSwipeTheRecordSheetDown() {
        collection().dismissRecordSheetBySwipe();
    }

    @When("I tap Open release in the sheet")
    public void iTapOpenReleaseInTheSheet() {
        collection().openReleaseFromSheet();
    }

    /**
     * Test launches reset the mode to grid; -uitesting-keepMode keeps the stored
     * one. The store is in memory, so the relaunched app starts empty.
     */
    @When("I relaunch the app keeping the mode")
    public void iRelaunchKeepingTheMode() {
        var driver = DriverManager.get();
        driver.terminateApp(Config.bundleId());
        driver.executeScript("mobile: launchApp", Map.of(
                "bundleId", Config.bundleId(),
                "arguments", List.of("-uitesting", "-uitesting-keepMode")));
    }

    @When("I add a release from the empty state with artist {string} and title {string}")
    public void iAddFromTheEmptyState(String artist, String title) {
        collection().tapAddFromEmptyState().fillRequired(artist, title, Flows.GENRE).save();
    }

    @When("I delete every release from the stack")
    public void iDeleteEveryReleaseFromTheStack() {
        while (!collection().isEmptyStateQuick()) {
            collection().openCurrentSheet().openReleaseFromSheet();
            detail().tapDelete().confirmDelete();
        }
    }

    @Then("the collection is in {word} mode")
    public void theCollectionIsInMode(String mode) {
        CollectionPage page = collection();
        assertEquals(mode, page.selectedMode(), "Wrong mode button selected");
        assertTrue(mode.equals("grid") ? page.isGridShown() : page.isStackShown(), mode + " not shown");
    }

    @Then("the grid rows read:")
    public void theGridRowsRead(DataTable table) {
        List<List<String>> expected = table.asLists().stream()
                .map(r -> r.stream().filter(c -> c != null && !c.isBlank()).toList())
                .toList();
        assertEquals(expected, collection().gridRows());
    }

    @Then("the release screen shows {string} by {string}")
    public void theReleaseScreenShows(String title, String artist) {
        assertTrue(detail().showsField("Title", title), "Title not shown as " + title);
        assertTrue(detail().showsField("Artist", artist), "Artist not shown as " + artist);
    }

    @Then("the current record is {string} with {string}")
    public void theCurrentRecordIsWith(String record, String value) {
        assertEquals(record, collection().currentStackRecord());
        assertEquals(value, collection().currentStackRecordValue());
    }

    @Then("the current record is {string}")
    public void theCurrentRecordIs(String record) {
        assertEquals(record, collection().currentStackRecord());
    }

    @Then("no record sheet is open")
    public void noRecordSheetIsOpen() {
        assertTrue(collection().isSheetClosed(), "A record sheet is still open");
    }

    @Then("the record sheet is {string}")
    public void theRecordSheetIs(String record) {
        assertTrue(collection().isSheetOpen(), "No record sheet open");
        assertEquals(record, collection().sheetRecord());
    }

    @Given("I add a release from the toolbar with artist {string} and title {string}")
    public void iAddFromTheToolbar(String artist, String title) {
        collection().tapToolbarAdd().fillRequired(artist, title, Flows.GENRE).save();
    }

    @Then("the current record sits in the middle")
    public void theCurrentRecordSitsInTheMiddle() {
        int offset = collection().currentRecordOffsetFromMiddle();
        assertTrue(Math.abs(offset) <= 8, "Current record is " + offset + "pt off the middle");
    }

    @Then("the record sheet shows {string}")
    public void theExpandedRecordShows(String text) {
        assertEquals(text, collection().noTracksText());
    }

    @Then("the stack holds each record once")
    public void theStackHoldsEachRecordOnce() {
        List<String> labels = collection().stackRecords();
        assertEquals(labels.stream().distinct().count(), (long) labels.size(), "Repeated records: " + labels);
    }

    @Then("the sheet's tracks read {string} and {string}")
    public void theSheetsTracksRead(String first, String second) {
        assertEquals(List.of(first, second), collection().sheetTracks());
    }
}
