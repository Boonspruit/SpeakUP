export const talkingPointsSchema = {
  type: "ARRAY",
  items: { type: "STRING" },
  minItems: 3,
  maxItems: 3
};

export function validTalkingPoints(values) {
  if (!Array.isArray(values) || values.length !== 3 || values.some(value => typeof value !== "string")) return null;
  const points = values.map(value => value.trim());
  if (new Set(points.map(value => value.toLowerCase())).size !== 3) return null;
  return points.every(value => value.length > 0 && value.length <= 240 && value.split(/\s+/).length <= 35) ? points : null;
}

export function fallbackTalkingPoints(title) {
  const topic = String(title || "this topic").trim().split(/\s+/).slice(0, 12).join(" ").slice(0, 80);
  return [
    `What is the main idea you want to share about ${topic}?`,
    "What specific example or experience would help your audience understand?",
    "What would you like your listeners to remember or do next?"
  ];
}
