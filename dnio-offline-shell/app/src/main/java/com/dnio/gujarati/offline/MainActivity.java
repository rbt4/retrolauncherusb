package com.dnio.gujarati.offline;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.WindowManager;
import android.webkit.JavascriptInterface;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;

public class MainActivity extends Activity {
    private static final String PREFS = "dnio_gujarati_v2";

    private WebView webView;
    private final ArrayList<Item> items = new ArrayList<>();
    private SharedPreferences prefs;
    private boolean pageReady;

    @SuppressLint({"SetJavaScriptEnabled", "AddJavascriptInterface"})
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
        loadCatalog();

        webView = new WebView(this);
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setAllowFileAccess(true);
        settings.setAllowContentAccess(false);
        settings.setMediaPlaybackRequiresUserGesture(true);
        webView.addJavascriptInterface(new Bridge(), "DNIO");
        webView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView view, String url) {
                pageReady = true;
                notifyStatus();
            }
        });
        setContentView(webView);
        webView.loadUrl("file:///android_asset/index.html");
    }

    private void loadCatalog() {
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(
                getAssets().open("catalog.json"), StandardCharsets.UTF_8))) {
            StringBuilder text = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) text.append(line);
            JSONArray array = new JSONArray(text.toString());
            for (int i = 0; i < array.length(); i++) {
                JSONObject row = array.getJSONObject(i);
                items.add(new Item(
                        row.getString("id"),
                        row.getString("title"),
                        row.getString("topic"),
                        row.getString("kind"),
                        row.getString("filename")
                ));
            }
        } catch (Exception error) {
            Toast.makeText(this, "The embedded catalogue could not be opened: " + error.getMessage(),
                    Toast.LENGTH_LONG).show();
        }
    }

    private void notifyStatus() {
        if (!pageReady || webView == null) return;
        webView.evaluateJavascript("window.DNIO_applyStatus(" + statusJson() + ");", null);
    }

    private JSONObject statusJson() {
        JSONObject out = new JSONObject();
        JSONArray ids = new JSONArray();
        JSONObject reviews = new JSONObject();
        try {
            for (Item item : items) {
                ids.put(item.id);
                String review = prefs.getString("review:" + item.id, "");
                if (review != null && !review.isEmpty()) reviews.put(item.id, review);
            }
            out.put("embedded", true);
            out.put("availableCount", items.size());
            out.put("totalCount", items.size());
            out.put("availableIds", ids);
            out.put("missingIds", new JSONArray());
            out.put("missingNames", new JSONArray());
            out.put("reviews", reviews);
            out.put("error", "");
        } catch (Exception ignored) {
        }
        return out;
    }

    private void openPlayer(String selectedId) {
        if (items.isEmpty()) {
            Toast.makeText(this, "The embedded catalogue is unavailable.", Toast.LENGTH_LONG).show();
            return;
        }

        ArrayList<String> ids = new ArrayList<>();
        ArrayList<String> titles = new ArrayList<>();
        ArrayList<String> metadata = new ArrayList<>();
        int selected = -1;
        for (int index = 0; index < items.size(); index++) {
            Item item = items.get(index);
            ids.add(item.id);
            titles.add(item.title);
            metadata.add(item.kind + " • " + item.topic + " • " + item.filename);
            if (item.id.equals(selectedId)) selected = index;
        }
        if (selected < 0) {
            Toast.makeText(this, "That embedded video was not found.", Toast.LENGTH_LONG).show();
            return;
        }

        Intent intent = new Intent(this, PlayerActivity.class);
        intent.putStringArrayListExtra(PlayerActivity.EXTRA_IDS, ids);
        intent.putStringArrayListExtra(PlayerActivity.EXTRA_TITLES, titles);
        intent.putStringArrayListExtra(PlayerActivity.EXTRA_METADATA, metadata);
        intent.putExtra(PlayerActivity.EXTRA_INDEX, selected);
        startActivity(intent);
    }

    @Override
    protected void onResume() {
        super.onResume();
        notifyStatus();
    }

    @Override
    protected void onDestroy() {
        if (webView != null) {
            webView.stopLoading();
            webView.loadUrl("about:blank");
            webView.destroy();
        }
        super.onDestroy();
    }

    private static final class Item {
        final String id;
        final String title;
        final String topic;
        final String kind;
        final String filename;

        Item(String id, String title, String topic, String kind, String filename) {
            this.id = id;
            this.title = title;
            this.topic = topic;
            this.kind = kind;
            this.filename = filename;
        }
    }

    public final class Bridge {
        @JavascriptInterface
        public String getStatus() {
            return statusJson().toString();
        }

        @JavascriptInterface
        public void play(String id) {
            runOnUiThread(() -> openPlayer(id));
        }
    }
}
