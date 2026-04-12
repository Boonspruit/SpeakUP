import cors from "cors";
import dotenv from "dotenv";
import express from "express";
import { GoogleGenAI } from "@google/genai";

dotenv.config();

const PORT = Number(process.env.PORT || 8787);
const GEMINI_MODEL = process.env.GEMINI_MODEL || "gemini-2.5-flash-lite";
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

app.get("/", (_req, res) => {
  res.json({
    service: "SpeakUp backend",
    ok: true,
    health: "/health",
    generateDrill: "/generate-drill",
    speechFeedback: "/speech-feedback",
    model: GEMINI_MODEL,
    geminiConfigured: Boolean(GEMINI_API_KEY)
  });
});

app.get("/health", (_req, res) => {
  res.json({
    ok: true,
    model: GEMINI_MODEL,
    geminiConfigured: Boolean(GEMINI_API_KEY)
  });
});

app.post("/generate-drill", async (req, res) => {
  if (!ai) {
    return sendAIErrorResponse(res, {
      status: 500,
      code: "gemini_not_configured",
      error: "Gemini API key is not configured on the backend.",
      userMessage: "AI drill generation isn't configured on the backend yet.",
      retryable: false
    });
  }

  const body = req.body ?? {};
  const focusTrack = normalizeFocusTrack(body.focusTrack);
  const difficulty = normalizeDifficulty(body.difficulty);
  const targetDurationSec = normalizeDuration(body.targetDurationSec);
  const tone = stringOr(body.tone, "supportive");
  const seedScenario = stringOr(body.seedScenario, "");
  const similarToDrillTitle = stringOr(body.similarToDrillTitle, "");

  try {
    const prompt = buildDrillPrompt({
      focusTrack,
      difficulty,
      targetDurationSec,
      tone,
      seedScenario,
      similarToDrillTitle,
      retryOnOutline: false
    });

    let generated = await generateStructuredJson({
      prompt,
      systemInstruction: buildDrillSystemInstruction(),
      schema: drillSchema
    });

    if (looksLikeOutlineDrill(generated, targetDurationSec)) {
      generated = await generateStructuredJson({
        prompt: buildDrillPrompt({
          focusTrack,
          difficulty,
          targetDurationSec,
          tone,
          seedScenario,
          similarToDrillTitle,
          retryOnOutline: true
        }),
        systemInstruction: buildDrillSystemInstruction(),
        schema: drillSchema
      });
    }

    const response = normalizeDrillResponse(generated, {
      focusTrack,
      difficulty,
      targetDurationSec,
      tone
    });

    if (looksLikeOutlineDrill(response, targetDurationSec)) {
      throw new Error("Generated drill was still an outline instead of spoken rehearsal copy.");
    }

    return res.json(response);
  } catch (error) {
    return sendAIErrorResponse(res, normalizeAIError(error, "generate_drill"));
  }
});

app.post("/speech-feedback", async (req, res) => {
  if (!ai) {
    return sendAIErrorResponse(res, {
      status: 500,
      code: "gemini_not_configured",
      error: "Gemini API key is not configured on the backend.",
      userMessage: "AI feedback isn't configured on the backend yet.",
      retryable: false
    });
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
    return sendAIErrorResponse(res, normalizeAIError(error, "speech_feedback"));
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
      opening: stringOr(raw.sections?.opening, "Thanks for being here today. I want to share one short example that shows how I handle this kind of moment."),
      point_1: stringOr(raw.sections?.point_1, "The situation was challenging at first, so I focused on staying clear, calm, and specific about what needed to happen next."),
      point_2: stringOr(raw.sections?.point_2, "I broke the problem into a few simple steps, communicated the priorities, and kept people aligned as we moved forward."),
      point_3: stringOr(raw.sections?.point_3, "That approach helped the conversation feel more confident and practical, and it made the result easier for everyone to follow."),
      closing: stringOr(raw.sections?.closing, "That experience reminded me that clear communication builds trust, especially when the stakes feel high.")
    }
  };
}

function buildDrillSystemInstruction() {
  return [
    "You write short public speaking drills for SpeakUp.",
    "You must stay supportive, practical, concise, and realistic.",
    "Every section must contain exact words the user can say out loud.",
    "Write in natural spoken language, usually first person, as if this were cue-card copy for rehearsal.",
    "Do not write instructions, labels, placeholders, or coaching commands.",
    "Never write phrases such as 'open with', 'say', 'mention', 'talk about', 'make your point', 'add a point', 'close with', or 'finish by'.",
    "Never include unsafe, hateful, sexual, medical, legal, or political persuasion content.",
    "Never mention AI or that the drill was generated.",
    "Return only valid JSON."
  ].join(" ");
}

function buildDrillPrompt({
  focusTrack,
  difficulty,
  targetDurationSec,
  tone,
  seedScenario,
  similarToDrillTitle,
  retryOnOutline
}) {
  const wordRange = targetWordRange(targetDurationSec);
  return [
    "Create one SpeakUp speaking drill.",
    "The app is a supportive public speaking practice app for iPhone.",
    "Return JSON only.",
    `Focus track: ${focusTrack}.`,
    `Difficulty: ${difficulty}.`,
    `Target duration: ${targetDurationSec} seconds.`,
    `Tone: ${tone}.`,
    seedScenario ? `Seed scenario: ${seedScenario}.` : "",
    similarToDrillTitle ? `Make it feel related to this drill title, but not a copy: ${similarToDrillTitle}.` : "",
    `Write approximately ${wordRange.min}-${wordRange.max} total words across the five sections.`,
    "The script must be actual rehearsal copy the user can read aloud immediately.",
    "Each section should contain 1-3 complete spoken sentences, not bullets or instructions.",
    "Write concrete lines with real content, not abstract placeholders.",
    "Good example for a section: 'Thanks for being here today. I want to share a quick update on what changed this week.'",
    "Bad example for a section: 'Open with a strong first line.'",
    "Bad example for a section: 'Mention your first supporting point.'",
    "Make the coaching goal and focus hint short and concrete.",
    retryOnOutline
      ? "Important: your previous answer sounded like an outline. Rewrite every section as literal spoken words someone can rehearse verbatim."
      : ""
  ].filter(Boolean).join("\n");
}

function targetWordRange(durationSec) {
  switch (normalizeDuration(durationSec)) {
    case 30:
      return { min: 45, max: 75 };
    case 90:
      return { min: 120, max: 170 };
    case 60:
    default:
      return { min: 80, max: 125 };
  }
}

function looksLikeOutlineDrill(drill, targetDurationSec) {
  const sections = [
    drill?.sections?.opening,
    drill?.sections?.point_1,
    drill?.sections?.point_2,
    drill?.sections?.point_3,
    drill?.sections?.closing
  ]
    .map((value) => String(value || "").trim())
    .filter(Boolean);

  if (sections.length < 5) return true;

  const combined = sections.join(" ").toLowerCase();
  const instructionPatterns = [
    "open with",
    "start with",
    "close with",
    "end with",
    "finish with",
    "finish your",
    "make your first",
    "make your point",
    "add a second",
    "supporting point",
    "mention ",
    "talk about ",
    "say why",
    "explain how"
  ];

  if (instructionPatterns.some((pattern) => combined.includes(pattern))) {
    return true;
  }

  const totalWords = combined.split(/\s+/).filter(Boolean).length;
  const wordRange = targetWordRange(targetDurationSec);
  if (totalWords < wordRange.min) {
    return true;
  }

  const averageWordsPerSection = totalWords / sections.length;
  return averageWordsPerSection < 10;
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

function sendAIErrorResponse(res, errorInfo) {
  return res.status(errorInfo.status).json({
    error: errorInfo.error,
    code: errorInfo.code,
    userMessage: errorInfo.userMessage,
    retryable: errorInfo.retryable,
    detail: errorInfo.detail
  });
}

function normalizeAIError(error, route) {
  const detail = error instanceof Error ? error.message : String(error ?? "Unknown error");
  const lower = detail.toLowerCase();

  if (
    lower.includes("429 too many requests") ||
    lower.includes("resource_exhausted") ||
    lower.includes("quota exceeded")
  ) {
    return {
      status: 429,
      code: "quota_exceeded",
      error: route === "generate_drill" ? "Failed to generate drill." : "Failed to generate speech feedback.",
      userMessage: "AI requests are temporarily unavailable because the Gemini account hit a billing or quota limit. Check Google AI billing and quotas, then try again.",
      retryable: true,
      detail
    };
  }

  if (
    lower.includes("404 not found") ||
    lower.includes("no longer available to new users") ||
    (lower.includes("model") && lower.includes("not found"))
  ) {
    return {
      status: 503,
      code: "model_unavailable",
      error: route === "generate_drill" ? "Failed to generate drill." : "Failed to generate speech feedback.",
      userMessage: `The configured Gemini model (${GEMINI_MODEL}) isn't available for this account. Update GEMINI_MODEL in Render to a supported model and redeploy.`,
      retryable: false,
      detail
    };
  }

  return {
    status: 502,
    code: "provider_error",
    error: route === "generate_drill" ? "Failed to generate drill." : "Failed to generate speech feedback.",
    userMessage: "The AI provider returned an unexpected error. Check your backend logs and Gemini configuration, then try again.",
    retryable: true,
    detail
  };
}
