package com.dnio.gujarati.offline;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.WindowManager;
import android.webkit.JavascriptInterface;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;

import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MainActivity extends Activity {
    private static final int REQUEST_FOLDER = 4202;

    private WebView webView;
    private MediaLibrary library;
    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private boolean pageReady = false;

    @SuppressLint({"SetJavaScriptEnabled", "AddJavascriptInterface"})
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        library = new MediaLibrary(this);

        webView = new WebView(this);
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setAllowFileAccess(true);
        settings.setAllowContentAccess(true);
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

        String tree = library.getTreeUriString();
        if (!tree.isEmpty()) scanAsync(Uri.parse(tree));
    }

    private void chooseFolder() {
        Intent intent = new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE);
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION |
                Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION |
                Intent.FLAG_GRANT_PREFIX_URI_PERMISSION);
        startActivityForResult(intent, REQUEST_FOLDER);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode != REQUEST_FOLDER || resultCode != RESULT_OK || data == null) return;
        Uri uri = data.getData();
        if (uri == null) return;
        try {
            getContentResolver().takePersistableUriPermission(uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION);
            library.setTreeUri(uri);
            scanAsync(uri);
        } catch (Exception error) {
            Toast.makeText(this, "Could not keep access to that folder: " + error.getMessage(),
                    Toast.LENGTH_LONG).show();
        }
    }

    private void scanAsync(Uri uri) {
        executor.execute(() -> {
            library.scan(uri);
            runOnUiThread(this::notifyStatus);
        });
    }

    private void notifyStatus() {
        if (!pageReady || webView == null) return;
        JSONObject status = library.statusJson();
        webView.evaluateJavascript("window.DNIO_applyStatus(" + status.toString() + ");", null);
    }

    private void openPlayer(String id) {
        List<MediaLibrary.Item> available = library.availableItems();
        if (available.isEmpty()) {
            Toast.makeText(this, "Choose the folder containing the Gujarati MP4 files first.",
                    Toast.LENGTH_LONG).show();
            return;
        }

        ArrayList<String> ids = new ArrayList<>();
        ArrayList<String> uris = new ArrayList<>();
        ArrayList<String> titles = new ArrayList<>();
        ArrayList<String> metadata = new ArrayList<>();
        int selected = -1;

        for (int index = 0; index < available.size(); index++) {
            MediaLibrary.Item item = available.get(index);
            ids.add(item.id);
            uris.add(item.uri.toString());
            titles.add(item.title);
            metadata.add(item.kind + " • " + item.topic + " • " + item.filename);
            if (item.id.equals(id)) selected = index;
        }
        if (selected < 0) {
            Toast.makeText(this, "That video is missing from the selected folder.",
                    Toast.LENGTH_LONG).show();
            return;
        }

        Intent intent = new Intent(this, PlayerActivity.class);
        intent.putStringArrayListExtra(PlayerActivity.EXTRA_IDS, ids);
        intent.putStringArrayListExtra(PlayerActivity.EXTRA_URIS, uris);
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
        executor.shutdownNow();
        if (webView != null) {
            webView.stopLoading();
            webView.loadUrl("about:blank");
            webView.destroy();
        }
        super.onDestroy();
    }

    public final class Bridge {
        @JavascriptInterface
        public String getStatus() {
            return library.statusJson().toString();
        }

        @JavascriptInterface
        public void chooseFolder() {
            runOnUiThread(MainActivity.this::chooseFolder);
        }

        @JavascriptInterface
        public void rescan() {
            String tree = library.getTreeUriString();
            if (tree.isEmpty()) runOnUiThread(MainActivity.this::chooseFolder);
            else scanAsync(Uri.parse(tree));
        }

        @JavascriptInterface
        public void play(String id) {
            runOnUiThread(() -> openPlayer(id));
        }
    }
}
