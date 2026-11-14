package com.gathin.tvhome;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Rect;
import android.graphics.drawable.Drawable;

/**
 * An app's main colour, read from its artwork for hero_title_art: the artwork drawn at 32×18 pixels and its vivid
 * pixels grouped by hue into twelve slices. The fullest slice wins as long as it covers a few percent of the picture,
 * so Spotify's green beats the flat grey it sits on, whose one shade would otherwise outnumber the green's many.
 * A logo with no vivid colour falls back to its most common grey or white.
 */
final class AppColours {
    private static final int W = 32, H = 18;
    private static final int HUES = 12;
    /** Saturation and brightness from which a pixel counts as a colour rather than a grey. */
    private static final float VIVID_S = 0.35f, VIVID_V = 0.25f;
    /** Share of the picture a hue needs before it is taken as the app's colour. */
    private static final float MIN_SHARE = 0.03f;
    /** Below this brightness a colour is lifted toward white, so the name stays legible over a dark wallpaper. */
    private static final float MIN_LUMA = 0.40f;

    private AppColours() {
    }

    /** The main colour, or Color.WHITE when there is no artwork. */
    static int main(Drawable live) {
        if (live == null) return Color.WHITE;
        // Draw a private copy: changing the bounds of the drawable a tile shows would blank the tile.
        Drawable d = live.getConstantState() != null ? live.getConstantState().newDrawable().mutate() : live;
        Rect saved = new Rect(d.getBounds());
        Bitmap small = Bitmap.createBitmap(W, H, Bitmap.Config.ARGB_8888);
        Canvas c = new Canvas(small);
        c.drawColor(Color.BLACK);
        d.setBounds(0, 0, W, H);
        d.draw(c);
        d.setBounds(saved);
        int[] px = new int[W * H];
        small.getPixels(px, 0, W, 0, 0, W, H);
        small.recycle();

        // Per slice: {count, r sum, g sum, b sum}. Slices 0..HUES-1 are hues, the rest are eight grey levels.
        float[][] slices = new float[HUES + 8][4];
        float[] hsv = new float[3];
        for (int p : px) {
            Color.colorToHSV(p, hsv);
            if (hsv[2] < 0.08f) continue;   // the dark ground most banners have is not the app's colour
            boolean vivid = hsv[1] >= VIVID_S && hsv[2] >= VIVID_V;
            int slice = vivid ? (int) (hsv[0] / 360f * HUES) % HUES : HUES + Math.min(7, (int) (hsv[2] * 8));
            float[] s = slices[slice];
            s[0]++;
            s[1] += Color.red(p);
            s[2] += Color.green(p);
            s[3] += Color.blue(p);
        }
        int best = -1;
        for (int i = 0; i < HUES; i++) {
            if (slices[i][0] >= MIN_SHARE * px.length && (best < 0 || slices[i][0] > slices[best][0])) best = i;
        }
        if (best < 0) {
            for (int i = HUES; i < slices.length; i++) {
                if (slices[i][0] > 0 && (best < 0 || slices[i][0] > slices[best][0])) best = i;
            }
        }
        if (best < 0) return Color.WHITE;
        float[] s = slices[best];
        return readable(Color.rgb(Math.round(s[1] / s[0]), Math.round(s[2] / s[0]), Math.round(s[3] / s[0])));
    }

    /** Lifts a dark colour toward white until its brightness reaches MIN_LUMA. */
    private static int readable(int colour) {
        int r = Color.red(colour), g = Color.green(colour), b = Color.blue(colour);
        float l = (0.2126f * r + 0.7152f * g + 0.0722f * b) / 255f;
        if (l >= MIN_LUMA) return colour;
        float t = (MIN_LUMA - l) / (1f - l);
        return Color.rgb(Math.round(r + (255 - r) * t), Math.round(g + (255 - g) * t), Math.round(b + (255 - b) * t));
    }
}
