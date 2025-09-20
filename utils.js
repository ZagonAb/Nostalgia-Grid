function formatPlayTime(seconds) {
    if (seconds <= 0) return "0 min";

    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);

    if (hours > 0) {
        return hours + " h " + (minutes > 0 ? minutes + " m" : "");
    } else {
        return minutes + " min";
    }
}

const shortTexts = [
    "A world that feels different!",
"Something is about to begin…",
"Not everything is what it seems.",
"Where reality ends…",
"Dare to feel it.",
"Change is near.",
"Anything can happen here.",
"Will you step in?",
"Just one decision left.",
"You're one step away.",
"Nothing will be the same.",
"One moment is enough.",
"The impossible, possible.",
"Something is waiting for you.",
"The extraordinary begins."
];

const longTexts = [
    "Discover the surprises that a special world has in store for you!",
"Dare to open the door no one else dares to cross.",
"Only the brave know what lies beyond the first step.",
"When routine ends, the real adventure begins.",
"The unexpected is waiting—just press start.",
"A unique story comes to life the moment you move forward.",
"This is where instinct makes all the difference.",
"Not everyone makes it… but you can try.",
"Excitement is just a button away. Ready?",
"The next move is entirely up to you.",
"Nothing compares to what you're about to experience.",
"Something epic is about to begin—if you choose to.",
"Close your eyes… and let it take you farther than expected.",
"A single moment of courage is enough to begin something unforgettable.",
"What seemed like a simple step… could change everything."
];

function getRandomShortText() {
    return shortTexts[Math.floor(Math.random() * shortTexts.length)];
}

function getRandomLongText() {
    return longTexts[Math.floor(Math.random() * longTexts.length)];
}


function getSystemColor(systemShortName, colorMapping) {
    if (!systemShortName || !colorMapping) {
        return "#f62507";
    }
    return colorMapping.getColor(systemShortName);
}


function isValidShortName(shortName) {
    return shortName && typeof shortName === 'string' && shortName.trim().length > 0;
}

function interpolateColors(color1, color2, factor) {
    if (factor <= 0) return color1;
    if (factor >= 1) return color2;

    function hexToRgb(hex) {
        const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
        return result ? {
            r: parseInt(result[1], 16),
            g: parseInt(result[2], 16),
            b: parseInt(result[3], 16)
        } : null;
    }

    function rgbToHex(r, g, b) {
        return "#" + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1);
    }

    const c1 = hexToRgb(color1);
    const c2 = hexToRgb(color2);

    if (!c1 || !c2) return color1;

    const r = Math.round(c1.r + factor * (c2.r - c1.r));
    const g = Math.round(c1.g + factor * (c2.g - c1.g));
    const b = Math.round(c1.b + factor * (c2.b - c1.b));

    return rgbToHex(r, g, b);
}

function adjustColorBrightness(color, amount) {
    const num = parseInt(color.replace("#", ""), 16);
    const amt = Math.round(2.55 * amount);
    const R = (num >> 16) + amt;
    const G = (num >> 8 & 0x00FF) + amt;
    const B = (num & 0x0000FF) + amt;

    return "#" + (0x1000000 + (R < 255 ? R < 1 ? 0 : R : 255) * 0x10000
    + (G < 255 ? G < 1 ? 0 : G : 255) * 0x100
    + (B < 255 ? B < 1 ? 0 : B : 255))
    .toString(16).slice(1);
}
