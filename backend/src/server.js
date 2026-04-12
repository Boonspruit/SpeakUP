import cors from "cors";
import dotenv from "dotenv";
import express from "express";
import { GoogleGenAI } from "@google/genai";

dotenv.config();

const PORT = Number(process.env.PORT || 8787);
const GEMINI_MODEL = process.env.GEMINI_MODEL || "gemini-2.0-flash-lite";
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

const app = express();
app.use(cors());
app.use(express.json({ limit: "1mb" }));

const ai = GEMINI_API_KEY ? new GoogleGenAI({ apiKey: GEMINI_API_KEY }) : null;

const focusTrackToCategory = {
  work: "presentation",
  interviews: "interview",
  social: "speech",
  school: "presentation",
  storytelling: "storytelling"
};

const drillSchema = {
  type: "OBJECT",
  properties: {
    title: { type: "STRING" },
    focusTrack: {
      type: "STRING",
      enum: ["work", "interviews", "social", "school", "storytelling"]
    },
    scenario: { type: "STRING" },
    difficulty: { type: "STRING" },
    targetDurationSec: { type: "NUMBER" },
    tone: { type: "STRING" },
    coachingGoal: { type: "STRING" },
    focusHint: { type: "STRING" },
    sections: {
      type: "OBJECT",
      properties: {
        opening: { type: "STRING" },
        point_1: { type: "STRING" },
        point_2: { type: "STRING" },
        point_3: { type: "STRING" },
        closing: { type: "STRING" }
      },
      required: ["opening", "point_1", "point_2", "point_3", "closing"],
      propertyOrdering: ["opening", "point_1", "point_2", "point_3", "closing"]
    }
  },
  required: [
    "title",
    "focusTrack",
    "scenario",
    "difficulty",
    "targetDurationSec",
    "tone",
    "coachingGoal",
    "focusHint",
    "sections"
  ],
  propertyOrdering: [
    "title",
    "focusTrack",
    "scenario",
    "difficulty",
    "targetDurationSec",
    "tone",
    "coachingGoal",
    "focusHint",
    "sections"
  ]
};

const feedbackSchema = {
  type: "OBJECT",
  properties: {
    strength: { type: "STRING" },
    suggestions: {
      type: "ARRAY",
      items: { type: "STRING" }
    },
    claritySummary: { type: "STRING" }
  },
  required: ["strength", "suggestions", "claritySummary"],
  propertyOrdering: ["strength", "suggestions", "claritySummary"]
};

app.get("/health", (_req, res) => {
  res.json({
    ok: true,
    model: GEMINI_MODEL,
    geminiConfigured: Boolean(GEMINI_API_KEY)
  });
});

app.post("/generate-drill", async (req, res) => {
  if (!ai) {
    return res.status(500).json({ error: "Gemini API key is not configured on the backend." });
  }

  const body = req.body ?? {};
  const focusTrack = normalizeFocusTrack(body.focusTrack);
  const difficulty = normalizeDifficulty(body.difficulty);
  const targetDurationSec = normalizeDuration(body.targetDurationSec);
  const tone = stringOr(body.tone, "supportive");
  const seedScenario = stringOr(body.seedScenario, "");
  const similarToDrillTitle = stringOr(body.similarToDrillTitle, "");

  try {
    const prompt = [
      "Create one SpeakUp speaking drill.",
      "The app is a supportive public speaking practice app for iPhone.",
      "Return JSON only.",
      `Focus track: ${focusTrack}.`,
      `Difficulty: ${difficulty}.`,
      `Target duration: ${targetDurationSec} seconds.`,
      `Tone: ${tone}.`,
      seedScenario ? `Seed scenario: ${seedScenario}.` : "",
      similarToDrillTitle ? `Make it feel related to this drill title, but not a copy: ${similarToDrillTitle}.` : "",
      "Keep it practical, realistic, and easy to practice aloud.",
      "The sections should feel like a natural speaking script, not bullet fragments.",
      "Make the coaching goal and focus hint short and concrete."
    ].filter(Boolean).join("\n");

    const generated = await generateStructuredJson({
      prompt,
      systemInstruction: [
        "You write short public speaking drills for SpeakUp.",
        "You must stay supportive, practical, and concise.",
        "Never include unsafe, hateful, sexual, medical, legal, or political persuasion content.",
        "Never mention AI or that the drill was generated.",
        "Return only valid JSON."
      ].join(" "),
      schema: drillSchema
    });

    const response = normalizeDrillResponse(generated, {
      focusTrack,
      difficulty,
      targetDurationSec,
      tone
    });

    return res.json(response);
  } catch (error) {
    return res.status(500).json({
      error: "Failed to generate drill.",
      detail: error instanceof Error ? error.message : "Unknown error"
    });
  }
});

app.post("/speech-feedback", async (req, res) => {
  if (!ai) {
    return res.status(500).json({ error: "Gemini API key is not configured on the backend." });
  }

  const body = req.body ?? {};
  const transcript = stringOr(body.transcript, "").trim();

  if (!transcript) {
    return res.status(400).json({ error: "Transcript is required." });
  }

  try {
    const prompt = [
      "Create supportive post-session coaching feedback for SpeakUp.",
      "The user just finished a speaking drill.",
      `Transcript: ${transcript}`,
      `Duration seconds: ${numberOr(body.durationSeconds, 0)}`,
      `Words per minute: ${numberOr(body.wordsPerMinute, 0)}`,
      `Filler word count: ${numberOr(body.fillerWordCount, 0)}`,
      `Pause count: ${numberOr(body.pauseCount, 0)}`,
      `Average pause duration: ${numberOr(body.averagePauseDuration, 0)}`,
      body.focusTrack ? `Focus track: ${body.focusTrack}` : "",
      body.practiceMode ? `Practice mode: ${body.practiceMode}` : "",
      body.drillTitle ? `Drill title: ${body.drillTitle}` : "",
      body.drillScenario ? `Drill scenario: ${body.drillScenario}` : "",
      "Give one strength, one or two small suggestions, and a short clarity summary.",
      "Be encouraging, warm, clear, and non-judgmental.",
      "Do not grade harshly. Do not mention tokens, models, AI, or technical analysis."
    ].filter(Boolean).join("\n");

    const feedback = await generateStructuredJson({
      prompt,
      systemInstruction: [
        "You are SpeakUp's supportive speaking coach.",
        "You write gentle, practical coaching after a speaking drill.",
        "Keep language simple and encouraging.",
        "Return only valid JSON."
      ].join(" "),
      schema: feedbackSchema
    });

    const suggestions = Array.isArray(feedback.suggestions)
      ? feedback.suggestions.map((item) => String(item).trim()).filter(Boolean).slice(0, 2)
      : [];

    return res.json({
      strength: stringOr(feedback.strength, "You completed the drill and built real speaking momentum."),
      suggestions,
      claritySummary: stringOr(feedback.claritySummary, "Steady")
    });
  } catch (error) {
    return res.status(500).json({
      error: "Failed to generate speech feedback.",
      detail: error instanceof Error ? error.message : "Unknown error"
    });
  }
});

app.listen(PORT, () => {
  console.log(`SpeakUp backend listening on http://127.0.0.1:${PORT}`);
});

async function generateStructuredJson({ prompt, systemInstruction, schema }) {
  const response = await ai.models.generateContent({
    model: GEMINI_MODEL,
    contents: prompt,
    config: {
      systemInstruction,
      temperature: 0.7,
      responseMimeType: "application/json",
      responseJsonSchema: schema
    }
  });

  const text = extractText(response);
  if (!text) {
    throw new Error("Gemini returned an empty response.");
  }

  return JSON.parse(text);
}

function extractText(response) {
  if (!response) return "";
  if (typeof response.text === "function") return response.text();
  if (typeof response.text === "string") return response.text;

  const parts = response.candidates?.[0]?.content?.parts;
  if (Array.isArray(parts)) {
    return parts.map((part) => part.text || "").join("").trim();
  }

  return "";
}

function normalizeDrillResponse(raw, defaults) {
  const focusTrack = normalizeFocusTrack(raw.focusTrack || defaults.focusTrack);
  return {
    title: stringOr(raw.title, "Fresh Drill"),
    category: focusTrackToCategory[focusTrack] || "presentation",
    focusTrack,
    scenario: stringOr(raw.scenario, "A practical speaking scenario"),
    difficulty: normalizeDifficulty(raw.difficulty || defaults.difficulty),
    targetDurationSec: normalizeDuration(raw.targetDurationSec || defaults.targetDurationSec),
    tone: stringOr(raw.tone, defaults.tone),
    coachingGoal: stringOr(raw.coachingGoal, "Practice sounding clear and confident."),
    focusHint: stringOr(raw.focusHint, "Keep your pace steady and your delivery natural."),
    sections: {
      opening: stringOr(raw.sections?.opening, "Open with a clear first line."),
      point_1: stringOr(raw.sections?.point_1, "Make your first supporting point."),
      point_2: stringOr(raw.sections?.point_2, "Add a second supporting point."),
      point_3: stringOr(raw.sections?.point_3, "Finish your final supporting point."),
      closing: stringOr(raw.sections?.closing, "Close with a confident ending.")
    }
  };
}

function normalizeFocusTrack(value) {
  const normalized = String(value || "").trim().toLowerCase();
  if (["work", "interviews", "social", "school", "storytelling"].includes(normalized)) {
    return normalized;
  }
  return "work";
}

function normalizeDifficulty(value) {
  const normalized = String(value || "").trim().toLowerCase();
  if (["easy", "medium", "hard"].includes(normalized)) {
    return normalized;
  }
  return "medium";
}

function normalizeDuration(value) {
  const duration = Number(value);
  if ([30, 60, 90].includes(duration)) {
    return duration;
  }
  return 60;
}

function stringOr(value, fallback) {
  const normalized = String(value || "").trim();
  return normalized || fallback;
}

function numberOr(value, fallback) {
  const numeric = Number(value);
  return Number.isFinite(numeric) ? numeric : fallback;
}
