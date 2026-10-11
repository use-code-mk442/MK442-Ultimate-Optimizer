package com.mk442.robloxbooster;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.view.Display;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.widget.HorizontalScrollView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import java.util.Locale;

/**
 * MK442 Roblox Booster Mobile.
 * This app is intentionally a safe companion/settings guide. Android sandboxing means
 * a normal third-party app cannot edit Roblox's private files or inject ReShade effects.
 * The saved FPS number is a preference/display target only, not an FPS unlocker.
 */
public class MainActivity extends Activity {
    private static final String PREFS = "mk442_mobile_prefs";
    private static final String ROBLOX_PACKAGE = "com.roblox.client";
    private static final int BG = Color.rgb(7, 11, 22);
    private static final int CARD = Color.rgb(14, 23, 41);
    private static final int CARD2 = Color.rgb(17, 32, 54);
    private static final int CYAN = Color.rgb(83, 224, 255);
    private static final int GREEN = Color.rgb(93, 246, 174);
    private static final int TEXT = Color.rgb(242, 248, 255);
    private static final int MUTED = Color.rgb(153, 174, 198);
    private static final int GOLD = Color.rgb(255, 211, 112);

    private SharedPreferences prefs;
    private int targetFps;
    private String selectedProfile;
    private TextView targetNote;
    private TextView currentRateText;
    private TextView maxRateText;
    private TextView profileDescription;
    private LinearLayout fpsChipRow;
    private LinearLayout profileRow;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
        targetFps = prefs.getInt("target_fps", 120);
        selectedProfile = prefs.getString("profile", "performance");

        Window w = getWindow();
        w.setStatusBarColor(BG);
        w.setNavigationBarColor(BG);
        if (Build.VERSION.SDK_INT >= 29) {
            w.setNavigationBarContrastEnforced(false);
            w.setStatusBarContrastEnforced(false);
        }

        ScrollView scroller = new ScrollView(this);
        scroller.setFillViewport(true);
        scroller.setBackgroundColor(BG);
        scroller.setClipToPadding(false);

        LinearLayout page = new LinearLayout(this);
        page.setOrientation(LinearLayout.VERTICAL);
        page.setLayoutDirection(View.LAYOUT_DIRECTION_RTL);
        page.setPadding(dp(18), dp(14), dp(18), dp(28));
        scroller.addView(page, new ScrollView.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));

        page.addView(buildHeader());
        page.addView(buildHero(), lpTop(18));
        page.addView(buildRefreshCard(), lpTop(14));
        page.addView(buildFpsCard(), lpTop(14));
        page.addView(buildProfilesCard(), lpTop(14));
        page.addView(buildActionsCard(), lpTop(14));
        page.addView(buildGuidesCard(), lpTop(14));
        page.addView(buildVisualLimitsCard(), lpTop(14));
        TextView credit = text("برمجة mk442  •  Mobile Edition 1.0", 12, MUTED, false);
        credit.setGravity(Gravity.CENTER);
        page.addView(credit, lpTop(20));

        setContentView(scroller);
        refreshDeviceInfo();
        updateTargetNote();
        updateProfileDescription();
    }

    private View buildHeader() {
        LinearLayout row = new LinearLayout(this);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setLayoutDirection(View.LAYOUT_DIRECTION_LTR);

        LinearLayout brand = new LinearLayout(this);
        brand.setOrientation(LinearLayout.VERTICAL);
        TextView title = text("MK442", 22, TEXT, true);
        TextView subtitle = text("ROBLOX MOBILE BOOSTER", 10, CYAN, true);
        subtitle.setLetterSpacing(0.08f);
        brand.addView(title);
        brand.addView(subtitle);
        row.addView(brand, new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1));

        TextView badge = text("S26 ULTRA • READY", 10, GREEN, true);
        badge.setGravity(Gravity.CENTER);
        badge.setPadding(dp(11), dp(8), dp(11), dp(8));
        badge.setBackground(roundRect(Color.rgb(10, 41, 43), Color.rgb(36, 115, 111), 999, 1));
        row.addView(badge);
        return row;
    }

    private View buildHero() {
        LinearLayout card = card(18, true);
        card.setBackground(gradient(new int[]{Color.rgb(17, 49, 77), Color.rgb(20, 27, 57)}, 24, CYAN, 1));

        TextView eyebrow = text("⚡  أداء • تخصيص • معلومات الجهاز", 12, GREEN, true);
        card.addView(eyebrow);
        TextView heading = text("خلّ تجربة Roblox أرتب وأوضح", 23, TEXT, true);
        heading.setPadding(0, dp(8), 0, dp(5));
        card.addView(heading);
        TextView body = text("لوحة جوال من MK442 لعرض تردد الشاشة، حفظ هدف FPS، وفتح إعدادات الجهاز المهمة. بدون تعديل ملفات Roblox أو طلب صلاحيات خطرة.", 14, MUTED, false);
        body.setLineSpacing(dp(3), 1.0f);
        card.addView(body);

        TextView disclaimer = text("مهم: التطبيق لا يستطيع إجبار Roblox على 120+ FPS؛ يعرض قدرات الشاشة ويوجهك للإعدادات الصحيحة.", 12, GOLD, true);
        disclaimer.setPadding(dp(12), dp(10), dp(12), dp(10));
        disclaimer.setBackground(roundRect(Color.rgb(53, 42, 23), Color.rgb(126, 95, 39), 14, 1));
        card.addView(disclaimer, lpTop(14));
        return card;
    }

    private View buildRefreshCard() {
        LinearLayout card = card(16, false);
        card.addView(sectionTitle("📱  تردد شاشة جهازك"));
        TextView explainer = text("Hz هو معدل تحديث الشاشة، وليس قياس FPS اللعبة نفسها.", 12, MUTED, false);
        card.addView(explainer, lpTop(4));

        LinearLayout values = new LinearLayout(this);
        values.setOrientation(LinearLayout.HORIZONTAL);
        values.setLayoutDirection(View.LAYOUT_DIRECTION_LTR);
        values.setPadding(0, dp(12), 0, 0);
        values.addView(rateTile("التردد الحالي", "— Hz", true), new LinearLayout.LayoutParams(0, dp(82), 1));
        values.addView(spaceW(10), new LinearLayout.LayoutParams(dp(10), 1));
        values.addView(rateTile("أعلى تردد متاح", "— Hz", false), new LinearLayout.LayoutParams(0, dp(82), 1));
        card.addView(values);

        TextView model = text("الجهاز: " + Build.MODEL, 12, MUTED, false);
        card.addView(model, lpTop(10));
        return card;
    }

    private View rateTile(String label, String value, boolean highlight) {
        LinearLayout tile = new LinearLayout(this);
        tile.setOrientation(LinearLayout.VERTICAL);
        tile.setGravity(Gravity.CENTER);
        tile.setBackground(roundRect(Color.rgb(9, 17, 31), Color.rgb(37, 63, 86), 16, 1));
        TextView l = text(label, 11, MUTED, false);
        TextView v = text(value, 24, highlight ? CYAN : GREEN, true);
        tile.addView(l);
        tile.addView(v, lpTop(4));
        if (highlight) currentRateText = v; else maxRateText = v;
        return tile;
    }

    private View buildFpsCard() {
        LinearLayout card = card(16, false);
        card.addView(sectionTitle("🎯  هدف FPS داخل التطبيق"));
        TextView intro = text("اختر الرقم الذي تبي تراقبه كتفضيل. اختيار 500 أو 1000 لا يغيّر حد اللعبة ولا يعني أنك ستحصل على هذه الإطارات.", 13, MUTED, false);
        intro.setLineSpacing(dp(2), 1f);
        card.addView(intro, lpTop(5));

        HorizontalScrollView horizontal = new HorizontalScrollView(this);
        horizontal.setHorizontalScrollBarEnabled(false);
        horizontal.setFillViewport(false);
        fpsChipRow = new LinearLayout(this);
        fpsChipRow.setOrientation(LinearLayout.HORIZONTAL);
        fpsChipRow.setLayoutDirection(View.LAYOUT_DIRECTION_LTR);
        horizontal.addView(fpsChipRow, new HorizontalScrollView.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        card.addView(horizontal, lpTop(12));

        targetNote = text("", 12, GOLD, false);
        targetNote.setPadding(dp(12), dp(10), dp(12), dp(10));
        targetNote.setLineSpacing(dp(2), 1f);
        targetNote.setBackground(roundRect(Color.rgb(43, 36, 24), Color.rgb(103, 81, 41), 14, 1));
        card.addView(targetNote, lpTop(12));
        rebuildFpsChips();
        return card;
    }

    private void rebuildFpsChips() {
        if (fpsChipRow == null) return;
        fpsChipRow.removeAllViews();
        int[] values = new int[]{30, 60, 90, 120, 144, 240, 500, 1000};
        for (int value : values) {
            final int chosen = value;
            TextView chip = text(String.valueOf(value), 14, targetFps == value ? BG : TEXT, true);
            chip.setGravity(Gravity.CENTER);
            chip.setMinWidth(dp(52));
            chip.setPadding(dp(13), dp(12), dp(13), dp(12));
            chip.setBackground(targetFps == value
                    ? gradient(new int[]{CYAN, Color.rgb(93, 246, 174)}, 13, CYAN, 1)
                    : roundRect(Color.rgb(11, 20, 36), Color.rgb(42, 63, 84), 13, 1));
            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
            params.setMargins(0, 0, dp(8), 0);
            fpsChipRow.addView(chip, params);
            chip.setOnClickListener(v -> {
                targetFps = chosen;
                prefs.edit().putInt("target_fps", targetFps).apply();
                rebuildFpsChips();
                updateTargetNote();
            });
        }
    }

    private View buildProfilesCard() {
        LinearLayout card = card(16, false);
        card.addView(sectionTitle("🕹️  ملفات التوصية"));
        TextView intro = text("اختر نوع التجربة؛ هذا يغيّر توصيات التطبيق فقط، ولا يكتب إعدادات داخل Roblox.", 12, MUTED, false);
        card.addView(intro, lpTop(4));

        profileRow = new LinearLayout(this);
        profileRow.setOrientation(LinearLayout.HORIZONTAL);
        profileRow.setLayoutDirection(View.LAYOUT_DIRECTION_RTL);
        card.addView(profileRow, lpTop(12));
        rebuildProfileButtons();

        profileDescription = text("", 13, TEXT, false);
        profileDescription.setLineSpacing(dp(2), 1f);
        profileDescription.setPadding(dp(12), dp(11), dp(12), dp(11));
        profileDescription.setBackground(roundRect(Color.rgb(9, 19, 34), Color.rgb(33, 57, 78), 14, 1));
        card.addView(profileDescription, lpTop(10));

        TextView save = actionButton("حفظ التفضيل", false);
        card.addView(save, lpTop(10));
        save.setOnClickListener(v -> {
            prefs.edit().putString("profile", selectedProfile).putInt("target_fps", targetFps).apply();
            Toast.makeText(this, "تم حفظ تفضيلات MK442 داخل التطبيق فقط", Toast.LENGTH_SHORT).show();
        });
        return card;
    }

    private void rebuildProfileButtons() {
        if (profileRow == null) return;
        profileRow.removeAllViews();
        addProfileButton("تنافسي", "performance", profileRow);
        addProfileButton("متوازن", "balanced", profileRow);
        addProfileButton("جودة", "visual", profileRow);
    }

    private void addProfileButton(String label, String key, LinearLayout row) {
        boolean active = selectedProfile.equals(key);
        TextView b = text(label, 13, active ? BG : TEXT, true);
        b.setGravity(Gravity.CENTER);
        b.setPadding(dp(5), dp(13), dp(5), dp(13));
        b.setBackground(active ? gradient(new int[]{CYAN, GREEN}, 13, CYAN, 1)
                : roundRect(Color.rgb(10, 19, 34), Color.rgb(44, 64, 84), 13, 1));
        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        p.setMargins(dp(3), 0, dp(3), 0);
        row.addView(b, p);
        b.setOnClickListener(v -> {
            selectedProfile = key;
            prefs.edit().putString("profile", selectedProfile).apply();
            rebuildProfileButtons();
            updateProfileDescription();
        });
    }

    private View buildActionsCard() {
        LinearLayout card = card(16, false);
        card.addView(sectionTitle("🚀  اختصارات سريعة"));

        LinearLayout firstRow = new LinearLayout(this);
        firstRow.setOrientation(LinearLayout.HORIZONTAL);
        firstRow.setLayoutDirection(View.LAYOUT_DIRECTION_RTL);
        TextView launch = actionButton("فتح Roblox", true);
        TextView display = actionButton("إعدادات الشاشة", false);
        firstRow.addView(launch, new LinearLayout.LayoutParams(0, dp(50), 1));
        firstRow.addView(spaceW(9), new LinearLayout.LayoutParams(dp(9), 1));
        firstRow.addView(display, new LinearLayout.LayoutParams(0, dp(50), 1));
        card.addView(firstRow, lpTop(12));
        launch.setOnClickListener(v -> launchRoblox());
        display.setOnClickListener(v -> openDisplaySettings());

        TextView appInfo = actionButton("معلومات تطبيق Roblox / البطارية", false);
        card.addView(appInfo, lpTop(9));
        appInfo.setOnClickListener(v -> openRobloxAppInfo());

        TextView refresh = actionButton("تحديث قراءة الشاشة", false);
        card.addView(refresh, lpTop(9));
        refresh.setOnClickListener(v -> {
            refreshDeviceInfo();
            Toast.makeText(this, "تم تحديث معلومات الشاشة", Toast.LENGTH_SHORT).show();
        });
        return card;
    }

    private View buildGuidesCard() {
        LinearLayout card = card(16, false);
        card.addView(sectionTitle("✅  إعدادات مقترحة لـ S26 Ultra"));
        addGuideLine(card, "1", "افتح إعدادات الشاشة ثم Motion smoothness / سلاسة الحركة واختر Adaptive إن كان متاحاً.");
        addGuideLine(card, "2", "افتح معلومات Roblox > البطارية، واختر Unrestricted إذا كان النظام يقيّد اللعبة. قد يزيد استهلاك البطارية.");
        addGuideLine(card, "3", "من داخل اللعبة خفّض Graphics Quality عندما تلاحظ تقطيعاً، وأغلق التطبيقات الثقيلة بالخلفية.");
        addGuideLine(card, "4", "جرّب Wi‑Fi مستقرّاً. تقطيع الشبكة يختلف عن هبوط FPS ولا يُحلّ بتغيير تردد الشاشة.");
        return card;
    }

    private void addGuideLine(LinearLayout card, String num, String content) {
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(Gravity.TOP);
        row.setLayoutDirection(View.LAYOUT_DIRECTION_RTL);
        TextView number = text(num, 13, BG, true);
        number.setGravity(Gravity.CENTER);
        number.setBackground(roundRect(CYAN, CYAN, 99, 1));
        row.addView(number, new LinearLayout.LayoutParams(dp(26), dp(26)));
        TextView body = text(content, 13, TEXT, false);
        body.setLineSpacing(dp(2), 1f);
        LinearLayout.LayoutParams bp = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1);
        bp.setMargins(dp(9), 0, 0, 0);
        row.addView(body, bp);
        card.addView(row, lpTop(12));
    }

    private View buildVisualLimitsCard() {
        LinearLayout card = card(16, false);
        card.addView(sectionTitle("🎨  موشن بلور و ReShade"));
        TextView body = text("تأثيرات مثل ReShade أو Motion Blur الحقيقي تحتاج دعماً من اللعبة نفسها أو صلاحيات/تعديلات عميقة. تطبيق عادي لا يستطيع حقن مؤثرات داخل Roblox أو تعديل مجلده الخاص على أندرويد. لذلك لا توجد أزرار وهمية تدّعي تطبيقها.", 13, MUTED, false);
        body.setLineSpacing(dp(3), 1f);
        card.addView(body, lpTop(6));
        TextView safety = text("🛡️ لا يحتاج Root أو Shizuku • لا يغيّر ملفات اللعبة • لا يجمع بياناتك", 12, GREEN, true);
        safety.setPadding(dp(11), dp(10), dp(11), dp(10));
        safety.setBackground(roundRect(Color.rgb(9, 38, 34), Color.rgb(31, 107, 84), 13, 1));
        card.addView(safety, lpTop(12));
        return card;
    }

    private void refreshDeviceInfo() {
        try {
            Display display = getWindowManager().getDefaultDisplay();
            float current = display.getRefreshRate();
            float max = current;
            Display.Mode[] modes = display.getSupportedModes();
            if (modes != null) {
                for (Display.Mode mode : modes) {
                    if (mode.getRefreshRate() > max) max = mode.getRefreshRate();
                }
            }
            if (currentRateText != null) currentRateText.setText(String.format(Locale.US, "%.0f Hz", current));
            if (maxRateText != null) maxRateText.setText(String.format(Locale.US, "%.0f Hz", max));
        } catch (Exception e) {
            if (currentRateText != null) currentRateText.setText("غير متاح");
            if (maxRateText != null) maxRateText.setText("غير متاح");
        }
    }

    private void updateTargetNote() {
        if (targetNote == null) return;
        float max = getMaxRefreshRate();
        String suffix;
        if (targetFps > max + 0.5f) {
            suffix = "الهدف " + targetFps + " رقم محفوظ داخل MK442 فقط؛ شاشة جهازك تعرض حتى "
                    + String.format(Locale.US, "%.0f", max) + " Hz تقريباً، ولا يمكن لهذا التطبيق رفع حد Roblox.";
        } else if (targetFps > 120) {
            suffix = "الهدف محفوظ كتفضيل فقط. دعم Roblox على أندرويد قد يقيّد FPS دون تردد الشاشة؛ لا يتم فرض هذا الرقم.";
        } else {
            suffix = "الهدف " + targetFps + " محفوظ كتفضيل داخل التطبيق فقط. هذا لا يثبت أن Roblox تعمل فعلياً بهذا العدد.";
        }
        targetNote.setText(suffix);
    }

    private float getMaxRefreshRate() {
        try {
            Display display = getWindowManager().getDefaultDisplay();
            float max = display.getRefreshRate();
            Display.Mode[] modes = display.getSupportedModes();
            if (modes != null) for (Display.Mode mode : modes) max = Math.max(max, mode.getRefreshRate());
            return max;
        } catch (Exception e) {
            return 60f;
        }
    }

    private void updateProfileDescription() {
        if (profileDescription == null) return;
        switch (selectedProfile) {
            case "balanced":
                profileDescription.setText("متوازن: ابدأ بجودة رسومات متوسطة، وراقب الحرارة وثبات الحركة. مناسب إذا تبي صورة جيدة مع أداء مستقر.");
                break;
            case "visual":
                profileDescription.setText("جودة: ارفع جودة الرسومات من إعدادات التجربة نفسها. الجودة الأعلى قد تقلل الأداء وترفع حرارة الجهاز.");
                break;
            default:
                profileDescription.setText("تنافسي: قلّل Graphics Quality داخل Roblox، فعّل أعلى سلاسة شاشة متاحة، وأوقف توفير الطاقة أثناء اللعب إذا كان يقيّد الأداء.");
                break;
        }
    }

    private void launchRoblox() {
        try {
            Intent launch = getPackageManager().getLaunchIntentForPackage(ROBLOX_PACKAGE);
            if (launch != null) {
                launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(launch);
            } else {
                Intent store = new Intent(Intent.ACTION_VIEW,
                        Uri.parse("https://play.google.com/store/apps/details?id=" + ROBLOX_PACKAGE));
                startActivity(store);
            }
        } catch (ActivityNotFoundException e) {
            Toast.makeText(this, "تعذّر فتح Roblox أو متجر التطبيقات", Toast.LENGTH_LONG).show();
        }
    }

    private void openDisplaySettings() {
        try {
            startActivity(new Intent(Settings.ACTION_DISPLAY_SETTINGS));
        } catch (Exception e) {
            startActivity(new Intent(Settings.ACTION_SETTINGS));
        }
    }

    private void openRobloxAppInfo() {
        try {
            Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.parse("package:" + ROBLOX_PACKAGE));
            startActivity(intent);
        } catch (Exception e) {
            Toast.makeText(this, "لم أتمكن من فتح معلومات Roblox. تأكد أنها مثبتة.", Toast.LENGTH_LONG).show();
        }
    }

    private LinearLayout card(int padding, boolean glowing) {
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(dp(padding), dp(padding), dp(padding), dp(padding));
        layout.setBackground(gradient(
                new int[]{glowing ? Color.rgb(15, 36, 58) : CARD2, CARD},
                20, glowing ? CYAN : Color.rgb(35, 55, 78), 1));
        return layout;
    }

    private TextView sectionTitle(String value) {
        TextView title = text(value, 17, TEXT, true);
        title.setGravity(Gravity.CENTER_VERTICAL | Gravity.RIGHT);
        return title;
    }

    private TextView actionButton(String value, boolean primary) {
        TextView button = text(value, 13, primary ? BG : TEXT, true);
        button.setGravity(Gravity.CENTER);
        button.setPadding(dp(8), dp(9), dp(8), dp(9));
        button.setBackground(primary
                ? gradient(new int[]{CYAN, GREEN}, 14, CYAN, 1)
                : roundRect(Color.rgb(17, 32, 51), Color.rgb(55, 83, 107), 14, 1));
        button.setClickable(true);
        button.setFocusable(true);
        return button;
    }

    private TextView text(String value, int sizeSp, int color, boolean bold) {
        TextView t = new TextView(this);
        t.setText(value);
        t.setTextSize(sizeSp);
        t.setTextColor(color);
        t.setGravity(Gravity.CENTER_VERTICAL | Gravity.RIGHT);
        t.setTextDirection(View.TEXT_DIRECTION_FIRST_STRONG);
        t.setTypeface(Typeface.create("sans-serif", bold ? Typeface.BOLD : Typeface.NORMAL));
        return t;
    }

    private GradientDrawable roundRect(int fill, int stroke, int radius, int strokeWidth) {
        GradientDrawable d = new GradientDrawable();
        d.setColor(fill);
        d.setCornerRadius(dp(radius));
        d.setStroke(dp(strokeWidth), stroke);
        return d;
    }

    private GradientDrawable gradient(int[] colors, int radius, int stroke, int strokeWidth) {
        GradientDrawable d = new GradientDrawable(GradientDrawable.Orientation.TL_BR, colors);
        d.setCornerRadius(dp(radius));
        d.setStroke(dp(strokeWidth), stroke);
        return d;
    }

    private LinearLayout.LayoutParams lpTop(int topDp) {
        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        p.topMargin = dp(topDp);
        return p;
    }

    private View spaceW(int widthDp) {
        View v = new View(this);
        v.setLayoutParams(new LinearLayout.LayoutParams(dp(widthDp), 1));
        return v;
    }

    private int dp(float value) {
        return (int) (value * getResources().getDisplayMetrics().density + 0.5f);
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (currentRateText != null) {
            refreshDeviceInfo();
            updateTargetNote();
        }
    }
}
