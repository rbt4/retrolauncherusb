package com.dnio.gujarati.offline;

import android.app.Activity;
import android.content.SharedPreferences;
import android.content.pm.ActivityInfo;
import android.content.res.AssetManager;
import android.graphics.Color;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.MediaController;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;
import android.widget.VideoView;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class PlayerActivity extends Activity {
    static final String EXTRA_IDS = "ids";
    static final String EXTRA_TITLES = "titles";
    static final String EXTRA_METADATA = "metadata";
    static final String EXTRA_INDEX = "index";

    private ArrayList<String> ids;
    private ArrayList<String> titles;
    private ArrayList<String> metadata;
    private int index;
    private VideoView video;
    private TextView title;
    private TextView detail;
    private TextView preparingText;
    private View preparing;
    private Button good;
    private Button edit;
    private Button bad;
    private SharedPreferences prefs;
    private final ExecutorService copyExecutor = Executors.newSingleThreadExecutor();
    private int loadGeneration;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        getWindow().setStatusBarColor(Color.BLACK);
        getWindow().setNavigationBarColor(Color.BLACK);
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE);
        prefs = getSharedPreferences("dnio_gujarati_v2", MODE_PRIVATE);

        ids = getIntent().getStringArrayListExtra(EXTRA_IDS);
        titles = getIntent().getStringArrayListExtra(EXTRA_TITLES);
        metadata = getIntent().getStringArrayListExtra(EXTRA_METADATA);
        index = getIntent().getIntExtra(EXTRA_INDEX, 0);

        if (ids == null || titles == null || ids.isEmpty()) {
            finish();
            return;
        }

        FrameLayout root = new FrameLayout(this);
        root.setBackgroundColor(Color.BLACK);

        video = new VideoView(this);
        FrameLayout.LayoutParams videoParams = new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
        videoParams.setMargins(0, dp(54), 0, dp(58));
        root.addView(video, videoParams);

        LinearLayout top = new LinearLayout(this);
        top.setOrientation(LinearLayout.HORIZONTAL);
        top.setGravity(Gravity.CENTER_VERTICAL);
        top.setPadding(dp(8), dp(5), dp(10), dp(5));
        top.setBackgroundColor(Color.rgb(12, 20, 29));
        Button back = button("← Library");
        back.setOnClickListener(v -> finish());
        top.addView(back, new LinearLayout.LayoutParams(dp(110), dp(44)));

        LinearLayout labels = new LinearLayout(this);
        labels.setOrientation(LinearLayout.VERTICAL);
        labels.setPadding(dp(10), 0, 0, 0);
        title = new TextView(this);
        title.setTextColor(Color.WHITE);
        title.setTextSize(17);
        title.setSingleLine(true);
        detail = new TextView(this);
        detail.setTextColor(Color.rgb(160, 177, 194));
        detail.setTextSize(11);
        detail.setSingleLine(true);
        labels.addView(title);
        labels.addView(detail);
        top.addView(labels, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));
        root.addView(top, new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(54), Gravity.TOP));

        LinearLayout bottom = new LinearLayout(this);
        bottom.setOrientation(LinearLayout.HORIZONTAL);
        bottom.setGravity(Gravity.CENTER);
        bottom.setPadding(dp(5), dp(6), dp(5), dp(6));
        bottom.setBackgroundColor(Color.rgb(12, 20, 29));

        Button prev = button("◀ Prev");
        good = button("✓ Good");
        edit = button("△ Edit");
        bad = button("✕ Bad");
        Button next = button("Next ▶");
        prev.setOnClickListener(v -> switchVideo(-1));
        next.setOnClickListener(v -> switchVideo(1));
        good.setOnClickListener(v -> setReview("Good"));
        edit.setOnClickListener(v -> setReview("Needs Edit"));
        bad.setOnClickListener(v -> setReview("Bad"));
        for (Button button : new Button[]{prev, good, edit, bad, next}) {
            bottom.addView(button, new LinearLayout.LayoutParams(0, dp(46), 1));
        }
        root.addView(bottom, new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(58), Gravity.BOTTOM));

        LinearLayout waitBox = new LinearLayout(this);
        waitBox.setOrientation(LinearLayout.VERTICAL);
        waitBox.setGravity(Gravity.CENTER);
        waitBox.setPadding(dp(24), dp(20), dp(24), dp(20));
        waitBox.setBackgroundColor(Color.rgb(10, 15, 22));
        ProgressBar spinner = new ProgressBar(this);
        preparingText = new TextView(this);
        preparingText.setTextColor(Color.WHITE);
        preparingText.setTextSize(15);
        preparingText.setGravity(Gravity.CENTER);
        preparingText.setPadding(0, dp(12), 0, 0);
        waitBox.addView(spinner, new LinearLayout.LayoutParams(dp(48), dp(48)));
        waitBox.addView(preparingText, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        FrameLayout.LayoutParams waitParams = new FrameLayout.LayoutParams(
                dp(320), dp(150), Gravity.CENTER);
        root.addView(waitBox, waitParams);
        preparing = waitBox;

        MediaController controller = new MediaController(this);
        controller.setAnchorView(video);
        video.setMediaController(controller);
        video.setOnCompletionListener(mp -> {
            savePosition(0);
            switchVideo(1);
        });
        video.setOnErrorListener((mp, what, extra) -> {
            preparing.setVisibility(View.GONE);
            Toast.makeText(this,
                    "The embedded original could not be played. Reinstall the APK and try again.",
                    Toast.LENGTH_LONG).show();
            return true;
        });

        setContentView(root);
        hideSystemUi();
        loadCurrent();
    }

    private void loadCurrent() {
        if (index < 0) index = ids.size() - 1;
        if (index >= ids.size()) index = 0;
        final String id = ids.get(index);
        final int generation = ++loadGeneration;

        title.setText(titles.get(index));
        detail.setText(metadata != null && index < metadata.size()
                ? metadata.get(index) : "Embedded Gujarati original");
        updateReviewButtons();
        preparingText.setText("Preparing the original video…\nFirst play can take a few seconds.");
        preparing.setVisibility(View.VISIBLE);
        video.stopPlayback();

        copyExecutor.execute(() -> {
            try {
                File playbackDir = new File(getCacheDir(), "dnio_playback");
                if (!playbackDir.exists() && !playbackDir.mkdirs()) {
                    throw new IllegalStateException("Could not create playback cache");
                }
                File ready = new File(playbackDir, id + ".mp4");
                clearOtherVideos(playbackDir, ready.getName());
                if (!ready.isFile() || ready.length() < 1024) {
                    File part = new File(playbackDir, id + ".part");
                    if (part.exists() && !part.delete()) {
                        throw new IllegalStateException("Could not reset temporary file");
                    }
                    copyEmbeddedAsset("videos/" + id + ".mp4", part);
                    if (ready.exists() && !ready.delete()) {
                        throw new IllegalStateException("Could not replace playback file");
                    }
                    if (!part.renameTo(ready)) {
                        throw new IllegalStateException("Could not finish playback file");
                    }
                }
                runOnUiThread(() -> startPreparedVideo(generation, id, ready));
            } catch (Exception error) {
                runOnUiThread(() -> {
                    if (generation != loadGeneration || isFinishing()) return;
                    preparing.setVisibility(View.GONE);
                    Toast.makeText(this,
                            "Could not prepare the embedded video: " + error.getMessage(),
                            Toast.LENGTH_LONG).show();
                });
            }
        });
    }

    private void copyEmbeddedAsset(String assetPath, File destination) throws Exception {
        try (InputStream raw = getAssets().open(assetPath, AssetManager.ACCESS_STREAMING);
             BufferedInputStream input = new BufferedInputStream(raw, 1024 * 1024);
             BufferedOutputStream output = new BufferedOutputStream(
                     new FileOutputStream(destination), 1024 * 1024)) {
            byte[] buffer = new byte[1024 * 1024];
            int count;
            while ((count = input.read(buffer)) != -1) output.write(buffer, 0, count);
            output.flush();
        }
        if (destination.length() < 1024) throw new IllegalStateException("Embedded video is incomplete");
    }

    private void clearOtherVideos(File directory, String keepName) {
        File[] files = directory.listFiles();
        if (files == null) return;
        for (File file : files) {
            if (!file.getName().equals(keepName)) file.delete();
        }
    }

    private void startPreparedVideo(int generation, String id, File file) {
        if (generation != loadGeneration || isFinishing()) return;
        video.setVideoPath(file.getAbsolutePath());
        video.setOnPreparedListener(player -> {
            if (generation != loadGeneration) return;
            preparing.setVisibility(View.GONE);
            int saved = prefs.getInt("position:" + id, 0);
            if (saved > 2000 && saved < player.getDuration() - 8000) video.seekTo(saved);
            video.start();
        });
        video.requestFocus();
    }

    private void switchVideo(int direction) {
        savePosition(video == null ? 0 : video.getCurrentPosition());
        loadGeneration++;
        if (video != null) video.stopPlayback();
        index = (index + direction + ids.size()) % ids.size();
        loadCurrent();
    }

    private void savePosition(int position) {
        if (ids == null || ids.isEmpty() || index < 0 || index >= ids.size()) return;
        prefs.edit().putInt("position:" + ids.get(index), Math.max(0, position)).apply();
    }

    private void setReview(String review) {
        prefs.edit().putString("review:" + ids.get(index), review).apply();
        updateReviewButtons();
    }

    private void updateReviewButtons() {
        String review = prefs.getString("review:" + ids.get(index), "");
        good.setTextColor("Good".equals(review) ? Color.rgb(69, 206, 139) : Color.WHITE);
        edit.setTextColor("Needs Edit".equals(review) ? Color.rgb(243, 189, 85) : Color.WHITE);
        bad.setTextColor("Bad".equals(review) ? Color.rgb(239, 113, 128) : Color.WHITE);
    }

    private Button button(String text) {
        Button button = new Button(this);
        button.setText(text);
        button.setTextColor(Color.WHITE);
        button.setTextSize(11);
        button.setAllCaps(false);
        button.setBackgroundColor(Color.rgb(24, 37, 52));
        return button;
    }

    private void hideSystemUi() {
        getWindow().getDecorView().setSystemUiVisibility(
                View.SYSTEM_UI_FLAG_FULLSCREEN |
                        View.SYSTEM_UI_FLAG_HIDE_NAVIGATION |
                        View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }

    @Override
    protected void onPause() {
        savePosition(video == null ? 0 : video.getCurrentPosition());
        if (video != null) video.pause();
        super.onPause();
    }

    @Override
    protected void onResume() {
        super.onResume();
        hideSystemUi();
    }

    @Override
    protected void onDestroy() {
        loadGeneration++;
        copyExecutor.shutdownNow();
        if (video != null) video.stopPlayback();
        super.onDestroy();
    }
}
