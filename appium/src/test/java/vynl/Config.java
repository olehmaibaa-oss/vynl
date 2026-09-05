package vynl;

import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.net.MalformedURLException;
import java.net.URI;
import java.net.URL;
import java.time.Duration;
import java.util.Properties;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Test configuration, loaded once from {@code config.properties} on the test
 * classpath. Any key can be overridden from the command line as a system
 * property, so CI and one-off runs never need to edit the file:
 *
 * <pre>mvn test -Dios.udid=A0EC2CC4-88A7-423A-B851-C59705474E84</pre>
 */
public final class Config {

    private static final String FILE = "config.properties";
    private static final Properties PROPS = load();

    private Config() {
    }

    private static Properties load() {
        Properties props = new Properties();
        try (InputStream in = Config.class.getClassLoader().getResourceAsStream(FILE)) {
            if (in == null) {
                throw new IllegalStateException(FILE + " not found on the test classpath");
            }
            props.load(in);
        } catch (IOException e) {
            throw new UncheckedIOException("Could not read " + FILE, e);
        }
        return props;
    }

    /** System property wins over the file, so -D overrides need no file edit. */
    private static String get(String key) {
        String override = System.getProperty(key);
        if (override != null && !override.isBlank()) {
            return override.trim();
        }
        String value = PROPS.getProperty(key);
        if (value == null || value.isBlank()) {
            throw new IllegalStateException("Missing config key: " + key);
        }
        return value.trim();
    }

    private static int getInt(String key) {
        return Integer.parseInt(get(key));
    }

    private static boolean getBool(String key) {
        return Boolean.parseBoolean(get(key));
    }

    public static URL appiumUrl() {
        try {
            return URI.create(get("appium.url")).toURL();
        } catch (MalformedURLException e) {
            throw new IllegalStateException("Bad appium.url: " + get("appium.url"), e);
        }
    }

    public static String deviceName() {
        return get("ios.deviceName");
    }

    public static String platformVersion() {
        return get("ios.platformVersion");
    }

    public static String bundleId() {
        return get("ios.bundleId");
    }

    public static int wdaLaunchTimeoutMs() {
        return getInt("wda.launchTimeoutMs");
    }

    public static int wdaConnectionTimeoutMs() {
        return getInt("wda.connectionTimeoutMs");
    }

    public static boolean useNewWda() {
        return getBool("wda.useNewWDA");
    }

    public static boolean usePrebuiltWda() {
        return getBool("wda.usePrebuiltWDA");
    }

    /** How long to wait for something that is expected to appear. */
    public static Duration elementTimeout() {
        return Duration.ofSeconds(getInt("wait.elementTimeoutSec"));
    }

    /** How long to wait before concluding something is not there. */
    public static Duration absenceTimeout() {
        return Duration.ofSeconds(getInt("wait.absenceTimeoutSec"));
    }

    /**
     * The simulator to drive. {@code auto} resolves to whichever simulator is
     * currently booted, so a rebuilt or replaced simulator doesn't break every
     * run the way a hardcoded UDID does. Set an explicit UDID when more than
     * one simulator is booted.
     */
    public static String udid() {
        String configured = get("ios.udid");
        return "auto".equalsIgnoreCase(configured) ? bootedSimulatorUdid() : configured;
    }

    private static final Pattern BOOTED_UDID = Pattern.compile(
            "\\(([0-9A-Fa-f-]{36})\\)\\s*\\(Booted\\)");

    private static String bootedSimulatorUdid() {
        String output = run("xcrun", "simctl", "list", "devices", "booted");
        Matcher matcher = BOOTED_UDID.matcher(output);
        if (!matcher.find()) {
            throw new IllegalStateException(
                    "ios.udid=auto but no simulator is booted. Boot one "
                            + "(xcrun simctl boot <udid>) or set ios.udid explicitly.");
        }
        String first = matcher.group(1);
        if (matcher.find()) {
            throw new IllegalStateException(
                    "ios.udid=auto but several simulators are booted — "
                            + "set ios.udid explicitly to pick one.");
        }
        return first;
    }

    private static String run(String... command) {
        try {
            Process process = new ProcessBuilder(command).redirectErrorStream(true).start();
            String output = new String(process.getInputStream().readAllBytes());
            process.waitFor();
            return output;
        } catch (IOException e) {
            throw new UncheckedIOException("Could not run " + String.join(" ", command), e);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Interrupted while running " + String.join(" ", command), e);
        }
    }
}
