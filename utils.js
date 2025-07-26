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
