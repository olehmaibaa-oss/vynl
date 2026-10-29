package vynl.pages;

import io.appium.java_client.AppiumBy;
import io.appium.java_client.ios.IOSDriver;
import org.openqa.selenium.By;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.ui.ExpectedConditions;
import vynl.config.Config;

import java.util.List;
import java.util.Map;

/**
 * The collection screen: grid and stack modes (DR-7), the empty state, the add
 * entry points.
 *
 * <p>A record in either mode is a {@code collection.record} button labelled
 * "Artist, Title"; its sleeve and texts are folded into it, so lookups go by
 * that label, never by StaticText. In the stack the current record carries the
 * Selected trait; looping (4+ records) puts the same record in more than one
 * slot, so stack lookups always take the selected one.
 */
public class CollectionPage extends BasePage {

    private static final String GRID = "collection.grid";
    private static final String STACK = "collection.stack";
    private static final String RECORD = "collection.record";
    private static final String GRID_MODE_BUTTON = "collection.gridModeButton";
    private static final String STACK_MODE_BUTTON = "collection.stackModeButton";
    private static final String EXPANDED_RECORD = "collection.expandedRecord";
    private static final String HIDE_TRACKS_BUTTON = "collection.hideTracksButton";
    private static final String TRACK_ROW = "collection.trackRow";
    private static final String OPEN_RELEASE_BUTTON = "collection.openReleaseButton";
    private static final String ADD_RELEASE_BUTTON = "collection.addReleaseButton";
    private static final String TOOLBAR_ADD_BUTTON = "collection.toolbarAddButton";
    private static final String MOODS_BUTTON = "collection.moodsButton";

    private static final By CURRENT_RECORD = AppiumBy.iOSNsPredicateString(
            "name == '" + RECORD + "' AND selected == 1");

    public CollectionPage(IOSDriver driver) {
        super(driver);
    }

    public AddReleasePage tapAddFromEmptyState() {
        tap(ADD_RELEASE_BUTTON);
        return new AddReleasePage(driver);
    }

    /** The gear in the Collection toolbar pushes the mood vocabulary. */
    public MoodVocabularyPage openMoods() {
        tap(MOODS_BUTTON);
        return new MoodVocabularyPage(driver);
    }

    /**
     * DR-3: the header's actions sit together on the right. "Right" = the button's
     * left edge is past the middle of the screen; reads the Button, not its iOS 26
     * toolbar wrapper (same frame, but the Button is the one users hit).
     */
    public boolean areHeaderActionsOnTheRight() {
        int screenWidth = driver.manage().window().getSize().getWidth();
        for (String id : new String[]{MOODS_BUTTON, TOOLBAR_ADD_BUTTON}) {
            int x = waitFor(ExpectedConditions.presenceOfElementLocated(button(id))).getRect().getX();
            if (x < screenWidth / 2) return false;
        }
        return true;
    }

    public AddReleasePage tapToolbarAdd() {
        tap(TOOLBAR_ADD_BUTTON);
        return new AddReleasePage(driver);
    }

    /**
     * The empty state has no identifier of its own, but its add CTA
     * ({@code collection.addReleaseButton}) only exists inside it.
     */
    public boolean isEmptyStateVisible() {
        return isVisible(ADD_RELEASE_BUTTON);
    }

    /** The empty collection has nothing to switch or filter, so neither control exists. */
    public boolean isModeToggleAndFilterBarGone() {
        return isGone(byId(GRID_MODE_BUTTON), Config.absenceTimeout())
                && isGone(byId(STACK_MODE_BUTTON), Config.absenceTimeout())
                && isGone(byId("filter.bar"), Config.absenceTimeout());
    }

    /** Same check on the short budget, for loops that stop once the collection is empty. */
    public boolean isEmptyStateQuick() {
        return isVisible(byId(ADD_RELEASE_BUTTON), Config.absenceTimeout());
    }

    // MARK: - Modes

    public CollectionPage switchToGrid() {
        tap(GRID_MODE_BUTTON);
        findVisible(GRID);
        return this;
    }

    public CollectionPage switchToStack() {
        tap(STACK_MODE_BUTTON);
        findVisible(STACK);
        return this;
    }

    /** "grid" or "stack": which mode button carries the Selected trait. */
    public String selectedMode() {
        WebElement grid = waitFor(ExpectedConditions.presenceOfElementLocated(button(GRID_MODE_BUTTON)));
        return "true".equals(grid.getAttribute("selected")) ? "grid" : "stack";
    }

    public boolean isGridShown() {
        return isVisible(GRID);
    }

    public boolean isStackShown() {
        return isVisible(STACK);
    }

    // MARK: - Records

    private static By record(String artist) {
        return AppiumBy.iOSNsPredicateString(
                "name == '" + RECORD + "' AND label BEGINSWITH '" + artist + ", '");
    }

    public boolean isReleaseVisible(String artist) {
        return isVisible(record(artist), Config.elementTimeout());
    }

    /** Short budget — for asserting a release is gone, e.g. after a delete. */
    public boolean isReleaseGone(String artist) {
        return isGone(record(artist), Config.absenceTimeout());
    }

    /** Opens a release from the grid (the default mode on a test launch). */
    public ReleaseDetailPage openRelease(String artist) {
        waitFor(ExpectedConditions.elementToBeClickable(record(artist))).click();
        return new ReleaseDetailPage(driver);
    }

    /** Grid tiles as rows of "Artist, Title", top to bottom, left to right. */
    public List<List<String>> gridRows() {
        findVisible(GRID);
        List<WebElement> tiles = driver.findElements(byId(RECORD));
        java.util.TreeMap<Integer, List<String>> byRow = new java.util.TreeMap<>();
        tiles.stream()
                .sorted(java.util.Comparator.comparingInt((WebElement e) -> e.getRect().getY())
                        .thenComparingInt(e -> e.getRect().getX()))
                .forEach(e -> byRow.computeIfAbsent(e.getRect().getY(), y -> new java.util.ArrayList<>())
                        .add(e.getAttribute("label")));
        return List.copyOf(byRow.values());
    }

    // MARK: - Stack

    /** "Artist, Title" of the record in the middle of the stack. */
    public String currentStackRecord() {
        return waitFor(ExpectedConditions.presenceOfElementLocated(CURRENT_RECORD)).getAttribute("label");
    }

    /** The current record's value, e.g. "2 tracks". */
    public String currentStackRecordValue() {
        return waitFor(ExpectedConditions.presenceOfElementLocated(CURRENT_RECORD)).getAttribute("value");
    }

    /**
     * Swipes the stack one record on ("up" = towards later records) and waits
     * for the current record to change. A short drag, not a fling: the stack is
     * view-aligned, so one drag moves exactly one record.
     */
    public CollectionPage swipeStack(String direction) {
        String before = currentStackRecord();
        org.openqa.selenium.Rectangle r = findVisible(STACK).getRect();
        int x = r.getX() + r.getWidth() / 2;
        int mid = r.getY() + r.getHeight() / 2;
        int delta = r.getHeight() / 5;
        boolean up = direction.equals("up");
        driver.executeScript("mobile: dragFromToForDuration", Map.of(
                "duration", 0.15,
                "fromX", x, "fromY", up ? mid + delta : mid - delta,
                "toX", x, "toY", up ? mid - delta : mid + delta));
        waitFor(d -> !before.equals(currentStackRecord()));
        return this;
    }

    /** Taps a stack record by artist: the current one expands, another one becomes current. */
    public CollectionPage tapStackRecord(String artist) {
        By selected = AppiumBy.iOSNsPredicateString(
                "name == '" + RECORD + "' AND selected == 1 AND label BEGINSWITH '" + artist + ", '");
        List<WebElement> current = driver.findElements(selected);
        (current.isEmpty() ? waitFor(ExpectedConditions.elementToBeClickable(record(artist))) : current.get(0)).click();
        return this;
    }

    public CollectionPage expandCurrent() {
        waitFor(ExpectedConditions.elementToBeClickable(CURRENT_RECORD)).click();
        findVisible(HIDE_TRACKS_BUTTON);
        return this;
    }

    public boolean isExpanded() {
        return isVisible(byId(HIDE_TRACKS_BUTTON), Config.elementTimeout());
    }

    public boolean isCollapsed() {
        return isGone(byId(HIDE_TRACKS_BUTTON), Config.elementTimeout())
                && isVisible(CURRENT_RECORD, Config.elementTimeout());
    }

    public String expandedRecord() {
        return find(EXPANDED_RECORD).getAttribute("label");
    }

    public CollectionPage hideTracks() {
        tap(HIDE_TRACKS_BUTTON);
        return this;
    }

    public CollectionPage tapExpandedSleeve() {
        tap(EXPANDED_RECORD);
        return this;
    }

    /** Swipes the expanded view: collapses and moves one record ("up" = next). */
    public CollectionPage swipeExpanded(String direction) {
        org.openqa.selenium.Rectangle r = find(EXPANDED_RECORD).getRect();
        int x = r.getX() + r.getWidth() / 2;
        int y = r.getY() + r.getHeight() / 2;
        boolean up = direction.equals("up");
        driver.executeScript("mobile: dragFromToForDuration", Map.of(
                "duration", 0.15,
                "fromX", x, "fromY", up ? y + 60 : y - 60,
                "toX", x, "toY", up ? y - 80 : y + 80));
        return this;
    }

    /** Labels of the expanded record's track rows ("A1, Title"). */
    public List<String> expandedTracks() {
        return labelsOf(TRACK_ROW);
    }

    /**
     * Vertical distance of the current record's centre from the middle of the
     * free area between the toolbar (the mode Button's bottom) and the filter bar.
     */
    public int currentRecordOffsetFromMiddle() {
        org.openqa.selenium.Rectangle card = waitFor(
                ExpectedConditions.presenceOfElementLocated(CURRENT_RECORD)).getRect();
        org.openqa.selenium.Rectangle toolbar = waitFor(
                ExpectedConditions.presenceOfElementLocated(button(GRID_MODE_BUTTON))).getRect();
        org.openqa.selenium.Rectangle bar = findVisible("filter.bar").getRect();
        int top = toolbar.getY() + toolbar.getHeight();
        int middle = (top + bar.getY()) / 2;
        return card.getY() + card.getHeight() / 2 - middle;
    }

    /** Every stack record in the tree, by label (looping repeats some). */
    public List<String> stackRecords() {
        findVisible(STACK);
        return labelsOf(RECORD);
    }

    /** The expanded record's empty-tracklist line. */
    public String noTracksText() {
        return findVisible("collection.noTracks").getAttribute("label");
    }

    public ReleaseDetailPage openReleaseFromStack() {
        tap(OPEN_RELEASE_BUTTON);
        return new ReleaseDetailPage(driver);
    }

    // MARK: - Filter bar and sort (DR-8)

    private static final String FILTER_BAR = "filter.bar";
    private static final String SORT_OPTION = "sort.option";
    private static final String APPLY_BUTTON = "filterSheet.applyButton";

    private static By sortOption(String name) {
        return AppiumBy.iOSNsPredicateString(
                "name == '" + SORT_OPTION + "' AND label == '" + name + "'");
    }

    /** The bar's value, e.g. "14 records, Artist A–Z". */
    public String filterBarValue() {
        return findVisible(FILTER_BAR).getAttribute("value");
    }

    public CollectionPage openFilterSheet() {
        tap(FILTER_BAR);
        findVisible(APPLY_BUTTON);
        return this;
    }

    public CollectionPage pickSort(String name) {
        waitFor(ExpectedConditions.elementToBeClickable(sortOption(name))).click();
        return this;
    }

    public CollectionPage applyFilter() {
        tap(APPLY_BUTTON);
        isGone(byId(APPLY_BUTTON), Config.elementTimeout());
        return this;
    }

    /** Closes the sheet the way a user does without applying: a swipe down. */
    public CollectionPage dismissFilterSheet() {
        org.openqa.selenium.Rectangle r = find(APPLY_BUTTON).getRect();
        int screenHeight = driver.manage().window().getSize().getHeight();
        int x = r.getX() + r.getWidth() / 2;
        int top = r.getY() - 160;
        driver.executeScript("mobile: dragFromToForDuration", Map.of(
                "duration", 0.2, "fromX", x, "fromY", top, "toX", x, "toY", screenHeight - 20));
        isGone(byId(APPLY_BUTTON), Config.elementTimeout());
        return this;
    }

    /** Label of the sort option carrying the Selected trait. */
    public String selectedSort() {
        return waitFor(ExpectedConditions.presenceOfElementLocated(AppiumBy.iOSNsPredicateString(
                "name == '" + SORT_OPTION + "' AND selected == 1"))).getAttribute("label");
    }

    /** "Artist, Title" of every record in on-screen order (grid). */
    public List<String> recordOrder() {
        findVisible(GRID);
        return labelsOf(RECORD);
    }
}
