package com.dnio.gujarati.offline;

import android.content.Context;
import android.content.SharedPreferences;
import android.net.Uri;

import androidx.documentfile.provider.DocumentFile;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

final class MediaLibrary {
    static final String PREFS = "dnio_gujarati_v2";
    static final String PREF_TREE_URI = "tree_uri";

    static final class Item {
        final String id;
        final String filename;
        final String title;
        final String topic;
        final String kind;
        Uri uri;

        Item(JSONObject object) throws JSONException {
            id = object.getString("id");
            filename = object.getString("filename");
            title = object.optString("title", filename);
            topic = object.optString("topic", "Gujarati");
            kind = object.optString("kind", "Lesson");
        }
    }

    private final Context context;
    private final SharedPreferences prefs;
    private final List<Item> items = new ArrayList<>();
    private final Map<String, Item> byId = new LinkedHashMap<>();
    private String folderLabel = "";
    private boolean scanning = false;
    private String lastError = "";

    MediaLibrary(Context context) {
        this.context = context.getApplicationContext();
        prefs = this.context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
        loadCatalog();
    }

    private void loadCatalog() {
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(
                context.getAssets().open("catalog.json"), StandardCharsets.UTF_8))) {
            StringBuilder builder = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) builder.append(line);
            JSONArray array = new JSONArray(builder.toString());
            for (int i = 0; i < array.length(); i++) {
                Item item = new Item(array.getJSONObject(i));
                items.add(item);
                byId.put(item.id, item);
            }
        } catch (Exception error) {
            lastError = "Could not load the built-in catalogue: " + error.getMessage();
        }
    }

    SharedPreferences preferences() {
        return prefs;
    }

    String getTreeUriString() {
        return prefs.getString(PREF_TREE_URI, "");
    }

    void setTreeUri(Uri uri) {
        prefs.edit().putString(PREF_TREE_URI, uri == null ? "" : uri.toString()).apply();
    }

    synchronized void clearMatches() {
        for (Item item : items) item.uri = null;
        folderLabel = "";
    }

    synchronized void scan(Uri treeUri) {
        scanning = true;
        lastError = "";
        clearMatches();
        if (treeUri == null) {
            scanning = false;
            return;
        }

        try {
            DocumentFile root = DocumentFile.fromTreeUri(context, treeUri);
            if (root == null || !root.exists() || !root.isDirectory()) {
                throw new IllegalStateException("The selected folder is no longer available.");
            }
            folderLabel = root.getName() == null ? "Selected folder" : root.getName();

            Map<String, Uri> exact = new HashMap<>();
            Map<String, List<Uri>> canonical = new HashMap<>();
            scanFiles(root, exact, canonical, 0);

            for (Item item : items) {
                String exactKey = item.filename.toLowerCase(Locale.ROOT);
                Uri match = exact.get(exactKey);
                if (match == null) {
                    List<Uri> candidates = canonical.get(canonicalName(item.filename));
                    if (candidates != null && candidates.size() == 1) match = candidates.get(0);
                }
                item.uri = match;
            }
        } catch (Exception error) {
            lastError = error.getMessage() == null ? error.toString() : error.getMessage();
        } finally {
            scanning = false;
        }
    }

    private void scanFiles(DocumentFile directory, Map<String, Uri> exact,
                           Map<String, List<Uri>> canonical, int depth) {
        if (depth > 8) return;
        DocumentFile[] children;
        try {
            children = directory.listFiles();
        } catch (Exception ignored) {
            return;
        }
        for (DocumentFile child : children) {
            if (child.isDirectory()) {
                scanFiles(child, exact, canonical, depth + 1);
                continue;
            }
            String name = child.getName();
            if (name == null || !name.toLowerCase(Locale.ROOT).endsWith(".mp4")) continue;
            exact.putIfAbsent(name.toLowerCase(Locale.ROOT), child.getUri());
            canonical.computeIfAbsent(canonicalName(name), key -> new ArrayList<>()).add(child.getUri());
        }
    }

    private static String canonicalName(String name) {
        String lower = name.toLowerCase(Locale.ROOT)
                .replace("(1)", "")
                .replaceAll("[^a-z0-9]+", "");
        return lower.endsWith("mp4") ? lower.substring(0, lower.length() - 3) : lower;
    }

    synchronized Item get(String id) {
        return byId.get(id);
    }

    synchronized List<Item> availableItems() {
        List<Item> result = new ArrayList<>();
        for (Item item : items) if (item.uri != null) result.add(item);
        return result;
    }

    synchronized JSONObject statusJson() {
        JSONObject status = new JSONObject();
        JSONArray available = new JSONArray();
        JSONArray missing = new JSONArray();
        JSONArray missingNames = new JSONArray();
        JSONObject reviews = new JSONObject();
        try {
            for (Item item : items) {
                if (item.uri != null) available.put(item.id);
                else {
                    missing.put(item.id);
                    missingNames.put(item.filename);
                }
                String review = prefs.getString("review:" + item.id, "");
                if (review != null && !review.isEmpty()) reviews.put(item.id, review);
            }
            status.put("scanning", scanning);
            status.put("folderSelected", !getTreeUriString().isEmpty());
            status.put("folderLabel", folderLabel);
            status.put("availableCount", available.length());
            status.put("totalCount", items.size());
            status.put("availableIds", available);
            status.put("missingIds", missing);
            status.put("missingNames", missingNames);
            status.put("reviews", reviews);
            status.put("error", lastError == null ? "" : lastError);
        } catch (JSONException ignored) {
        }
        return status;
    }
}
