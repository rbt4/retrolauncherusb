package com.dnio.gujarati.offline;

import android.app.Activity;
import android.graphics.Color;
import android.net.Uri;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.MediaController;
import android.widget.TextView;
import android.widget.Toast;
import android.widget.VideoView;

import java.util.ArrayList;

public class PlayerActivity extends Activity {
    static final String EXTRA_IDS = "ids";
    static final String EXTRA_URIS = "uris";
    static final String EXTRA_TITLES = "titles";
    static final String EXTRA_METADATA = "metadata";
    static final String EXTRA_INDEX = "index";

    private ArrayList<String> ids;
    private ArrayList<String> uris;
    private ArrayList<String> titles;
    private ArrayList<String> metadata;
    private int index;
    private VideoView video;
    private TextView title;
    private TextView detail;
    private Button good;
    private Button edit;
    private Button bad;
    private android.content.SharedPreferences prefs;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        getWindow().setStatusBarColor(Color.BLACK);
        getWindow().setNavigationBarColor(Color.BLACK);
        prefs = getSharedPreferences(MediaLibrary.PREFS, MODE_PRIVATE);

        ids = getIntent().getStringArrayListExtra(EXTRA_IDS);
        uris = getIntent().getStringArrayListExtra(EXTRA_URIS);
        titles = getIntent().getStringArrayListExtra(EXTRA_TITLES);
        metadata = getIntent().getStringArrayListExtra(EXTRA_METADATA);
        index = getIntent().getIntExtra(EXTRA_INDEX, 0);

        if (ids == null || uris == null || titles == null || ids.isEmpty()) {
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

        MediaController controller = new MediaController(this);
        controller.setAnchorView(video);
        video.setMediaController(controller);
        video.setOnCompletionListener(mp -> {
            savePosition(0);
            switchVideo(1);
        });
        video.setOnErrorListener((mp, what, extra) -> {
            Toast.makeText(this, "This video could not be played. Try copying the original MP4 again.",
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
        String id = ids.get(index);
        title.setText(titles.get(index));
        detail.setText(metadata != null && index < metadata.size() ? metadata.get(index) : "Gujarati video");
        updateReviewButtons();

        video.setVideoURI(Uri.parse(uris.get(index)));
        video.setOnPreparedListener(player -> {
            int saved = prefs.getInt("position:" + id, 0);
            if (saved > 2000 && saved < player.getDuration() - 8000) video.seekTo(saved);
            video.start();
        });
        video.requestFocus();
    }

    private void switchVideo(int direction) {
        savePosition(video.getCurrentPosition());
        video.stopPlayback();
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
}
