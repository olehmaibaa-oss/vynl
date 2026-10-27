package vynl.steps;

import vynl.driver.DriverManager;
import vynl.pages.CollectionPage;
import vynl.pages.ReleaseDetailPage;

/**
 * Data setup shared by step classes. Each scenario starts on an empty in-memory
 * store, so every scenario builds its own data through the UI — these are the
 * flows it does that with, kept in one place so a change to the add-release or
 * add-track UI is fixed once.
 */
final class Flows {

    static final String ARTIST = "Surgeon";
    static final String TITLE = "Internal Empire";
    static final String GENRE = "Techno";

    private Flows() {
    }

    /** Adds a release from the empty state and opens it. */
    static ReleaseDetailPage openNewRelease() {
        return new CollectionPage(DriverManager.get())
                .tapAddFromEmptyState()
                .fillRequired(ARTIST, TITLE, GENRE)
                .save()
                .openRelease(ARTIST);
    }

    /** Adds a track through the toolbar control, which exists with or without tracks. */
    static ReleaseDetailPage addTrack(ReleaseDetailPage detail, String position, String title) {
        return detail.tapToolbarAddTrack()
                .setPosition(position)
                .setTitle(title)
                .save();
    }

    /** Title used when a scenario only cares about the position. */
    static String titleFor(String position) {
        return "Track " + position;
    }
}
