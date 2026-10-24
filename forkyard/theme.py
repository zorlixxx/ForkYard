"""Design tokens for the ForkYard interface.

The palette, spacing, radii, type scale and motion timings live in one
place and are handed to QML as a read-only context property, so the
Python side and the declarative side can never drift apart.
"""
from __future__ import annotations

COLORS = {
    # Surfaces, from deepest to highest.
    "bg": "#0A0811",
    "bgSoft": "#0E0B17",
    "surface": "#12101C",
    "surfaceAlt": "#171423",
    "surfaceHi": "#1D1A2B",
    "surfacePress": "#242032",
    "border": "#262133",
    "borderHi": "#342E45",
    # Type.
    "text": "#EEF2F7",
    "textDim": "#9AA5B4",
    "textFaint": "#68727F",
    "textOnAccent": "#120A1E",
    # Accent - a single violet against the black shell.
    "accent": "#A855F7",
    "accentHi": "#C084FC",
    "accentLo": "#7C3AED",
    # Semantic colours.
    "safe": "#46C08A",
    "moderate": "#E5A63F",
    "advanced": "#E4675E",
    "info": "#5E9CE6",
    # Chrome.
    "scrim": "#05030C",
}

SPACE = {
    "xs": 4,
    "sm": 6,
    "md": 8,
    "lg": 12,
    "xl": 16,
    "xxl": 20,
}

RADIUS = {
    "sm": 6,
    "control": 8,
    "card": 12,
    "panel": 16,
    "dialog": 18,
    "pill": 999,
}

FONTS = {
    "family": {
        "display": "Reversal",
        "ui": "Segoe UI",
        "mono": "Consolas",
    },
    "size": {
        "wordmark": 19,
        "display": 23,
        "title": 15,
        "dialogTitle": 18,
        "body": 13,
        "bodySmall": 12,
        "label": 11,
        "micro": 10,
        "mono": 11,
    },
    "tracking": {
        "wordmark": 2.4,
        "micro": 0.9,
    },
}

MOTION = {
    "instant": 90,
    "fast": 140,
    "base": 200,
}

TOKENS = {
    "color": COLORS,
    "space": SPACE,
    "radius": RADIUS,
    "font": FONTS,
    "motion": MOTION,
    "layout": {
        "headerHeight": 60,
        "sidebarWidth": 274,
        "activityCollapsed": 38,
        "activityExpanded": 196,
        "cardHeight": 152,
        "cardGap": 12,
        "contentPadding": 26,
    },
}

RISK_COLORS = {
    "Safe": COLORS["safe"],
    "Moderate": COLORS["moderate"],
    "Advanced": COLORS["advanced"],
}


def risk_color(risk: str) -> str:
    """Colour that represents a risk level."""
    return RISK_COLORS.get(risk, COLORS["textFaint"])
